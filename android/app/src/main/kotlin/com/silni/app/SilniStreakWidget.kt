package com.silni.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SilniStreakWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.silni_streak_widget)

            val streakText = widgetData.getString("streak_text", "\u0635\u0650\u0644\u0646\u064A \uD83D\uDD25\u0660") ?: "\u0635\u0650\u0644\u0646\u064A \uD83D\uDD25\u0660"
            val displayName = widgetData.getString("display_name", "\u0635\u0650\u0644\u0646\u064A") ?: "\u0635\u0650\u0644\u0646\u064A"

            views.setTextViewText(R.id.streak_text, streakText)
            views.setTextViewText(R.id.display_name, displayName)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
