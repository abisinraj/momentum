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
    
    // onReceive not strictly needed if we just use standard update flow, 
    // but handy for debugging. We can remove it for production cleanliness.
    override fun onReceive(context: Context, intent: android.content.Intent) {
        super.onReceive(context, intent)
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
        private const val PREFS_NAME = "com.silo.momentum.widget"

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
            // Try specific FlutterSharedPreferences first, then default
            var prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            // Debug Log: Check if file exists/contains data
            val allMap = prefs.all
            android.util.Log.d("MomentumWidget", "SHARED PREFS CONTENTS (${allMap.size} items): $allMap")

            // Fallback: If empty, try default shared preferences (sometimes used by plugins)
            if (allMap.isEmpty()) {
                 val defaultPrefs = androidx.preference.PreferenceManager.getDefaultSharedPreferences(context)
                 val defaultMap = defaultPrefs.all
                 android.util.Log.d("MomentumWidget", "DEFAULT PREFS CONTENTS (${defaultMap.size} items): $defaultMap")
                 if (defaultMap.isNotEmpty()) {
                     prefs = defaultPrefs
                 }
            }

            // Helper to get string with fallback keys
            fun getString(key: String, default: String): String {
                val val1 = prefs.getString(key, null)
                val val2 = prefs.getString("flutter.$key", null)
                android.util.Log.d("MomentumWidget", "Getting '$key': val1='$val1', val2='$val2'")
                return val1 ?: val2 ?: default
            }

            var streak = 0
            try {
                // Try reading streak (could be int or string, could have prefix or not)
                val key1 = "widget_streak"
                val key2 = "flutter.widget_streak"
                
                // Try reading as int first (most likely for direct native write if integer)
                if (prefs.contains(key1)) {
                    streak = prefs.getInt(key1, 0)
                } else if (prefs.contains(key2)) {
                    streak = prefs.getInt(key2, 0)
                } else {
                     // Try as string
                     val s1 = prefs.getString(key1, null)
                     val s2 = prefs.getString(key2, null)
                     streak = (s1 ?: s2)?.toIntOrNull() ?: 0
                }
            } catch (e: Exception) {
               android.util.Log.e("MomentumWidget", "Error reading streak: ${e.message}")
            }

            val title = getString("widget_title", "No Workout")
            val desc = getString("widget_desc", "Tap to view")
            val nextWorkout = getString("widget_next_workout", "")
            val weeklyProgress = getString("widget_cycle_progress", "--/--")
            
            android.util.Log.d("MomentumWidget", "Final Loaded Data: Streak=$streak, Title='$title'")

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
                views.setViewVisibility(R.id.widget_next_workout, android.view.View.GONE)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
