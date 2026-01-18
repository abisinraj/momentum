// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'349bdc5ecf86e2022b35a6f6ebcde1c324ac0862';

/// Single database instance for the entire app
///
/// Copied from [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = Provider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = ProviderRef<AppDatabase>;
String _$isSetupCompleteHash() => r'e53b542d1a50bb8eefc6d005943c115b68f462b2';

/// Provider for checking if setup is complete (from database)
///
/// Copied from [isSetupComplete].
@ProviderFor(isSetupComplete)
final isSetupCompleteProvider = AutoDisposeFutureProvider<bool>.internal(
  isSetupComplete,
  name: r'isSetupCompleteProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isSetupCompleteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsSetupCompleteRef = AutoDisposeFutureProviderRef<bool>;
String _$currentUserHash() => r'8a89dc8ea33f61d168b667f017bae49b82e1e1ef';

/// Provider for the current user
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeFutureProvider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeFutureProviderRef<User?>;
String _$workoutsStreamHash() => r'9bed1e2e1093cabff3f10058ee237acef5568bcc';

/// Provider for all workouts (reactive stream)
///
/// Copied from [workoutsStream].
@ProviderFor(workoutsStream)
final workoutsStreamProvider =
    AutoDisposeStreamProvider<List<Workout>>.internal(
      workoutsStream,
      name: r'workoutsStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$workoutsStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WorkoutsStreamRef = AutoDisposeStreamProviderRef<List<Workout>>;
String _$todayCompletedWorkoutIdsHash() =>
    r'ebced50361cb5c7bd4cde2f9089f331a9a846916';

/// Provider for today's completed workout IDs
///
/// Copied from [todayCompletedWorkoutIds].
@ProviderFor(todayCompletedWorkoutIds)
final todayCompletedWorkoutIdsProvider =
    AutoDisposeFutureProvider<List<int>>.internal(
      todayCompletedWorkoutIds,
      name: r'todayCompletedWorkoutIdsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$todayCompletedWorkoutIdsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodayCompletedWorkoutIdsRef = AutoDisposeFutureProviderRef<List<int>>;
String _$nextWorkoutHash() => r'e44cb96d7ea50c5186ff8bc274589edf44eb4633';

/// Provider for the next workout in the cycle
///
/// Copied from [nextWorkout].
@ProviderFor(nextWorkout)
final nextWorkoutProvider = AutoDisposeFutureProvider<Workout?>.internal(
  nextWorkout,
  name: r'nextWorkoutProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nextWorkoutHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NextWorkoutRef = AutoDisposeFutureProviderRef<Workout?>;
String _$activityGridHash() => r'0b874fac8881c5934bbf09bff538a329b731cd3c';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider for activity grid data (last N days)
///
/// Copied from [activityGrid].
@ProviderFor(activityGrid)
const activityGridProvider = ActivityGridFamily();

/// Provider for activity grid data (last N days)
///
/// Copied from [activityGrid].
class ActivityGridFamily extends Family<AsyncValue<Map<DateTime, String>>> {
  /// Provider for activity grid data (last N days)
  ///
  /// Copied from [activityGrid].
  const ActivityGridFamily();

  /// Provider for activity grid data (last N days)
  ///
  /// Copied from [activityGrid].
  ActivityGridProvider call({int days = 30}) {
    return ActivityGridProvider(days: days);
  }

  @override
  ActivityGridProvider getProviderOverride(
    covariant ActivityGridProvider provider,
  ) {
    return call(days: provider.days);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'activityGridProvider';
}

/// Provider for activity grid data (last N days)
///
/// Copied from [activityGrid].
class ActivityGridProvider
    extends AutoDisposeFutureProvider<Map<DateTime, String>> {
  /// Provider for activity grid data (last N days)
  ///
  /// Copied from [activityGrid].
  ActivityGridProvider({int days = 30})
    : this._internal(
        (ref) => activityGrid(ref as ActivityGridRef, days: days),
        from: activityGridProvider,
        name: r'activityGridProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$activityGridHash,
        dependencies: ActivityGridFamily._dependencies,
        allTransitiveDependencies:
            ActivityGridFamily._allTransitiveDependencies,
        days: days,
      );

  ActivityGridProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.days,
  }) : super.internal();

  final int days;

  @override
  Override overrideWith(
    FutureOr<Map<DateTime, String>> Function(ActivityGridRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActivityGridProvider._internal(
        (ref) => create(ref as ActivityGridRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        days: days,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<DateTime, String>> createElement() {
    return _ActivityGridProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActivityGridProvider && other.days == days;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, days.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ActivityGridRef on AutoDisposeFutureProviderRef<Map<DateTime, String>> {
  /// The parameter `days` of this provider.
  int get days;
}

class _ActivityGridProviderElement
    extends AutoDisposeFutureProviderElement<Map<DateTime, String>>
    with ActivityGridRef {
  _ActivityGridProviderElement(super.provider);

  @override
  int get days => (origin as ActivityGridProvider).days;
}

String _$exercisesForWorkoutHash() =>
    r'b6929e591567145ec1226195b2c0763b2431dd40';

/// Provider for exercises in a workout
///
/// Copied from [exercisesForWorkout].
@ProviderFor(exercisesForWorkout)
const exercisesForWorkoutProvider = ExercisesForWorkoutFamily();

/// Provider for exercises in a workout
///
/// Copied from [exercisesForWorkout].
class ExercisesForWorkoutFamily extends Family<AsyncValue<List<Exercise>>> {
  /// Provider for exercises in a workout
  ///
  /// Copied from [exercisesForWorkout].
  const ExercisesForWorkoutFamily();

  /// Provider for exercises in a workout
  ///
  /// Copied from [exercisesForWorkout].
  ExercisesForWorkoutProvider call(int workoutId) {
    return ExercisesForWorkoutProvider(workoutId);
  }

  @override
  ExercisesForWorkoutProvider getProviderOverride(
    covariant ExercisesForWorkoutProvider provider,
  ) {
    return call(provider.workoutId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'exercisesForWorkoutProvider';
}

/// Provider for exercises in a workout
///
/// Copied from [exercisesForWorkout].
class ExercisesForWorkoutProvider
    extends AutoDisposeFutureProvider<List<Exercise>> {
  /// Provider for exercises in a workout
  ///
  /// Copied from [exercisesForWorkout].
  ExercisesForWorkoutProvider(int workoutId)
    : this._internal(
        (ref) => exercisesForWorkout(ref as ExercisesForWorkoutRef, workoutId),
        from: exercisesForWorkoutProvider,
        name: r'exercisesForWorkoutProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$exercisesForWorkoutHash,
        dependencies: ExercisesForWorkoutFamily._dependencies,
        allTransitiveDependencies:
            ExercisesForWorkoutFamily._allTransitiveDependencies,
        workoutId: workoutId,
      );

  ExercisesForWorkoutProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.workoutId,
  }) : super.internal();

  final int workoutId;

  @override
  Override overrideWith(
    FutureOr<List<Exercise>> Function(ExercisesForWorkoutRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ExercisesForWorkoutProvider._internal(
        (ref) => create(ref as ExercisesForWorkoutRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        workoutId: workoutId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Exercise>> createElement() {
    return _ExercisesForWorkoutProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExercisesForWorkoutProvider && other.workoutId == workoutId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, workoutId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ExercisesForWorkoutRef on AutoDisposeFutureProviderRef<List<Exercise>> {
  /// The parameter `workoutId` of this provider.
  int get workoutId;
}

class _ExercisesForWorkoutProviderElement
    extends AutoDisposeFutureProviderElement<List<Exercise>>
    with ExercisesForWorkoutRef {
  _ExercisesForWorkoutProviderElement(super.provider);

  @override
  int get workoutId => (origin as ExercisesForWorkoutProvider).workoutId;
}

String _$weeklyStatsHash() => r'e72e44a89933eaec9e36add3e194acb27916806b';

/// Provider for weekly stats
///
/// Copied from [weeklyStats].
@ProviderFor(weeklyStats)
final weeklyStatsProvider =
    AutoDisposeFutureProvider<Map<String, int>>.internal(
      weeklyStats,
      name: r'weeklyStatsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$weeklyStatsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WeeklyStatsRef = AutoDisposeFutureProviderRef<Map<String, int>>;
String _$weeklyInsightHash() => r'75146fca320485cbc5539b7db547f44fa0af43b7';

/// Provider for weekly insight text
///
/// Copied from [weeklyInsight].
@ProviderFor(weeklyInsight)
final weeklyInsightProvider = AutoDisposeFutureProvider<String>.internal(
  weeklyInsight,
  name: r'weeklyInsightProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$weeklyInsightHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WeeklyInsightRef = AutoDisposeFutureProviderRef<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
