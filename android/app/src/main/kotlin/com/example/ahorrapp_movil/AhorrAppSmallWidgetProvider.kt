package com.example.ahorrapp_movil

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class AhorrAppSmallWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val summary = FinancialWidgetSnapshot.read(widgetData)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.small_widget).apply {
                setTextViewText(R.id.widget_balance, summary.balance)
                setTextViewText(R.id.widget_ingresos, "Ingresos ${summary.ingresos}")
                setTextViewText(R.id.widget_gastos, "Gastos ${summary.gastos}")
                setTextViewText(R.id.widget_porcentaje, summary.porcentaje)
                setTextViewText(R.id.widget_date, summary.fecha)

                val pendingIntentGasto = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("ahorrapp://gasto")
                )
                setOnClickPendingIntent(R.id.btn_gasto, pendingIntentGasto)

                val pendingIntentIngreso = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("ahorrapp://ingreso")
                )
                setOnClickPendingIntent(R.id.btn_ingreso, pendingIntentIngreso)

                val pendingIntentRoot = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntentRoot)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
