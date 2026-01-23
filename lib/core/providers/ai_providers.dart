
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momentum/core/services/ai_insights_service.dart';
import 'package:momentum/core/providers/database_providers.dart';


/// Provider for the AI Insights Service
final aiInsightsServiceProvider = Provider<AIInsightsService>((ref) {
  return AIInsightsService();
});

/// Future provider to fetch the daily insight
/// Caches the result to avoid unnecessary API calls on rebuilds
final dailyInsightProvider = FutureProvider<String>((ref) async {
  // Watch user data
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return "Welcome to Momentum! Setup your profile to get started.";
  
  // Watch database to get history
  final db = ref.watch(appDatabaseProvider);
  // Get recent 5 sessions for context
  final history = await db.getRecentSessionsWithDetails(limit: 5);
  
  // Get service
  final service = ref.watch(aiInsightsServiceProvider);
  
  // Generate insight
  return service.getDailyInsight(user, history);
});
