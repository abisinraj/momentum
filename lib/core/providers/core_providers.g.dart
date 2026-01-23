// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for checking if setup is complete (synchronous check for router)
/// This watches the async provider and returns false until loaded

@ProviderFor(isSetupCompleteSync)
final isSetupCompleteSyncProvider = IsSetupCompleteSyncProvider._();

/// Provider for checking if setup is complete (synchronous check for router)
/// This watches the async provider and returns false until loaded

final class IsSetupCompleteSyncProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider for checking if setup is complete (synchronous check for router)
  /// This watches the async provider and returns false until loaded
  IsSetupCompleteSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isSetupCompleteSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isSetupCompleteSyncHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isSetupCompleteSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isSetupCompleteSyncHash() =>
    r'3d1a01f533f859d74e2f60a775d0e80fd360b765';

/// Provider for current cycle position

@ProviderFor(currentCyclePosition)
final currentCyclePositionProvider = CurrentCyclePositionProvider._();

/// Provider for current cycle position

final class CurrentCyclePositionProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Provider for current cycle position
  CurrentCyclePositionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentCyclePositionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentCyclePositionHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return currentCyclePosition(ref);
  }
}

String _$currentCyclePositionHash() =>
    r'6f943248f2b2d405e5f36b188650d4c0491c074c';
