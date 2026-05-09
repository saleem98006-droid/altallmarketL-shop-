package com.altall.market.shop

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.view.LayoutInflater
import android.view.WindowManager
import android.view.View
import android.os.Build
import android.provider.Settings
import android.widget.Button
import android.widget.TextView
import android.graphics.PixelFormat
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import androidx.core.app.NotificationCompat

class OrderOverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private val CHANNEL_ID = "order_overlay_channel"

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Settings.canDrawOverlays(this)) {
            showOverlay(intent)
        }
        return START_NOT_STICKY
    }

    private fun showOverlay(intent: Intent?) {
        if (overlayView != null) return
        val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
        overlayView = inflater.inflate(R.layout.layout_order_overlay, null)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        windowManager?.addView(overlayView, params)

        val openAppButton = overlayView?.findViewById<Button>(R.id.btnOpenApp)
        openAppButton?.setOnClickListener {
            // يمكنك هنا فتح التطبيق أو تنفيذ أي إجراء آخر
            removeOverlay()
            stopSelf()
        }

        val tvBody = overlayView?.findViewById<TextView>(R.id.tvBody)
        val orderInfo = intent?.getStringExtra("order_info") ?: "طلب جديد!"
        tvBody?.text = orderInfo

        // بدء الخدمة كـ foreground
        val notification = buildNotification(orderInfo)
        startForeground(1001, notification)
    }

    private fun removeOverlay() {
        if (overlayView != null) {
            windowManager?.removeView(overlayView)
            overlayView = null
        }
    }

    private fun buildNotification(orderInfo: String): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("طلب جديد")
            .setContentText(orderInfo)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "تنبيهات الطلبات المنبثقة",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        removeOverlay()
        super.onDestroy()
    }
}