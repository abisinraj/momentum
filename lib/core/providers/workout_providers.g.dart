// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeWorkoutSessionHash() =>
    r'3866afe7b143d176f893e8c36bde541b66635d85';

/// Notifier for managing active workout session
///
/// Copied from [ActiveWorkoutSession].
@ProviderFor(ActiveWorkoutSession)
final activeWorkoutSessionProvider =
    AutoDisposeNotifierProvider<ActiveWorkoutSession, ActiveSession?>.internal(
      ActiveWorkoutSession.new,
      name: r'activeWorkoutSessionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeWorkoutSessionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveWorkoutSession = AutoDisposeNotifier<ActiveSession?>;
String _$workoutManagerHash() => r'f58f052282cdfc5dfa2fd4685f3b128708462647';

/// Provider for adding a new workout
///
/// Copied from [WorkoutManager].
@ProviderFor(WorkoutManager)
final workoutManagerProvider =
    AutoDisposeAsyncNotifierProvider<WorkoutManager, void>.internal(
      WorkoutManager.new,
      name: r'workoutManagerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$workoutManagerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WorkoutManager = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
