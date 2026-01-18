import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'database_providers.dart';

part 'core_providers.g.dart';

/// Provider for checking if setup is complete (synchronous check for router)
/// This watches the async provider and returns false until loaded
@riverpod
bool isSetupComplete(ref) {
  final asyncValue = ref.watch(isSetupCompleteProvider);
  return asyncValue.valueOrNull ?? false;
}

/// Provider for current cycle position
@riverpod
int currentCyclePosition(ref) {
  // TODO: Implement actual cycle logic
  return 0;
}
