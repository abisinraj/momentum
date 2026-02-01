import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'health_connect_service.dart';

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

  void markAsHandled() => state = true;
}

@riverpod
class PermissionService extends _$PermissionService {
  @override
  void build() {}

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
    final healthConnectGranted = await HealthConnectService().hasPermissions();
    results[AppPermission.healthConnect] = PermissionStatusInfo(
      permission: AppPermission.healthConnect,
      isGranted: healthConnectGranted,
    );

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
