import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SosButton extends StatefulWidget {
  final VoidCallback onSosTriggered;

  const SosButton({Key? key, required this.onSosTriggered}) : super(key: key);

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: () {
          _showSosConfirmationDialog(context);
        },
        backgroundColor: AppTheme.primaryColor,
        elevation: 8,
        child: const Icon(Icons.sos, color: Colors.white, size: 36),
      ),
    );
  }

  void _showSosConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('TRIGGER SOS?', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          content: const Text(
            'This will flood the mesh network with a high-priority emergency alert containing your exact location. Only use this for immediate danger to life or limb.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondaryColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onSosTriggered();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('SOS Alert Broadcasted to Mesh Network!'),
                    backgroundColor: AppTheme.primaryColor,
                  )
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('BROADCAST SOS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
