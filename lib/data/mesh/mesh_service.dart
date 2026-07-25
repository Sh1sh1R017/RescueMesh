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
  
  // Custom UUID for RescueMesh network
  static const String RESCUE_MESH_SERVICE_UUID = '0000FEAA-0000-1000-8000-00805F9B34FB';
  
  bool _isAdvertising = false;
  bool _isScanning = false;
  
  StreamSubscription? _scanSubscription;
  final List<BluetoothDevice> _connectedPeers = [];
  
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
      debugPrint('Bluetooth permissions not granted.');
      return;
    }

    // Start the mesh lifecycle
    await startAdvertising();
    await startScanning();
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> startAdvertising() async {
    if (_isAdvertising) return;
    
    final AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: RESCUE_MESH_SERVICE_UUID,
      includeDeviceName: false,
    );

    try {
      await _blePeripheral.start(advertiseData: advertiseData);
      _isAdvertising = true;
      debugPrint('Mesh Advertising Started');
    } catch (e) {
      debugPrint('Failed to start advertising: $e');
    }
  }

  Future<void> startScanning() async {
    if (_isScanning) return;

    try {
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.advertisementData.serviceUuids.map((u) => u.toString().toUpperCase()).contains(RESCUE_MESH_SERVICE_UUID.toUpperCase())) {
            _connectToPeer(r.device);
          }
        }
      });

      await FlutterBluePlus.startScan(
        withServices: [Guid(RESCUE_MESH_SERVICE_UUID)],
        continuousUpdates: true,
      );
      _isScanning = true;
      debugPrint('Mesh Scanning Started');
    } catch (e) {
      debugPrint('Failed to start scanning: $e');
    }
  }

  Future<void> _connectToPeer(BluetoothDevice device) async {
    if (_connectedPeers.contains(device)) return;

    try {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 5));
      if (!_connectedPeers.contains(device)) {
        _connectedPeers.add(device);
        _updatePeerCount();
      }
      debugPrint('Connected to peer: ${device.remoteId}');

      // Listen for unexpected disconnects
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          if (_connectedPeers.contains(device)) {
            _connectedPeers.remove(device);
            _updatePeerCount();
            debugPrint('Peer disconnected: ${device.remoteId}');
          }
        }
      });

      // Initiate Sync
      await _syncWithPeer(device);

    } catch (e) {
      debugPrint('Connection failed to ${device.remoteId}: $e');
      _connectedPeers.remove(device);
      _updatePeerCount();
    }
  }

  Future<void> _syncWithPeer(BluetoothDevice device) async {
    // 1. Discover Services
    List<BluetoothService> services = await device.discoverServices();
    BluetoothService? meshService;
    
    for (var service in services) {
      if (service.uuid.toString().toUpperCase() == RESCUE_MESH_SERVICE_UUID.toUpperCase()) {
        meshService = service;
        break;
      }
    }

    if (meshService == null) return;

    // 2. We will assume there is a characteristic for reading/writing packets
    // In a full implementation, you define RX/TX characteristics.
    // For MVP, we simulate pulling messages from SyncEngine and attempting to send.
    
    List<MeshPacket> messagesToSend = await _syncEngine.handlePeerConnected();
    
    for (var char in meshService.characteristics) {
      if (char.properties.write) {
        for (var msg in messagesToSend) {
          try {
             await char.write(msg.toBleBytes());
          } catch(e) {
             debugPrint('Failed to send message over BLE: $e');
          }
        }
      }
      
      // Also subscribe to incoming messages
      if (char.properties.notify) {
        await char.setNotifyValue(true);
        char.onValueReceived.listen((value) async {
           try {
              MeshPacket incoming = MeshPacket.fromBleBytes(value);
              bool isNew = await _syncEngine.processIncomingPacket(incoming);
              if (isNew) {
                // If it's a new packet, we might want to broadcast it to other connected peers
                debugPrint('Received new message from mesh: ${incoming.msgId}');
              }
           } catch(e) {
              debugPrint('Error decoding incoming BLE message: $e');
           }
        });
      }
    }
  }

  Future<void> stopAll() async {
    await _blePeripheral.stop();
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _isAdvertising = false;
    _isScanning = false;
    for (var peer in _connectedPeers) {
      await peer.disconnect();
    }
    _connectedPeers.clear();
    _updatePeerCount();
  }
}
