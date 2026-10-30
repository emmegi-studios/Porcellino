package com.porcellino.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.piggy_widget_layout).apply {
                val patrimonio = widgetData.getString("widget_patrimonio", "Patrimonio: € 0.00")
                setTextViewText(R.id.widget_patrimonio, patrimonio)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
