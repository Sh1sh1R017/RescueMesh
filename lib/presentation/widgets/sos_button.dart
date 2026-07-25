import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SosButton extends StatelessWidget {
  final Future<bool> Function() onSosTriggered;

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
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
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
          content: Text(
            'This action will queue a high-priority emergency alert containing your exact location. It will be broadcast to all connected nodes.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).textTheme.bodyMedium?.color),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final messenger = ScaffoldMessenger.of(context);
                final success = await onSosTriggered();
                
                if (success) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('SOS queued — will send when a peer connects.'),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      behavior: SnackBarBehavior.floating,
                    )
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('SOS failed to queue. Please check location permissions.'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    )
                  );
                }
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
