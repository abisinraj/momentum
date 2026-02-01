import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../core/services/permission_service.dart';

class PermissionBottomSheet extends ConsumerStatefulWidget {
  final Map<AppPermission, PermissionStatusInfo> missingPermissions;

  const PermissionBottomSheet({
    super.key,
    required this.missingPermissions,
  });

  @override
  ConsumerState<PermissionBottomSheet> createState() => _PermissionBottomSheetState();
}

class _PermissionBottomSheetState extends ConsumerState<PermissionBottomSheet> {
  late Map<AppPermission, PermissionStatusInfo> _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = Map.from(widget.missingPermissions);
  }

  Future<void> _handleGrantAll() async {
    final service = ref.read(permissionServiceProvider.notifier);
    
    // Attempt everything sequentially to avoid system UI overlap issues
    for (final permission in _currentStatus.keys) {
      if (!_currentStatus[permission]!.isGranted) {
        try {
          // Add a 10-second timeout per permission to prevent being stuck forever
          await service.requestPermission(permission).timeout(
            const Duration(seconds: 10),
            onTimeout: () => false,
          );
        } catch (e) {
          debugPrint('[PermissionSheet] Error requesting $permission: $e');
        }
      }
    }

    final newStatus = await service.checkAllPermissions();
    if (mounted) {
      setState(() {
        _currentStatus = newStatus;
      });

      // ALWAYS close after attempting to grant all. 
      // If some failed, they'll be "Limited Access" users.
      // We don't want to get them stuck in a loop.
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'PERMISSIONS',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Grant access to enable tracking and AI features.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          // Wrap in flexible to handle small screens
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: _currentStatus.entries.map((entry) => _buildPermissionItem(entry.key, entry.value)).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _handleGrantAll,
              child: const Text('GRANT ALL PERMISSIONS'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.darkBorder),
                foregroundColor: AppTheme.textMuted,
              ),
              child: const Text('CONTINUE WITH LIMITED ACCESS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(AppPermission permission, PermissionStatusInfo status) {
    final info = _getPermissionInfo(permission);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: status.isGranted 
                  ? AppTheme.success.withValues(alpha: 0.1)
                  : AppTheme.darkSurfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              info.icon,
              color: status.isGranted ? AppTheme.success : AppTheme.tealPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  info.description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (status.isGranted)
            const Icon(Icons.check_circle, color: AppTheme.success)
          else
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  _PermissionDescriptor _getPermissionInfo(AppPermission permission) {
    switch (permission) {
      case AppPermission.activityRecognition:
        return _PermissionDescriptor(
          icon: Icons.directions_run,
          title: 'Activity Tracking',
          description: 'Required to count your daily steps.',
        );
      case AppPermission.camera:
        return _PermissionDescriptor(
          icon: Icons.camera_alt,
          title: 'Camera Access',
          description: 'Used for AI equipment & meal recognition.',
        );
      case AppPermission.notifications:
        return _PermissionDescriptor(
          icon: Icons.notifications,
          title: 'Notifications',
          description: 'Reminders for your scheduled workouts.',
        );
      case AppPermission.healthConnect:
        return _PermissionDescriptor(
          icon: Icons.favorite,
          title: 'Health Connect',
          description: 'Sync weight, sleep, and heart rate data.',
        );
    }
  }
}

class _PermissionDescriptor {
  final IconData icon;
  final String title;
  final String description;

  _PermissionDescriptor({
    required this.icon,
    required this.title,
    required this.description,
  });
}
