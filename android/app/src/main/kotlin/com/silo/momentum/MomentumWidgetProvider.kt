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

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
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
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            var streak = 0
            try {
                // Try reading as straight String first (new way)
                val streakStr = prefs.getString("widget_streak", null)
                if (streakStr != null) {
                    streak = streakStr.toIntOrNull() ?: 0
                } else {
                    // Fallback to Int (old way)
                    streak = prefs.getInt("widget_streak", 0)
                }
            } catch (e: Exception) {
                // If cast fails (e.g. explicitly stored as Long?), try Long
                try {
                   streak = prefs.getLong("widget_streak", 0L).toInt()
                } catch (e2: Exception) {
                   streak = 0
                }
            }
            val title = prefs.getString("widget_title", "No Workout") ?: "No Workout"
            val desc = prefs.getString("widget_desc", "Tap to view") ?: "Tap to view"
            val nextWorkout = prefs.getString("widget_next_workout", "") ?: ""
            val weeklyProgress = prefs.getString("widget_cycle_progress", "--/--") ?: "--/--"
            
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
