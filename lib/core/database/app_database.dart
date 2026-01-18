import 'package:drift/drift.dart';

import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

/// Clock types for workouts
enum ClockType {
  none,
  stopwatch,
  timer,
  alarm,
}

/// Users table - stores user profile
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get age => integer().nullable()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get goal => text().nullable()();
  IntColumn get splitDays => integer().nullable()(); // Number of days in split (e.g. 3, 4, 5)
  IntColumn get currentSplitIndex => integer().withDefault(const Constant(0))(); // Current position in split (0 to splitDays-1)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Workouts table - stores workout definitions
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get shortCode => text().withLength(min: 1, max: 1)(); // Single letter
  TextColumn get description => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()(); // URL or asset path
  IntColumn get orderIndex => integer()(); // Position in cycle
  IntColumn get clockType => intEnum<ClockType>().withDefault(const Constant(0))();
  IntColumn get timerDurationSeconds => integer().nullable()(); // For timer type
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Exercises table - stores exercises for each workout
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get sets => integer().withDefault(const Constant(3))();
  IntColumn get reps => integer().withDefault(const Constant(10))();
  IntColumn get orderIndex => integer()();
}

/// Sessions table - stores completed workout sessions
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
}

/// The main application database
@DriftDatabase(tables: [Users, Workouts, Sessions, Exercises])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.openConnection());
  
  @override
  int get schemaVersion => 3;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Schema v2 changes:
          // 1. Add splitDays to users
          await m.addColumn(users, users.splitDays);
          
          // 2. Add description and thumbnailUrl to workouts
          await m.addColumn(workouts, workouts.description);
          await m.addColumn(workouts, workouts.thumbnailUrl);
          
          // 3. Create exercises table
          await m.createTable(exercises);
        }
        if (from < 3) {
          // Schema v3 changes:
          // Add currentSplitIndex to users (for manual split progression)
          await m.addColumn(users, users.currentSplitIndex);
        }
      },
    );
  }
  
  // ===== User Operations =====
  
  /// Get the current user (there's only one)
  Future<User?> getUser() => (select(users)..limit(1)).getSingleOrNull();
  
  /// Create or update user
  Future<int> saveUser(UsersCompanion user) =>
      into(users).insertOnConflictUpdate(user);
  
  /// Check if setup is complete
  Future<bool> isSetupComplete() async {
    final user = await getUser();
    if (user == null || user.splitDays == null) return false;
    
    // Also check if they have created at least one workout
    final workouts = await getAllWorkouts();
    return workouts.isNotEmpty;
  }
  
  // ===== Exercises Operations =====
  
  /// Get exercises for a specific workout
  Future<List<Exercise>> getExercisesForWorkout(int workoutId) =>
      (select(exercises)..where((e) => e.workoutId.equals(workoutId))
                        ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
          .get();
          
  /// Watch exercises for a workout
  Stream<List<Exercise>> watchExercisesForWorkout(int workoutId) =>
      (select(exercises)..where((e) => e.workoutId.equals(workoutId))
                        ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
          .watch();
          
  /// Add an exercise
  Future<int> addExercise(ExercisesCompanion exercise) =>
      into(exercises).insert(exercise);
      
  /// Update an exercise
  Future<bool> updateExercise(ExercisesCompanion exercise) =>
      update(exercises).replace(exercise);
              
  /// Delete an exercise
  Future<int> deleteExercise(int id) =>
      (delete(exercises)..where((e) => e.id.equals(id))).go();
  
  // ===== Workout Operations =====
  
  /// Get all workouts ordered by cycle position
  Future<List<Workout>> getAllWorkouts() =>
      (select(workouts)..orderBy([(w) => OrderingTerm.asc(w.orderIndex)])).get();
  
  /// Watch all workouts (for reactive updates)
  Stream<List<Workout>> watchAllWorkouts() =>
      (select(workouts)..orderBy([(w) => OrderingTerm.asc(w.orderIndex)])).watch();
  
  /// Add a new workout
  Future<int> addWorkout(WorkoutsCompanion workout) =>
      into(workouts).insert(workout);
  
  /// Update workout order (for reordering)
  Future<void> updateWorkoutOrder(int id, int newIndex) =>
      (update(workouts)..where((w) => w.id.equals(id)))
          .write(WorkoutsCompanion(orderIndex: Value(newIndex)));
          
  /// Update workout details
  Future<bool> updateWorkout(WorkoutsCompanion workout) =>
      update(workouts).replace(workout);
  
  /// Delete a workout
  Future<int> deleteWorkout(int id) =>
      (delete(workouts)..where((w) => w.id.equals(id))).go();
  
  // ===== Session Operations =====
  
  /// Get sessions for a specific date
  Future<List<Session>> getSessionsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(sessions)
          ..where((s) => s.startedAt.isBiggerOrEqualValue(start) & 
                        s.startedAt.isSmallerThanValue(end)))
        .get();
  }
  
  /// Get today's completed workouts
  Future<List<int>> getTodayCompletedWorkoutIds() async {
    final today = DateTime.now();
    final sessionList = await getSessionsForDate(today);
    return sessionList
        .where((s) => s.completedAt != null)
        .map((s) => s.workoutId)
        .toList();
  }
  
  /// Start a new session
  Future<int> startSession(int workoutId) =>
      into(sessions).insert(SessionsCompanion(
        workoutId: Value(workoutId),
        startedAt: Value(DateTime.now()),
      ));
  
  /// Complete a session
  Future<void> completeSession(int sessionId, int durationSeconds) =>
      (update(sessions)..where((s) => s.id.equals(sessionId)))
          .write(SessionsCompanion(
            completedAt: Value(DateTime.now()),
            durationSeconds: Value(durationSeconds),
          ));
  
  // ===== Progress/History Operations =====
  
  /// Get activity for contribution grid (last N days)
  Future<Map<DateTime, String>> getActivityGrid(int days) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
    
    final result = await (select(sessions)
          ..where((s) => s.startedAt.isBiggerOrEqualValue(start) & 
                        s.completedAt.isNotNull()))
        .join([innerJoin(workouts, workouts.id.equalsExp(sessions.workoutId))])
        .get();
    
    final Map<DateTime, String> grid = {};
    for (final row in result) {
      final session = row.readTable(sessions);
      final workout = row.readTable(workouts);
      final dateKey = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );
      // Use the workout's short code for that day
      grid[dateKey] = workout.shortCode;
    }
    return grid;
  }
  
  // ===== Cycle Logic =====
  
  /// Get the current user's split index
  Future<int> getCurrentSplitIndex() async {
    final user = await getUser();
    return user?.currentSplitIndex ?? 0;
  }
  
  /// Get the workout for the current split day
  Future<Workout?> getNextWorkout() async {
    final allWorkouts = await getAllWorkouts();
    if (allWorkouts.isEmpty) return null;
    
    final currentIndex = await getCurrentSplitIndex();
    
    // Find workout matching current split index
    for (final workout in allWorkouts) {
      if (workout.orderIndex == currentIndex) {
        return workout;
      }
    }
    
    // Fallback to first workout if index is out of range
    return allWorkouts.first;
  }
  
  /// Count completed sessions for a specific workout orderIndex (current split day)
  Future<int> getCompletedCountForSplitDay(int splitIndex) async {
    final allWorkouts = await getAllWorkouts();
    
    // Find workout IDs that match this split index
    final matchingWorkoutIds = allWorkouts
        .where((w) => w.orderIndex == splitIndex)
        .map((w) => w.id)
        .toList();
    
    if (matchingWorkoutIds.isEmpty) return 0;
    
    // Count all completed sessions for these workouts
    final result = await (select(sessions)
          ..where((s) => s.workoutId.isIn(matchingWorkoutIds) & 
                        s.completedAt.isNotNull()))
        .get();
    
    return result.length;
  }
  
  /// Advance to next split day if 2+ workouts completed for current day
  /// Returns true if advanced, false otherwise
  Future<bool> advanceSplit() async {
    final user = await getUser();
    if (user == null) return false;
    
    final currentIndex = user.currentSplitIndex;
    final splitDays = user.splitDays ?? 7;
    
    final completedCount = await getCompletedCountForSplitDay(currentIndex);
    
    if (completedCount >= 2) {
      // Advance to next day (with wrap-around)
      final nextIndex = (currentIndex + 1) % splitDays;
      
      await (update(users)..where((u) => u.id.equals(user.id)))
          .write(UsersCompanion(currentSplitIndex: Value(nextIndex)));
      
      return true;
    }
    
    return false;
  }
  
  /// Update the user's current split index manually
  Future<void> setSplitIndex(int index) async {
    final user = await getUser();
    if (user == null) return;
    
    await (update(users)..where((u) => u.id.equals(user.id)))
        .write(UsersCompanion(currentSplitIndex: Value(index)));
  }
  
  // ===== Stats & Insights =====
  
  /// Get stats for the last 7 days (including today)
  /// Returns { 'duration': totalSeconds, 'calories': totalKcal, 'workouts': count }
  Future<Map<String, int>> getWeeklyStats() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    
    // Get sessions from last 7 days that are completed
    final recentSessions = await (select(sessions)
          ..where((s) => s.startedAt.isBiggerOrEqualValue(start) & 
                        s.completedAt.isNotNull()))
        .get();
        
    int totalDuration = 0;
    int workoutCount = recentSessions.length;
    
    // Get user weight for calorie calc
    final user = await getUser();
    final weight = user?.weightKg ?? 70.0; // Fallback to 70kg
    const double met = 4.5; // Moderate effort
    
    for (final session in recentSessions) {
      totalDuration += session.durationSeconds ?? 0;
    }
    
    // Calorie formula: MET * Weight(kg) * Duration(hr)
    final durationHours = totalDuration / 3600.0;
    final totalCalories = (met * weight * durationHours).round();
    
    return {
      'duration': totalDuration,
      'calories': totalCalories,
      'workouts': workoutCount,
    };
  }
  
  /// Get weekly insight comparing this week (last 7 days) vs previous week
  Future<String> getWeeklyInsight() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // This week: [Today-6, Today]
    final thisWeekStart = today.subtract(const Duration(days: 6));
    
    // Last week: [Today-13, Today-7]
    final lastWeekStart = today.subtract(const Duration(days: 13));
    final lastWeekEnd = today.subtract(const Duration(days: 7));
    
    // Helper to count sessions in range
    Future<int> countSessions(DateTime start, DateTime end) async {
       // inclusive start, inclusive end (conceptually)
       // drift queries usually need careful bounds. 
       // strict comparison: start <= date < end+1day
       final effectiveEnd = end.add(const Duration(days: 1));
       
       final result = await (select(sessions)
          ..where((s) => s.startedAt.isBiggerOrEqualValue(start) & 
                        s.startedAt.isSmallerThanValue(effectiveEnd) &
                        s.completedAt.isNotNull()))
        .get();
        return result.length;
    }
    
    final thisWeekCount = await countSessions(thisWeekStart, today);
    final lastWeekCount = await countSessions(lastWeekStart, lastWeekEnd);
    
    if (thisWeekCount == 0) {
      if (lastWeekCount > 0) {
        return "You've been quiet this week. Time to get back to it!";
      }
      return "Start your first workout to build momentum!";
    }
    
    if (thisWeekCount > lastWeekCount) {
      final diff = thisWeekCount - lastWeekCount;
      return "You're crushing it! $diff more workouts than last week. Keep building that momentum.";
    } else if (thisWeekCount == lastWeekCount) {
      return "Consistent effort! You're matching your pace from last week.";
    } else {
      return "You're active, but a little behind last week's pace. Push for one more!";
    }
  }
}

