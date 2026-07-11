import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class RescueMeshApp extends StatelessWidget {
  const RescueMeshApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RescueMesh',
      theme: AppTheme.darkTheme, // Force dark/high-contrast theme for battery & visibility
      home: const MainDashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PlaceholderScreen(title: 'Emergency Dashboard'),
    const PlaceholderScreen(title: 'Situation Map'),
    const PlaceholderScreen(title: 'Neighborhood Feed'),
    const PlaceholderScreen(title: 'Resource Sharing'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RescueMesh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_connected, color: AppTheme.safeColor),
            onPressed: () {
              // TODO: Show mesh connection status
            },
          )
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceColor,
        selectedItemColor: AppTheme.primaryColor,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          // TODO: Open SOS Creation Dialog
        },
        child: const Icon(Icons.sos, color: Colors.white, size: 32),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context).textTheme.displayMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
