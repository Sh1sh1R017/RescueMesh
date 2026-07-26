import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import 'sync_engine.dart';
import '../../domain/models/mesh_packet.dart';

class MeshService {
  final SyncEngine _syncEngine = SyncEngine();
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();

  // Custom UUID for RescueMesh network (already uppercase — no .toUpperCase() needed)
  static const String rescueMeshServiceUuid =
      '0000FEAA-0000-1000-8000-00805F9B34FB';

  bool _isAdvertising = false;
  bool _isScanning = false;

  StreamSubscription? _scanSubscription;
  final List<BluetoothDevice> _connectedPeers = [];

  /// Track BLE characteristic subscriptions per peer to cancel on disconnect.
  final Map<BluetoothDevice, List<StreamSubscription>> _peerSubs = {};

  // Exposes real-time peer count
  final ValueNotifier<int> connectedPeerCount = ValueNotifier<int>(0);

  void _updatePeerCount() {
    if (connectedPeerCount.value != _connectedPeers.length) {
      connectedPeerCount.value = _connectedPeers.length;
    }
  }

  Future<void> initializeAndStart() async {
    bool permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      if (kDebugMode) debugPrint('Bluetooth permissions not granted.');
      return;
    }

    // Start the mesh lifecycle
    await startAdvertising();
    await startScanning();
  }

  Future<bool> _requestPermissions() async {
    try {
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      return statuses[Permission.bluetoothAdvertise]?.isGranted == true &&
          statuses[Permission.bluetoothConnect]?.isGranted == true &&
          statuses[Permission.bluetoothScan]?.isGranted == true &&
          statuses[Permission.location]?.isGranted == true;
    } catch (e) {
      debugPrint('Error requesting BLE permissions: $e');
      return false;
    }
  }

  Future<void> startAdvertising() async {
    if (_isAdvertising) return;

    final AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: rescueMeshServiceUuid,
      includeDeviceName: false,
    );

    try {
      await _blePeripheral.start(advertiseData: advertiseData);
      _isAdvertising = true;
      if (kDebugMode) debugPrint('Mesh Advertising Started');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to start advertising: $e');
    }
  }

  /// In-flight connection locks to prevent GATT 133 errors & race conditions
  final Set<String> _connectingDeviceIds = <String>{};

  Future<void> startScanning() async {
    if (_isScanning) return;

    try {
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.advertisementData.serviceUuids
              .map((u) => u.toString().toUpperCase())
              .contains(rescueMeshServiceUuid)) {
            _connectToPeer(r.device);
          }
        }
      });

      await FlutterBluePlus.startScan(
        withServices: [Guid(rescueMeshServiceUuid)],
        continuousUpdates: false, // Prevents continuous 100% radio power draw
      );
      _isScanning = true;
      if (kDebugMode) debugPrint('Mesh Scanning Started');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to start scanning: $e');
    }
  }

  Future<void> _connectToPeer(BluetoothDevice device) async {
    final String deviceId = device.remoteId.str;

    // Guard: already connected OR connection in-flight
    if (_connectedPeers.contains(device) || _connectingDeviceIds.contains(deviceId)) {
      return;
    }

    _connectingDeviceIds.add(deviceId);

    try {
      await device.connect(
          autoConnect: false, timeout: const Duration(seconds: 5));
      _connectedPeers.add(device);
      _updatePeerCount();
      if (kDebugMode) debugPrint('Connected to peer: $deviceId');

      // Listen for unexpected disconnects — cancel characteristic subs too
      final connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handlePeerDisconnect(device);
        }
      });

      // Store connection subscription so it can be cancelled on stopAll()
      _peerSubs[device] = [connSub];

      // Initiate Sync
      await _syncWithPeer(device);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Connection failed to $deviceId: $e');
      }
      _connectedPeers.remove(device);
      _updatePeerCount();
    } finally {
      _connectingDeviceIds.remove(deviceId);
    }
  }


  /// Cleans up a disconnected peer's state and all its subscriptions.
  void _handlePeerDisconnect(BluetoothDevice device) {
    if (_connectedPeers.remove(device)) {
      _updatePeerCount();
      if (kDebugMode) debugPrint('Peer disconnected: ${device.remoteId}');
    }
    // Cancel all subscriptions for this peer to prevent leaks
    for (final sub in _peerSubs[device] ?? []) {
      sub.cancel();
    }
    _peerSubs.remove(device);
  }

  Future<void> _syncWithPeer(BluetoothDevice device) async {
    // 1. Discover Services
    final services = await device.discoverServices();
    BluetoothService? meshService;

    for (var service in services) {
      // UUID constant is already uppercase — only normalise the incoming value
      if (service.uuid.toString().toUpperCase() == rescueMeshServiceUuid) {
        meshService = service;
        break;
      }
    }

    if (meshService == null) return;

    // 2. We will assume there is a characteristic for reading/writing packets
    // In a full implementation, you define RX/TX characteristics.
    // For MVP, we simulate pulling messages from SyncEngine and attempting to send.

    final messagesToSend = await _syncEngine.handlePeerConnected();

    for (var char in meshService.characteristics) {
      if (char.properties.write) {
        for (var msg in messagesToSend) {
          try {
            await char.write(msg.toBleBytes());
          } catch (e) {
            if (kDebugMode) debugPrint('Failed to send message over BLE: $e');
          }
        }
      }

      // Subscribe to incoming messages — store subscription to cancel on disconnect
      if (char.properties.notify) {
        await char.setNotifyValue(true);
        final incomingSub = char.onValueReceived.listen((value) async {
          try {
            final incoming = MeshPacket.fromBleBytes(value);
            final isNew =
                await _syncEngine.processIncomingPacket(incoming);
            if (isNew && kDebugMode) {
              debugPrint('Received new message from mesh: ${incoming.msgId}');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error decoding incoming BLE message: $e');
            }
          }
        });
        // Track subscription for cleanup on disconnect
        _peerSubs[device]?.add(incomingSub);
      }
    }
  }

  Future<void> stopAll() async {
    await _blePeripheral.stop();
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _isAdvertising = false;
    _isScanning = false;

    // Snapshot the list before iterating to prevent ConcurrentModificationError
    // (the disconnect handler removes peers from the list)
    final peers = List<BluetoothDevice>.of(_connectedPeers);
    for (final peer in peers) {
      await peer.disconnect();
    }
    _connectedPeers.clear();

    // Cancel all peer subscriptions
    for (final subs in _peerSubs.values) {
      for (final sub in subs) {
        sub.cancel();
      }
    }
    _peerSubs.clear();
    _updatePeerCount();
  }
}
