// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_connect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the Health Connect service instance.

@ProviderFor(healthConnectService)
final healthConnectServiceProvider = HealthConnectServiceProvider._();

/// Provider for the Health Connect service instance.

final class HealthConnectServiceProvider
    extends
        $FunctionalProvider<
          HealthConnectService,
          HealthConnectService,
          HealthConnectService
        >
    with $Provider<HealthConnectService> {
  /// Provider for the Health Connect service instance.
  HealthConnectServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthConnectServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthConnectServiceHash();

  @$internal
  @override
  $ProviderElement<HealthConnectService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HealthConnectService create(Ref ref) {
    return healthConnectService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthConnectService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthConnectService>(value),
    );
  }
}

String _$healthConnectServiceHash() =>
    r'9df35e84c3a0fbec8a5e0bfc47919749085bc73e';

/// Notifier for managing health data state.

@ProviderFor(HealthNotifier)
final healthProvider = HealthNotifierProvider._();

/// Notifier for managing health data state.
final class HealthNotifierProvider
    extends $NotifierProvider<HealthNotifier, HealthState> {
  /// Notifier for managing health data state.
  HealthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthNotifierHash();

  @$internal
  @override
  HealthNotifier create() => HealthNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthState>(value),
    );
  }
}

String _$healthNotifierHash() => r'c85788d6a92102c3f063639bc00a033d8f8bab25';

/// Notifier for managing health data state.

abstract class _$HealthNotifier extends $Notifier<HealthState> {
  HealthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<HealthState, HealthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HealthState, HealthState>,
              HealthState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
