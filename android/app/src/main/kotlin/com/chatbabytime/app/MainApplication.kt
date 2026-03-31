package com.chatbabytime.app

import android.app.Application
import android.content.Context
import androidx.multidex.MultiDex

/**
 * 멀티덱스 및 플러그인 클래스 로딩 순서 이슈 완화.
 * flutter_local_notifications의 LongUtils 등이 런타임에 누락되는 경우가 있어
 * attachBaseContext에서 MultiDex.install을 호출합니다.
 */
class MainApplication : Application() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
}
