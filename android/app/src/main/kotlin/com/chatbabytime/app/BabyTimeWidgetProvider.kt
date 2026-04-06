package com.chatbabytime.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 아기톡톡 홈 위젯 프로바이더
 *
 * 기능:
 * 1. 아기 이름 + 오늘 요약 표시
 * 2. 다음 루틴 예정 시각 배지
 * 3. 수유/기저귀/수면 퀵 액션 버튼 (앱 실행 없이 즉시 기록)
 */
class BabyTimeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.baby_time_widget).apply {

                // ── 전체 위젯 탭 → 앱 실행 ──
                val openApp = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("chatbabytime://home"),
                )
                setOnClickPendingIntent(R.id.widget_root, openApp)

                // ── 데이터 바인딩 ──
                val name = widgetData.getString("baby_name", null) ?: "아기톡톡"
                val summary = widgetData.getString("summary_line", null)
                    ?: "앱에서 기록하면 여기에 오늘 요약이 표시돼요"
                val detail = widgetData.getString("detail_line", null)
                    ?: "탭하면 앱이 열려요"
                val nextRoutine = widgetData.getString("next_routine_line", null)
                    ?: ""

                setTextViewText(R.id.widget_baby_name, name)
                setTextViewText(R.id.widget_summary, summary)
                setTextViewText(R.id.widget_detail, detail)
                setTextViewText(R.id.widget_next_routine, nextRoutine)

                // 다음 루틴이 없으면 배지 숨김
                if (nextRoutine.isEmpty()) {
                    setViewVisibility(R.id.widget_next_routine, android.view.View.GONE)
                } else {
                    setViewVisibility(R.id.widget_next_routine, android.view.View.VISIBLE)
                }

                // ── 퀵 액션 버튼 PendingIntent ──
                setOnClickPendingIntent(
                    R.id.btn_quick_feeding,
                    createQuickActionPendingIntent(
                        context, QuickRecordReceiver.ACTION_QUICK_FEEDING, 1001
                    )
                )
                setOnClickPendingIntent(
                    R.id.btn_quick_diaper,
                    createQuickActionPendingIntent(
                        context, QuickRecordReceiver.ACTION_QUICK_DIAPER, 1002
                    )
                )
                setOnClickPendingIntent(
                    R.id.btn_quick_sleep,
                    createQuickActionPendingIntent(
                        context, QuickRecordReceiver.ACTION_QUICK_SLEEP, 1003
                    )
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun createQuickActionPendingIntent(
        context: Context,
        action: String,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, QuickRecordReceiver::class.java).apply {
            this.action = action
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
