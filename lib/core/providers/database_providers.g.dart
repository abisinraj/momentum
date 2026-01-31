// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'448adad5717e7b1c0b3ca3ca7e03d0b2116237af';

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
String _$isSetupCompleteHash() => r'193889f2209c4a353b314b42535079977e9b31c9';

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
String _$currentUserHash() => r'044d37f89fcd07d7b08aa8d56e567883b9882577';

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
String _$userStreamHash() => r'ab8074f60635aafd3dfcb6c9fb20da7040060835';

/// Provider for watching the current user
///
/// Copied from [userStream].
@ProviderFor(userStream)
final userStreamProvider = AutoDisposeStreamProvider<User?>.internal(
  userStream,
  name: r'userStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserStreamRef = AutoDisposeStreamProviderRef<User?>;
String _$workoutsStreamHash() => r'851ce9a4b956ebb3ae278a076f0fe0d18aae2907';

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
    r'709e98fe2defe6b0ffa9551fb24728bfd26833fc';

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
String _$nextWorkoutHash() => r'3c65998fd60cfec3534093abcc09cf3442ffe258';

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
String _$activityGridHash() => r'3d18482915f88257e3a503f7d3b614e988b930e8';

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
/// Provider for activity grid data (last N days)
///
/// Copied from [activityGrid].
@ProviderFor(activityGrid)
const activityGridProvider = ActivityGridFamily();

/// Provider for activity grid data (last N days)
/// Provider for activity grid data (last N days)
///
/// Copied from [activityGrid].
class ActivityGridFamily extends Family<AsyncValue<Map<DateTime, String>>> {
  /// Provider for activity grid data (last N days)
  /// Provider for activity grid data (last N days)
  ///
  /// Copied from [activityGrid].
  const ActivityGridFamily();

  /// Provider for activity grid data (last N days)
  /// Provider for activity grid data (last N days)
  ///
  /// Copied from [activityGrid].
  ActivityGridProvider call(int days) {
    return ActivityGridProvider(days);
  }

  @override
  ActivityGridProvider getProviderOverride(
    covariant ActivityGridProvider provider,
  ) {
    return call(provider.days);
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
/// Provider for activity grid data (last N days)
///
/// Copied from [activityGrid].
class ActivityGridProvider
    extends AutoDisposeStreamProvider<Map<DateTime, String>> {
  /// Provider for activity grid data (last N days)
  /// Provider for activity grid data (last N days)
  ///
  /// Copied from [activityGrid].
  ActivityGridProvider(int days)
    : this._internal(
        (ref) => activityGrid(ref as ActivityGridRef, days),
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
    Stream<Map<DateTime, String>> Function(ActivityGridRef provider) create,
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
  AutoDisposeStreamProviderElement<Map<DateTime, String>> createElement() {
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
mixin ActivityGridRef on AutoDisposeStreamProviderRef<Map<DateTime, String>> {
  /// The parameter `days` of this provider.
  int get days;
}

class _ActivityGridProviderElement
    extends AutoDisposeStreamProviderElement<Map<DateTime, String>>
    with ActivityGridRef {
  _ActivityGridProviderElement(super.provider);

  @override
  int get days => (origin as ActivityGridProvider).days;
}

String _$exercisesForWorkoutHash() =>
    r'dc2d6ec017acdfdabf439b6516a314dd06534f34';

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

String _$weeklyStatsHash() => r'fdb9ab9a48842fd4a085fe6696163946a0647d96';

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
String _$weeklyInsightHash() => r'836830b14c7bc702fe9fb7a599dab3ee343df060';

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
String _$sessionHistoryHash() => r'f4afdec4153d336270ce91f5b48ad9b384bfaf7c';

/// Provider for session history with workout details
///
/// Copied from [sessionHistory].
@ProviderFor(sessionHistory)
const sessionHistoryProvider = SessionHistoryFamily();

/// Provider for session history with workout details
///
/// Copied from [sessionHistory].
class SessionHistoryFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// Provider for session history with workout details
  ///
  /// Copied from [sessionHistory].
  const SessionHistoryFamily();

  /// Provider for session history with workout details
  ///
  /// Copied from [sessionHistory].
  SessionHistoryProvider call(int limit) {
    return SessionHistoryProvider(limit);
  }

  @override
  SessionHistoryProvider getProviderOverride(
    covariant SessionHistoryProvider provider,
  ) {
    return call(provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sessionHistoryProvider';
}

/// Provider for session history with workout details
///
/// Copied from [sessionHistory].
class SessionHistoryProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// Provider for session history with workout details
  ///
  /// Copied from [sessionHistory].
  SessionHistoryProvider(int limit)
    : this._internal(
        (ref) => sessionHistory(ref as SessionHistoryRef, limit),
        from: sessionHistoryProvider,
        name: r'sessionHistoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sessionHistoryHash,
        dependencies: SessionHistoryFamily._dependencies,
        allTransitiveDependencies:
            SessionHistoryFamily._allTransitiveDependencies,
        limit: limit,
      );

  SessionHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(SessionHistoryRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SessionHistoryProvider._internal(
        (ref) => create(ref as SessionHistoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _SessionHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionHistoryProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SessionHistoryRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _SessionHistoryProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with SessionHistoryRef {
  _SessionHistoryProviderElement(super.provider);

  @override
  int get limit => (origin as SessionHistoryProvider).limit;
}

String _$sessionExerciseDetailsHash() =>
    r'083f69c34c7dc7ba2c0b309547a97edaf266bd7c';

/// Provider for exercise details of a specific session
///
/// Copied from [sessionExerciseDetails].
@ProviderFor(sessionExerciseDetails)
const sessionExerciseDetailsProvider = SessionExerciseDetailsFamily();

/// Provider for exercise details of a specific session
///
/// Copied from [sessionExerciseDetails].
class SessionExerciseDetailsFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// Provider for exercise details of a specific session
  ///
  /// Copied from [sessionExerciseDetails].
  const SessionExerciseDetailsFamily();

  /// Provider for exercise details of a specific session
  ///
  /// Copied from [sessionExerciseDetails].
  SessionExerciseDetailsProvider call(int sessionId) {
    return SessionExerciseDetailsProvider(sessionId);
  }

  @override
  SessionExerciseDetailsProvider getProviderOverride(
    covariant SessionExerciseDetailsProvider provider,
  ) {
    return call(provider.sessionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sessionExerciseDetailsProvider';
}

/// Provider for exercise details of a specific session
///
/// Copied from [sessionExerciseDetails].
class SessionExerciseDetailsProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// Provider for exercise details of a specific session
  ///
  /// Copied from [sessionExerciseDetails].
  SessionExerciseDetailsProvider(int sessionId)
    : this._internal(
        (ref) =>
            sessionExerciseDetails(ref as SessionExerciseDetailsRef, sessionId),
        from: sessionExerciseDetailsProvider,
        name: r'sessionExerciseDetailsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sessionExerciseDetailsHash,
        dependencies: SessionExerciseDetailsFamily._dependencies,
        allTransitiveDependencies:
            SessionExerciseDetailsFamily._allTransitiveDependencies,
        sessionId: sessionId,
      );

  SessionExerciseDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sessionId,
  }) : super.internal();

  final int sessionId;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(
      SessionExerciseDetailsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SessionExerciseDetailsProvider._internal(
        (ref) => create(ref as SessionExerciseDetailsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sessionId: sessionId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _SessionExerciseDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionExerciseDetailsProvider &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sessionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SessionExerciseDetailsRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `sessionId` of this provider.
  int get sessionId;
}

class _SessionExerciseDetailsProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with SessionExerciseDetailsRef {
  _SessionExerciseDetailsProviderElement(super.provider);

  @override
  int get sessionId => (origin as SessionExerciseDetailsProvider).sessionId;
}

String _$sleepLogsHash() => r'2a74c48584013b2ad578161b5c1ed91bf5838ee3';

/// Provider for sleep logs (last 30 days)
///
/// Copied from [sleepLogs].
@ProviderFor(sleepLogs)
const sleepLogsProvider = SleepLogsFamily();

/// Provider for sleep logs (last 30 days)
///
/// Copied from [sleepLogs].
class SleepLogsFamily extends Family<AsyncValue<List<SleepLog>>> {
  /// Provider for sleep logs (last 30 days)
  ///
  /// Copied from [sleepLogs].
  const SleepLogsFamily();

  /// Provider for sleep logs (last 30 days)
  ///
  /// Copied from [sleepLogs].
  SleepLogsProvider call({int days = 30}) {
    return SleepLogsProvider(days: days);
  }

  @override
  SleepLogsProvider getProviderOverride(covariant SleepLogsProvider provider) {
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
  String? get name => r'sleepLogsProvider';
}

/// Provider for sleep logs (last 30 days)
///
/// Copied from [sleepLogs].
class SleepLogsProvider extends AutoDisposeStreamProvider<List<SleepLog>> {
  /// Provider for sleep logs (last 30 days)
  ///
  /// Copied from [sleepLogs].
  SleepLogsProvider({int days = 30})
    : this._internal(
        (ref) => sleepLogs(ref as SleepLogsRef, days: days),
        from: sleepLogsProvider,
        name: r'sleepLogsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sleepLogsHash,
        dependencies: SleepLogsFamily._dependencies,
        allTransitiveDependencies: SleepLogsFamily._allTransitiveDependencies,
        days: days,
      );

  SleepLogsProvider._internal(
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
    Stream<List<SleepLog>> Function(SleepLogsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SleepLogsProvider._internal(
        (ref) => create(ref as SleepLogsRef),
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
  AutoDisposeStreamProviderElement<List<SleepLog>> createElement() {
    return _SleepLogsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SleepLogsProvider && other.days == days;
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
mixin SleepLogsRef on AutoDisposeStreamProviderRef<List<SleepLog>> {
  /// The parameter `days` of this provider.
  int get days;
}

class _SleepLogsProviderElement
    extends AutoDisposeStreamProviderElement<List<SleepLog>>
    with SleepLogsRef {
  _SleepLogsProviderElement(super.provider);

  @override
  int get days => (origin as SleepLogsProvider).days;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
