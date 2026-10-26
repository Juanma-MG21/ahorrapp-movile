package com.example.ahorrapp_movil

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class AhorrAppMediumWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val summary = FinancialWidgetSnapshot.read(widgetData)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.medium_widget).apply {
                setTextViewText(R.id.widget_balance, summary.balance)
                setTextViewText(R.id.widget_ingresos, summary.ingresos)
                setTextViewText(R.id.widget_gastos, summary.gastos)
                setTextViewText(R.id.widget_porcentaje, summary.porcentaje)
                setTextViewText(R.id.widget_date, summary.fecha)
                setProgressBar(R.id.widget_progress_bar, 100, summary.progreso, false)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
