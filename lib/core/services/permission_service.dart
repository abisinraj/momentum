import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'health_connect_service.dart';
import 'settings_service.dart';
import 'package:flutter/foundation.dart';

part 'permission_service.g.dart';

enum AppPermission {
  activityRecognition,
  camera,
  notifications,
  healthConnect,
}

class PermissionStatusInfo {
  final AppPermission permission;
  final bool isGranted;
  final bool isPermanentlyDenied;

  PermissionStatusInfo({
    required this.permission,
    required this.isGranted,
    this.isPermanentlyDenied = false,
  });
}

@riverpod
class PermissionsHandled extends _$PermissionsHandled {
  @override
  bool build() => false;

  Future<void> markAsHandled() async {
    state = true;
    await ref.read(permissionServiceProvider.notifier).markAsHandled();
  }
}

@riverpod
class PermissionService extends _$PermissionService {
  @override
  void build() {}

  Future<bool> isHandled() async {
    return await ref.read(settingsServiceProvider).getPermissionsHandled();
  }

  Future<void> markAsHandled() async {
    await ref.read(settingsServiceProvider).setPermissionsHandled(true);
  }

  Future<Map<AppPermission, PermissionStatusInfo>> checkStartupPermissions() async {
    final handled = await isHandled();
    if (handled) return {}; 
    return await checkAllPermissions();
  }

  Future<Map<AppPermission, PermissionStatusInfo>> checkAllPermissions() async {
    final results = <AppPermission, PermissionStatusInfo>{};

    // Activity Recognition
    final activity = await Permission.activityRecognition.status;
    results[AppPermission.activityRecognition] = PermissionStatusInfo(
      permission: AppPermission.activityRecognition,
      isGranted: activity.isGranted,
      isPermanentlyDenied: activity.isPermanentlyDenied,
    );

    // Camera
    final camera = await Permission.camera.status;
    results[AppPermission.camera] = PermissionStatusInfo(
      permission: AppPermission.camera,
      isGranted: camera.isGranted,
      isPermanentlyDenied: camera.isPermanentlyDenied,
    );

    // Notifications
    final notifications = await Permission.notification.status;
    results[AppPermission.notifications] = PermissionStatusInfo(
      permission: AppPermission.notifications,
      isGranted: notifications.isGranted,
      isPermanentlyDenied: notifications.isPermanentlyDenied,
    );

    // Health Connect
    try {
      final healthConnectStatus = await HealthConnectService.checkAvailability();
      if (healthConnectStatus == HealthConnectSdkStatus.sdkAvailable) {
        final healthConnectGranted = await HealthConnectService().hasPermissions();
        results[AppPermission.healthConnect] = PermissionStatusInfo(
          permission: AppPermission.healthConnect,
          isGranted: healthConnectGranted,
        );
      }
    } catch (e) {
      debugPrint('[PermissionService] Error checking Health Connect: $e');
    }

    return results;
  }

  Future<bool> requestPermission(AppPermission permission) async {
    switch (permission) {
      case AppPermission.activityRecognition:
        return (await Permission.activityRecognition.request()).isGranted;
      case AppPermission.camera:
        return (await Permission.camera.request()).isGranted;
      case AppPermission.notifications:
        return (await Permission.notification.request()).isGranted;
      case AppPermission.healthConnect:
        return await HealthConnectService().requestPermissions();
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
