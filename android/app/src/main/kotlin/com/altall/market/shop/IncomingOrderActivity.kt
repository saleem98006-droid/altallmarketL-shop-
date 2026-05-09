package com.altall.market.shop

import android.app.Activity
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class IncomingOrderActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // السماح بالظهور فوق القفل + تشغيل الشاشة
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        // تصميم بسيط مؤقت (سنعدله لاحقاً إن أردت)
        val textView = TextView(this).apply {
            text = "وصل طلب جديد!"
            textSize = 28f
            setPadding(40, 200, 40, 40)
        }

        val closeBtn = Button(this).apply {
            text = "إغلاق"
            setOnClickListener { finish() }
        }

        val layout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            addView(textView)
            addView(closeBtn)
        }

        setContentView(layout)
    }
}