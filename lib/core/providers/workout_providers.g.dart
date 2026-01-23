// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing active workout session

@ProviderFor(ActiveWorkoutSession)
final activeWorkoutSessionProvider = ActiveWorkoutSessionProvider._();

/// Notifier for managing active workout session
final class ActiveWorkoutSessionProvider
    extends $NotifierProvider<ActiveWorkoutSession, ActiveSession?> {
  /// Notifier for managing active workout session
  ActiveWorkoutSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeWorkoutSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeWorkoutSessionHash();

  @$internal
  @override
  ActiveWorkoutSession create() => ActiveWorkoutSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveSession?>(value),
    );
  }
}

String _$activeWorkoutSessionHash() =>
    r'cf4771ac44e74c6139e059d34cf01e3d4605d98d';

/// Notifier for managing active workout session

abstract class _$ActiveWorkoutSession extends $Notifier<ActiveSession?> {
  ActiveSession? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ActiveSession?, ActiveSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActiveSession?, ActiveSession?>,
              ActiveSession?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for adding a new workout

@ProviderFor(WorkoutManager)
final workoutManagerProvider = WorkoutManagerProvider._();

/// Provider for adding a new workout
final class WorkoutManagerProvider
    extends $AsyncNotifierProvider<WorkoutManager, void> {
  /// Provider for adding a new workout
  WorkoutManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutManagerHash();

  @$internal
  @override
  WorkoutManager create() => WorkoutManager();
}

String _$workoutManagerHash() => r'334da5d305ac3833a9f5197d84155c8b711748b6';

/// Provider for adding a new workout

abstract class _$WorkoutManager extends $AsyncNotifier<void> {
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
