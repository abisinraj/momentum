
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momentum/core/services/ai_insights_service.dart';
import 'package:momentum/core/providers/database_providers.dart';
import 'package:momentum/core/services/settings_service.dart';



/// Provider for the AI Insights Service
final aiInsightsServiceProvider = Provider<AIInsightsService>((ref) {
  return AIInsightsService();
});

/// Future provider to fetch the daily insight
/// Caches the result to avoid unnecessary API calls on rebuilds
final dailyInsightProvider = FutureProvider.autoDispose<AIInsightResponse>((ref) async {
  // refresh every 4 hours or on app restart
  ref.keepAlive();
  
  // Watch user data
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
     return AIInsightResponse(
       text: "Welcome to Momentum! Setup your profile to get started.",
       mood: "hero",
       type: "general",
     );
  }
  
  // Watch database to get history
  final db = ref.watch(appDatabaseProvider);
  
  // 1. History (Recent 5 sessions)
  final history = await db.getRecentSessionsWithDetails(limit: 5);
  if (history.isNotEmpty) {
    final latestSession = history.first;
    final sessionId = (latestSession['session'] as dynamic).id;
    final exerciseDetails = await db.getSessionExerciseDetails(sessionId);
    latestSession['exercises'] = exerciseDetails;
  }
  
  // 2. Trends (Last 30 days)
  final trend = await db.getVolumeTrend(30);
  
  // 3. Milestones (All-time stats)
  final stats = await db.getAllTimeStats();
  
  // 4. Diet Gap (Hours since last meal)
  final dietGap = await db.getHoursSinceLastFoodLog();

  // Get API Key and Model
  final apiKey = ref.watch(geminiApiKeyProvider).valueOrNull;
  final preferredModel = ref.watch(geminiModelProvider).valueOrNull;

  // Generate insight
  return ref.watch(aiInsightsServiceProvider).getDailyInsight(
    user: user,
    recentSessions: history,
    allTimeStats: stats,
    volumeTrend: trend,
    hoursSinceLastMeal: dietGap,
    apiKey: apiKey,
    preferredModel: preferredModel,
  );
});
