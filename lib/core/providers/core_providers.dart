import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'database_providers.dart';

part 'core_providers.g.dart';

/// Provider for checking if setup is complete (synchronous check for router)
/// This watches the async provider and returns false until loaded
@riverpod
bool isSetupCompleteSync(ref) {
  final asyncValue = ref.watch(isSetupCompleteProvider);
  return asyncValue.valueOrNull ?? false;
}

/// Provider for current cycle position
@riverpod
Future<int> currentCyclePosition(ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getCurrentSplitIndex();
}
