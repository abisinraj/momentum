// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isSetupCompleteSyncHash() =>
    r'3d1a01f533f859d74e2f60a775d0e80fd360b765';

/// Provider for checking if setup is complete (synchronous check for router)
/// This watches the async provider and returns false until loaded
///
/// Copied from [isSetupCompleteSync].
@ProviderFor(isSetupCompleteSync)
final isSetupCompleteSyncProvider = AutoDisposeProvider<bool>.internal(
  isSetupCompleteSync,
  name: r'isSetupCompleteSyncProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isSetupCompleteSyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsSetupCompleteSyncRef = AutoDisposeProviderRef<bool>;
String _$currentCyclePositionHash() =>
    r'a1ac4bfe02b71010c68ec07871c75497aea29df0';

/// Provider for current cycle position
///
/// Copied from [currentCyclePosition].
@ProviderFor(currentCyclePosition)
final currentCyclePositionProvider = AutoDisposeProvider<int>.internal(
  currentCyclePosition,
  name: r'currentCyclePositionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentCyclePositionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentCyclePositionRef = AutoDisposeProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
