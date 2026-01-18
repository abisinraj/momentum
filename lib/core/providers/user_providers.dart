import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import 'database_providers.dart';

part 'user_providers.g.dart';

/// Notifier for managing user setup
@riverpod
class UserSetup extends _$UserSetup {
  @override
  FutureOr<void> build() {}
  
  /// Complete the user setup
  Future<void> completeSetup({
    required String name,
    int? age,
    double? heightCm,
    double? weightKg,
    String? goal,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final user = await db.getUser();
    
    if (user != null) {
      await db.saveUser(user.toCompanion(true).copyWith(
        name: Value(name),
        age: age != null ? Value(age) : const Value.absent(),
        heightCm: heightCm != null ? Value(heightCm) : const Value.absent(),
        weightKg: weightKg != null ? Value(weightKg) : const Value.absent(),
        goal: goal != null ? Value(goal) : const Value.absent(),
      ));
    } else {
      await db.saveUser(UsersCompanion.insert(
        name: name,
        age: age != null ? Value(age) : const Value.absent(),
        heightCm: heightCm != null ? Value(heightCm) : const Value.absent(),
        weightKg: weightKg != null ? Value(weightKg) : const Value.absent(),
        goal: goal != null ? Value(goal) : const Value.absent(),
      ));
    }
    
    // Invalidate user provider to update UI name etc
    ref.invalidate(currentUserProvider);
    
    // NOTE: We do NOT invalidate isSetupCompleteProvider here.
    // We want the user to stay in the setup flow until they finish creating workouts.
    // The invalidation happens in CreateWorkoutScreen.
  }
  
  /// Update user profile
  Future<void> updateProfile({
    String? name,
    int? age,
    double? heightCm,
    double? weightKg,
    String? goal,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final currentUser = await db.getUser();
    
    if (currentUser == null) return;
    
    await db.saveUser(UsersCompanion(
      id: Value(currentUser.id),
      name: name != null ? Value(name) : Value(currentUser.name),
      age: age != null ? Value(age) : Value(currentUser.age),
      heightCm: heightCm != null ? Value(heightCm) : Value(currentUser.heightCm),
      weightKg: weightKg != null ? Value(weightKg) : Value(currentUser.weightKg),
      goal: goal != null ? Value(goal) : Value(currentUser.goal),
    ));
    
    ref.invalidate(currentUserProvider);
  }
  
  /// Update split days
  Future<void> setSplitDays(int days) async {
    final db = ref.read(appDatabaseProvider);
    final currentUser = await db.getUser();
    
    if (currentUser == null) return;
    
    await db.saveUser(currentUser.toCompanion(true).copyWith(
      splitDays: Value(days),
    ));
    
    ref.invalidate(currentUserProvider);
    // Note: We don't invalidate isSetupComplete yet as we want to keep them in the wizard
    // until they finish creating workouts
  }
}
