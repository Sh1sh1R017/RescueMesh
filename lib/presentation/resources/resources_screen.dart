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
              tabs: [
                Tab(text: 'Available'),
                Tab(text: 'Needed'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAvailableList(),
                  _buildNeededList(context),
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
        icon: const Icon(Icons.add),
        label: const Text('Share Resource'),
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

  Widget _buildNeededList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildNeededCard(context, 'Baby Formula', 'Need formula for 6 month old.', 'High'),
        _buildNeededCard(context, 'Insulin', 'Type 1 Diabetic requires immediate insulin.', 'Critical'),
      ],
    );
  }

  Widget _buildResourceCard(String title, String desc, String dist, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(desc),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(dist, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNeededCard(BuildContext context, String title, String desc, String priority) {
    Color pColor = priority == 'Critical' ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(desc),
        trailing: Chip(
          label: Text(priority, style: TextStyle(color: pColor, fontSize: 12)),
          backgroundColor: pColor.withValues(alpha: 0.2),
          side: BorderSide.none,
        ),
      ),
    );
  }
}
