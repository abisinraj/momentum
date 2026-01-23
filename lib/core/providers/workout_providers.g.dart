// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeWorkoutSessionHash() =>
    r'cf4771ac44e74c6139e059d34cf01e3d4605d98d';

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
String _$workoutManagerHash() => r'334da5d305ac3833a9f5197d84155c8b711748b6';

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
