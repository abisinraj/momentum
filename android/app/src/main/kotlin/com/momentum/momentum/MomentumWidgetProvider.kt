package com.momentum.momentum

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.graphics.Color
import android.content.SharedPreferences

/**
 * Momentum Home Screen Widget
 * 
 * Displays the last 30 days of workout activity as a contribution grid.
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
        // Widget first added to home screen
    }

    override fun onDisabled(context: Context) {
        // Last widget instance removed
    }

    companion object {
        private const val PREFS_NAME = "MomentumWidgetPrefs"
        private const val ACTIVE_COLOR = "#5C6BC0" // Deep Indigo
        private const val INACTIVE_COLOR = "#E0E0E0"
        
        private val DAY_IDS = arrayOf(
            R.id.day1, R.id.day2, R.id.day3, R.id.day4, R.id.day5, R.id.day6,
            R.id.day7, R.id.day8, R.id.day9, R.id.day10, R.id.day11, R.id.day12,
            R.id.day13, R.id.day14, R.id.day15, R.id.day16, R.id.day17, R.id.day18,
            R.id.day19, R.id.day20, R.id.day21, R.id.day22, R.id.day23, R.id.day24,
            R.id.day25, R.id.day26, R.id.day27, R.id.day28, R.id.day29, R.id.day30
        )

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.momentum_widget)
            
            // Get activity data from SharedPreferences
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val activityData = prefs.getString("activity_data", "") ?: ""
            
            // Parse activity data (format: "1,0,1,1,0,..." for 30 days)
            val days = if (activityData.isNotEmpty()) {
                activityData.split(",").map { it.trim() == "1" }
            } else {
                List(30) { false }
            }
            
            // Update each day cell
            var activeDays = 0
            for ((index, dayId) in DAY_IDS.withIndex()) {
                val isActive = days.getOrElse(index) { false }
                if (isActive) {
                    activeDays++
                    views.setInt(dayId, "setBackgroundColor", Color.parseColor(ACTIVE_COLOR))
                    views.setTextViewText(dayId, "✓")
                } else {
                    views.setInt(dayId, "setBackgroundColor", Color.parseColor(INACTIVE_COLOR))
                    views.setTextViewText(dayId, "")
                }
            }
            
            // Update subtitle with active days count
            val subtitle = when (activeDays) {
                0 -> "Start your momentum!"
                1 -> "1 active day"
                else -> "$activeDays active days"
            }
            views.setTextViewText(R.id.widget_subtitle, subtitle)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
