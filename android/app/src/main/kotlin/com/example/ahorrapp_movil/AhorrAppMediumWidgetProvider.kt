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
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.medium_widget).apply {
                val balance = widgetData.getString("balance", "$0.00")
                val ingresos = widgetData.getString("ingresos", "$0")
                val gastos = widgetData.getString("gastos", "$0")
                val porcentaje = widgetData.getInt("porcentaje", 0)
                val fecha = widgetData.getString("fecha", "Agosto 2026")

                setTextViewText(R.id.widget_balance, balance)
                setTextViewText(R.id.widget_ingresos, ingresos)
                setTextViewText(R.id.widget_gastos, gastos)
                setTextViewText(R.id.widget_porcentaje, "$porcentaje%")
                setTextViewText(R.id.widget_date, fecha)
                setProgressBar(R.id.widget_progress_bar, 100, porcentaje, false)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
