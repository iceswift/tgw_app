package com.thaigoldview.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import android.graphics.Color
import com.thaigoldview.app.R

class GoldWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                val widgetData = HomeWidgetPlugin.getData(context)
                
                // Fetch Data (New Complete Set)
                val bullionBuy = widgetData.getString("bullion_buy", "--")
                val bullionSell = widgetData.getString("bullion_sell", "--")
                val ornamentBuy = widgetData.getString("ornament_buy", "--")
                val ornamentSell = widgetData.getString("ornament_sell", "--")
                
                val change = widgetData.getString("change", "--")
                val date = widgetData.getString("date", "--:--")

                val views = RemoteViews(context.packageName, R.layout.widget_layout)

                // Bind Data
                views.setTextViewText(R.id.widget_bullion_buy, bullionBuy)
                views.setTextViewText(R.id.widget_bullion_sell, bullionSell)
                views.setTextViewText(R.id.widget_ornament_buy, ornamentBuy)
                views.setTextViewText(R.id.widget_ornament_sell, ornamentSell)
                
                views.setTextViewText(R.id.widget_date, date)
                
                // Change logic
                views.setTextViewText(R.id.widget_change, change)
                if (change != "--") {
                    val cleanChange = change?.replace("+", "")?.replace(",", "")?.toDoubleOrNull() ?: 0.0
                    if (cleanChange > 0) {
                        views.setTextColor(R.id.widget_change, Color.parseColor("#4CAF50"))
                    } else if (cleanChange < 0) {
                        views.setTextColor(R.id.widget_change, Color.parseColor("#F44336"))
                    } else {
                         views.setTextColor(R.id.widget_change, Color.parseColor("#FFFFFF"))
                    }
                } else {
                     views.setTextColor(R.id.widget_change, Color.parseColor("#888888"))
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
