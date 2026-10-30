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
        val prefData = context.getSharedPreferences("DATA", Context.MODE_PRIVATE)
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val patrimonio = widgetData.getString("widget_patrimonio", null)
            ?: prefData.getString("widget_patrimonio", null)
            ?: widgetData.getString("patrimonio", null)
            ?: prefData.getString("patrimonio", null)
            ?: "Patrimonio: € 0.00"

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.piggy_widget_layout).apply {
                setTextViewText(R.id.widget_patrimonio, patrimonio)
                setOnClickPendingIntent(R.id.widget_piggy_btn, pendingIntent)
                setOnClickPendingIntent(R.id.widget_patrimonio, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
