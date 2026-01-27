package com.silo.momentum

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.graphics.Color
import android.content.SharedPreferences

/**
 * Momentum Home Screen Widget
 * 
 * Displays current streak and workout status.
 * Data is synced from Flutter via SharedPreferences using home_widget package.
 */
class MomentumWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: android.content.Intent) {
        android.util.Log.d("MomentumWidget", "onReceive: ${intent.action}")
        super.onReceive(context, intent)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        android.util.Log.d("MomentumWidget", "onUpdate called for ${appWidgetIds.size} widgets")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Widget first added to home screen - force immediate update
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = android.content.ComponentName(context, MomentumWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
        onUpdate(context, appWidgetManager, appWidgetIds)
    }

    override fun onDisabled(context: Context) {
        // Last widget instance removed
    }

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.momentum_widget)
            
            // PendingIntent to launch app on click
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pendingIntent = android.app.PendingIntent.getActivity(
                context, 
                0, 
                intent, 
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_app_name, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_workout_name, pendingIntent)
            
            // Get data from SharedPreferences
            // home_widget specific: The file name is "FlutterSharedPreferences"
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            var streak = 0
            try {
                // Try reading as straight String first (new way)
                val streakStr = prefs.getString("flutter.widget_streak", null)
                android.util.Log.d("MomentumWidget", "Raw streak string: $streakStr")
                
                if (streakStr != null) {
                    streak = streakStr.toIntOrNull() ?: 0
                } else {
                    // Fallback to Int (old way) - standard SharedPreferences might store as Int
                    // BUT Flutter's SharedPreferences implementation prefixes keys with "flutter." !!!
                    // AND it often stores everything as String if not typed strictly.
                    // Let's try getting it as int with the prefix
                    streak = prefs.getInt("flutter.widget_streak", 0)
                }
            } catch (e: Exception) {
                android.util.Log.e("MomentumWidget", "Error reading streak: ${e.message}")
            }

            // Note: Keys in Flutter SharedPreferences are prefixed with "flutter."
            // We need to use "flutter.widget_title" instead of "widget_title"
            val title = prefs.getString("flutter.widget_title", "No Workout") ?: "No Workout"
            val desc = prefs.getString("flutter.widget_desc", "Tap to view") ?: "Tap to view"
            val nextWorkout = prefs.getString("flutter.widget_next_workout", "") ?: ""
            val weeklyProgress = prefs.getString("flutter.widget_cycle_progress", "--/--") ?: "--/--"
            
            android.util.Log.d("MomentumWidget", "Loaded: Streak=$streak, Title='$title', Desc='$desc', Progress='$weeklyProgress'")

            // Update views
            views.setTextViewText(R.id.widget_streak, "\uD83D\uDD25 $streak") // Fire emoji
            views.setTextViewText(R.id.widget_workout_name, title)
            views.setTextViewText(R.id.widget_workout_desc, desc)
            
            // Cycle Progress
            views.setTextViewText(R.id.widget_weekly_progress, "Day $weeklyProgress")
            views.setViewVisibility(R.id.widget_weekly_progress, android.view.View.VISIBLE)

            if (nextWorkout.isNotEmpty()) {
                views.setViewVisibility(R.id.widget_next_workout, android.view.View.VISIBLE)
                views.setTextViewText(R.id.widget_next_workout, "Next: $nextWorkout")
            } else {
                // If no next workout, we can hide it or show something else
                views.setViewVisibility(R.id.widget_next_workout, android.view.View.GONE)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
