package com.chatbabytime.app

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * 위젯 퀵 액션 BroadcastReceiver
 *
 * 앱을 실행하지 않고 위젯 버튼 탭으로 즉시 기록을 생성합니다.
 * 기록은 SharedPreferences의 "pending_widget_records" 큐에 JSON으로 저장되고,
 * Flutter 앱이 다음에 열릴 때 RecordService가 Hive + Firestore로 동기화합니다.
 *
 * 지원 액션:
 * - ACTION_QUICK_FEEDING: 분유 160ml 즉시 기록
 * - ACTION_QUICK_DIAPER: 기저귀(소변) 즉시 기록
 * - ACTION_QUICK_SLEEP: 수면(잠듦) 즉시 기록
 */
class QuickRecordReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "QuickRecordReceiver"
        const val ACTION_QUICK_FEEDING = "com.chatbabytime.app.ACTION_QUICK_FEEDING"
        const val ACTION_QUICK_DIAPER = "com.chatbabytime.app.ACTION_QUICK_DIAPER"
        const val ACTION_QUICK_SLEEP = "com.chatbabytime.app.ACTION_QUICK_SLEEP"

        // SharedPreferences 키 (home_widget 플러그인이 사용하는 것과 동일)
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val KEY_PENDING_RECORDS = "pending_widget_records"

        // RecordCategory 인덱스 (baby_record.dart의 enum과 일치)
        private const val CAT_FEEDING = 0
        private const val CAT_SLEEP = 1
        private const val CAT_DIAPER = 2

        // FeedingType 인덱스
        private const val FEEDING_FORMULA = 1

        // DiaperType 인덱스
        private const val DIAPER_PEE = 0

        // SleepStatus 인덱스
        private const val SLEEP_START = 0
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "onReceive: ${intent.action}")

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        when (intent.action) {
            ACTION_QUICK_FEEDING -> enqueueRecord(prefs, createFeedingRecord())
            ACTION_QUICK_DIAPER -> enqueueRecord(prefs, createDiaperRecord())
            ACTION_QUICK_SLEEP -> enqueueRecord(prefs, createSleepRecord())
            else -> return
        }

        // 위젯 요약 업데이트 (카운트 증가)
        updateWidgetCounters(context, prefs, intent.action ?: "")

        // 위젯 갱신 트리거
        val widgetManager = AppWidgetManager.getInstance(context)
        val widgetComponent = ComponentName(context, BabyTimeWidgetProvider::class.java)
        val widgetIds = widgetManager.getAppWidgetIds(widgetComponent)
        val updateIntent = Intent(context, BabyTimeWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
        }
        context.sendBroadcast(updateIntent)

        Log.d(TAG, "퀵 기록 큐잉 완료: ${intent.action}")
    }

    private fun createFeedingRecord(): JSONObject {
        return JSONObject().apply {
            put("id", UUID.randomUUID().toString())
            put("category", CAT_FEEDING)
            put("timestamp", System.currentTimeMillis())
            put("feedingType", FEEDING_FORMULA)
            put("amountMl", 160)
            put("inputSource", "widget")
            put("memo", "위젯에서 빠른 기록")
        }
    }

    private fun createDiaperRecord(): JSONObject {
        return JSONObject().apply {
            put("id", UUID.randomUUID().toString())
            put("category", CAT_DIAPER)
            put("timestamp", System.currentTimeMillis())
            put("diaperType", DIAPER_PEE)
            put("inputSource", "widget")
            put("memo", "위젯에서 빠른 기록")
        }
    }

    private fun createSleepRecord(): JSONObject {
        return JSONObject().apply {
            put("id", UUID.randomUUID().toString())
            put("category", CAT_SLEEP)
            put("timestamp", System.currentTimeMillis())
            put("sleepStatus", SLEEP_START)
            put("inputSource", "widget")
            put("memo", "위젯에서 빠른 기록")
        }
    }

    private fun enqueueRecord(prefs: SharedPreferences, record: JSONObject) {
        val existing = prefs.getString(KEY_PENDING_RECORDS, null)
        val array = if (existing != null) {
            try { JSONArray(existing) } catch (e: Exception) { JSONArray() }
        } else {
            JSONArray()
        }
        array.put(record)
        prefs.edit().putString(KEY_PENDING_RECORDS, array.toString()).apply()
    }

    /**
     * 위젯의 오늘 요약 카운터를 즉시 반영 (앱 동기화 전 UI 피드백)
     */
    private fun updateWidgetCounters(context: Context, prefs: SharedPreferences, action: String) {
        val currentSummary = prefs.getString("summary_line", null) ?: return

        // "오늘 수유 3 · 기저귀 2 · 수면 1" 형태 파싱
        val regex = Regex("""수유\s+(\d+)\s+·\s+기저귀\s+(\d+)\s+·\s+수면\s+(\d+)""")
        val match = regex.find(currentSummary) ?: return

        var feeding = match.groupValues[1].toIntOrNull() ?: 0
        var diaper = match.groupValues[2].toIntOrNull() ?: 0
        var sleep = match.groupValues[3].toIntOrNull() ?: 0

        when (action) {
            ACTION_QUICK_FEEDING -> feeding++
            ACTION_QUICK_DIAPER -> diaper++
            ACTION_QUICK_SLEEP -> sleep++
        }

        val newSummary = "오늘 수유 $feeding · 기저귀 $diaper · 수면 $sleep"
        prefs.edit().putString("summary_line", newSummary).apply()

        // detail_line도 업데이트
        when (action) {
            ACTION_QUICK_FEEDING -> prefs.edit().putString("detail_line", "방금 수유 기록됨 (위젯)").apply()
            ACTION_QUICK_DIAPER -> prefs.edit().putString("detail_line", "방금 기저귀 기록됨 (위젯)").apply()
            ACTION_QUICK_SLEEP -> prefs.edit().putString("detail_line", "방금 수면 기록됨 (위젯)").apply()
        }
    }
}
