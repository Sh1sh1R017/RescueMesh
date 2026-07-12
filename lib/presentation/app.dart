import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/mesh_provider.dart';

// Screens
import 'dashboard/dashboard_screen.dart';
import 'map/map_screen.dart';
import 'feed/feed_screen.dart';
import 'resources/resources_screen.dart';
import 'widgets/sos_button.dart';
import '../domain/services/location_service.dart';
import '../domain/models/mesh_packet.dart';
import '../providers/device_identity_provider.dart';
import '../providers/message_provider.dart';

class RescueMeshApp extends ConsumerStatefulWidget {
  const RescueMeshApp({Key? key}) : super(key: key);

  @override
  ConsumerState<RescueMeshApp> createState() => _RescueMeshAppState();
}

class _RescueMeshAppState extends ConsumerState<RescueMeshApp> {
  @override
  void initState() {
    super.initState();
    // Initialize mesh network on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(meshStateProvider.notifier).initializeMesh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RescueMesh',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainDashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen> {
  int _currentIndex = 0;

  Future<bool> _triggerSos(WidgetRef ref) async {
    try {
      final locString = await LocationService().getEmergencyLocationString();
      final nodeId = ref.read(deviceIdentityProvider);
      final syncEngine = ref.read(syncEngineProvider);
      
      final packet = MeshPacket(
        msgId: 'sos_${DateTime.now().millisecondsSinceEpoch}',
        originNodeId: nodeId,
        type: 1, // SOS
        priority: 3, // CRITICAL
        timestamp: DateTime.now().millisecondsSinceEpoch,
        ttl: 86400000, // 24h
        hopCount: 0,
        payload: locString,
      );
      
      final success = await syncEngine.queueOutgoingPacket(packet);
      if (success) {
        ref.invalidate(messagesRefreshProvider);
        ref.read(meshServiceProvider).startScanning();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('SOS trigger failed: $e');
      return false;
    }
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MapScreen(),
    const FeedScreen(),
    const ResourcesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final meshState = ref.watch(meshStateProvider);
    final bool isConnected = meshState.connectedPeersCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RescueMesh'),
        // No centered title, left aligned utility style via theme
      ),
      body: Column(
        children: [
          _buildGlobalStatusBar(meshState),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).textTheme.bodyMedium?.color,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Resources',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? SosButton(
        onSosTriggered: () => _triggerSos(ref),
      ) : null,
    );
  }

  Widget _buildGlobalStatusBar(MeshState meshState) {
    bool isConnected = meshState.connectedPeersCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                size: 16,
                color: isConnected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'MESH ACTIVE' : 'SEARCHING...',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          Text(
            'NODES: ${meshState.connectedPeersCount}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
