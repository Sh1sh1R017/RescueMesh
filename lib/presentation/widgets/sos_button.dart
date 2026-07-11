import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SosButton extends StatelessWidget {
  final VoidCallback onSosTriggered;

  const SosButton({Key? key, required this.onSosTriggered}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        _showSosConfirmationDialog(context);
      },
      backgroundColor: AppTheme.criticalColor,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4), // Sharp corners for field utility feel
      ),
      child: const Icon(Icons.sos, size: 28),
    );
  }

  void _showSosConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppTheme.criticalColor, width: 2),
          ),
          title: const Text(
            'TRIGGER SOS', 
            style: TextStyle(
              color: AppTheme.criticalColor, 
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            )
          ),
          content: const Text(
            'This action will queue a high-priority emergency alert containing your exact location. It will be broadcast to all connected nodes.',
            style: TextStyle(color: AppTheme.textPrimaryColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondaryColor),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onSosTriggered();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('SOS queued — will send when a peer connects.'),
                    backgroundColor: AppTheme.surfaceColor,
                    behavior: SnackBarBehavior.floating,
                  )
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.criticalColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('CONFIRM SOS'),
            ),
          ],
        );
      },
    );
  }
}
