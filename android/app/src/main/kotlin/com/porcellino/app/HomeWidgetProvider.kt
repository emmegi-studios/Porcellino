package com.porcellino.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        val prefs = context.getSharedPreferences("DATA", Context.MODE_PRIVATE)
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = if (launchIntent != null) {
            PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else null

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.piggy_widget_layout).apply {
                val patrimonio = prefs.getString("widget_patrimonio", "Patrimonio: € 0.00")
                setTextViewText(R.id.widget_patrimonio, patrimonio)

                if (pendingIntent != null) {
                    setOnClickPendingIntent(R.id.widget_piggy_btn, pendingIntent)
                    setOnClickPendingIntent(R.id.widget_patrimonio, pendingIntent)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
