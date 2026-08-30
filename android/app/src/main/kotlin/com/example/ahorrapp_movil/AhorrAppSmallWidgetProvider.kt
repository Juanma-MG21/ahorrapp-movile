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
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.small_widget).apply {
                val balance = widgetData.getString("balance", "$0.00")
                setTextViewText(R.id.widget_balance, balance)

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
