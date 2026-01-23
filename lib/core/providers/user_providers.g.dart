// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing user setup

@ProviderFor(UserSetup)
final userSetupProvider = UserSetupProvider._();

/// Notifier for managing user setup
final class UserSetupProvider extends $AsyncNotifierProvider<UserSetup, void> {
  /// Notifier for managing user setup
  UserSetupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userSetupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userSetupHash();

  @$internal
  @override
  UserSetup create() => UserSetup();
}

String _$userSetupHash() => r'd16330e1dea0296f3df953a1846e76b0581d288f';

/// Notifier for managing user setup

abstract class _$UserSetup extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
