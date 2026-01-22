// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_connect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$healthConnectServiceHash() =>
    r'9df35e84c3a0fbec8a5e0bfc47919749085bc73e';

/// Provider for the Health Connect service instance.
///
/// Copied from [healthConnectService].
@ProviderFor(healthConnectService)
final healthConnectServiceProvider =
    AutoDisposeProvider<HealthConnectService>.internal(
      healthConnectService,
      name: r'healthConnectServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$healthConnectServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HealthConnectServiceRef = AutoDisposeProviderRef<HealthConnectService>;
String _$healthNotifierHash() => r'c85788d6a92102c3f063639bc00a033d8f8bab25';

/// Notifier for managing health data state.
///
/// Copied from [HealthNotifier].
@ProviderFor(HealthNotifier)
final healthNotifierProvider =
    AutoDisposeNotifierProvider<HealthNotifier, HealthState>.internal(
      HealthNotifier.new,
      name: r'healthNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$healthNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HealthNotifier = AutoDisposeNotifier<HealthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
