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
    
    await db.saveUser(UsersCompanion.insert(
      name: name,
      age: age != null ? Value(age) : const Value.absent(),
      heightCm: heightCm != null ? Value(heightCm) : const Value.absent(),
      weightKg: weightKg != null ? Value(weightKg) : const Value.absent(),
      goal: goal != null ? Value(goal) : const Value.absent(),
    ));
    
    // Invalidate setup check
    ref.invalidate(isSetupCompleteProvider);
    ref.invalidate(currentUserProvider);
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
}
