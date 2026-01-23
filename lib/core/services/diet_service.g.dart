// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diet_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dietService)
final dietServiceProvider = DietServiceProvider._();

final class DietServiceProvider
    extends $FunctionalProvider<DietService, DietService, DietService>
    with $Provider<DietService> {
  DietServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dietServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dietServiceHash();

  @$internal
  @override
  $ProviderElement<DietService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DietService create(Ref ref) {
    return dietService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DietService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DietService>(value),
    );
  }
}

String _$dietServiceHash() => r'ee6621e5cf44f9b16a920cee03ec8e0ee3e843d5';
