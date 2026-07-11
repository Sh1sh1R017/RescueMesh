import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: AppTheme.infoColor,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              tabs: [
                Tab(text: 'Available'),
                Tab(text: 'Needed'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAvailableList(),
                  _buildNeededList(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Open share resource form
        },
        backgroundColor: AppTheme.infoColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Share Resource', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAvailableList() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildResourceCard('Fresh Water', '100L available. Bring your own containers.', '0.5 km', Icons.water_drop),
        _buildResourceCard('Generator Power', 'Running until 8PM. Charge phones/radios.', '1.2 km', Icons.electrical_services),
        _buildResourceCard('First Aid Kits', 'Basic supplies, bandages, antiseptics.', '3.0 km', Icons.medical_services),
      ],
    );
  }

  Widget _buildNeededList() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildNeededCard('Baby Formula', 'Need formula for 6 month old.', 'High'),
        _buildNeededCard('Insulin', 'Type 1 Diabetic requires immediate insulin.', 'Critical'),
      ],
    );
  }

  Widget _buildResourceCard(String title, String desc, String dist, IconData icon) {
    return Card(
      color: AppTheme.surfaceColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.infoColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(desc, style: const TextStyle(color: AppTheme.textSecondaryColor)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(dist, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNeededCard(String title, String desc, String priority) {
    Color pColor = priority == 'Critical' ? AppTheme.primaryColor : AppTheme.secondaryColor;
    return Card(
      color: AppTheme.surfaceColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(desc, style: const TextStyle(color: AppTheme.textSecondaryColor)),
        trailing: Chip(
          label: Text(priority, style: TextStyle(color: pColor, fontSize: 12)),
          backgroundColor: pColor.withOpacity(0.2),
          side: BorderSide.none,
        ),
      ),
    );
  }
}
