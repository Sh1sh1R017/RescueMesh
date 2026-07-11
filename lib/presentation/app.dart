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
import '../../domain/services/location_service.dart';

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
      theme: AppTheme.darkTheme, 
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
        backgroundColor: AppTheme.surfaceColor,
        selectedItemColor: AppTheme.textPrimaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
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
        onSosTriggered: () async {
          final locationService = LocationService();
          final locString = await locationService.getEmergencyLocationString();
          
          debugPrint('Generated SOS with Location: \$locString');
          // TODO: Actually construct and save SOS packet to DB, then mesh will pick it up
        }
      ) : null, // Only show SOS heavily on Dashboard to prevent accidental clicks on map
    );
  }

  Widget _buildGlobalStatusBar(MeshState meshState) {
    bool isConnected = meshState.connectedPeersCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(bottom: BorderSide(color: AppTheme.surfaceVariantColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                size: 16,
                color: isConnected ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'MESH ACTIVE' : 'SEARCHING...',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          Text(
            'NODES: \${meshState.connectedPeersCount}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
