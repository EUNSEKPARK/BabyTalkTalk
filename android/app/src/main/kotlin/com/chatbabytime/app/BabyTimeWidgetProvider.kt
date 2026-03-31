package com.chatbabytime.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class BabyTimeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.baby_time_widget).apply {
                val openApp = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("chatbabytime://home"),
                )
                setOnClickPendingIntent(R.id.widget_root, openApp)

                val name = widgetData.getString("baby_name", null) ?: "ChatBabyTime"
                val summary = widgetData.getString("summary_line", null)
                    ?: "앱에서 기록하면 여기에 오늘 요약이 표시돼요"
                val detail = widgetData.getString("detail_line", null)
                    ?: "탭하면 앱이 열려요"

                setTextViewText(R.id.widget_baby_name, name)
                setTextViewText(R.id.widget_summary, summary)
                setTextViewText(R.id.widget_detail, detail)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
