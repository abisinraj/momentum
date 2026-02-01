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
        private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
        
        // Keys
        private const val KEY_STREAK = "widget_streak"
        private const val KEY_TITLE = "widget_title"
        private const val KEY_DESC = "widget_desc"
        private const val KEY_CYCLE = "widget_cycle_progress"
        private const val KEY_NEXT = "widget_next_workout"
        private const val KEY_THEME = "widget_theme"

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
                 // Try FlutterSharedPreferences (default for Flutter plugins)
                 val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
                 val flutterMap = flutterPrefs.all
                 android.util.Log.d("MomentumWidget", "FLUTTER PREFS CONTENTS (${flutterMap.size} items): $flutterMap")
                 
                 if (flutterMap.isNotEmpty()) {
                     prefs = flutterPrefs
                 } else {
                     val defaultPrefs = androidx.preference.PreferenceManager.getDefaultSharedPreferences(context)
                     val defaultMap = defaultPrefs.all
                     android.util.Log.d("MomentumWidget", "DEFAULT PREFS CONTENTS (${defaultMap.size} items): $defaultMap")
                     if (defaultMap.isNotEmpty()) {
                         prefs = defaultPrefs
                     }
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
                val key1 = KEY_STREAK
                val key2 = "flutter.$KEY_STREAK"
                
                // Safely read streak (Flutter may write Integer as Long on Android)
                // We attempt to get the object and check type manually or try multiple getters.
                
                fun getIntSafe(k: String): Int {
                    if (!prefs.contains(k)) return -1 // Not found signal
                    
                    try {
                        return prefs.getInt(k, 0)
                    } catch (e: ClassCastException) {
                        try {
                            return prefs.getLong(k, 0L).toInt()
                        } catch (e2: Exception) {
                            try {
                                return prefs.getString(k, "0")?.toIntOrNull() ?: 0
                            } catch (e3: Exception) {
                                return 0
                            }
                        }
                    }
                }

                val v1 = getIntSafe(key1)
                val v2 = getIntSafe(key2)
                
                if (v1 != -1) streak = v1
                else if (v2 != -1) streak = v2
                else streak = 0

            } catch (e: Exception) {
               android.util.Log.e("MomentumWidget", "Error reading streak: ${e.message}")
            }

            val title = getString(KEY_TITLE, "No Workout")
            val desc = getString(KEY_DESC, "Tap to view")
            val nextWorkout = getString(KEY_NEXT, "")
            val weeklyProgress = getString(KEY_CYCLE, "--/--")
            val themeKey = getString(KEY_THEME, "classic")
            
            android.util.Log.d("MomentumWidget", "Final Loaded Data: Streak=$streak, Title='$title', Theme='$themeKey'")

            // Apply Theme
            if (themeKey == "liquid_glass") {
                // Ghost Theme: Remove background
                views.setInt(R.id.widget_root, "setBackgroundResource", 0)
                views.setInt(R.id.widget_root, "setBackgroundColor", Color.TRANSPARENT)
            } else {
                // Classic Theme: Restore background
                views.setInt(R.id.widget_root, "setBackgroundResource", R.drawable.widget_background)
            }

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
