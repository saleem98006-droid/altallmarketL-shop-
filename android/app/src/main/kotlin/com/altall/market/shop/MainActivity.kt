package com.altall.market.shop

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // ...existing code...
            val channelId = "main_channel"
            val channelName = "Altall Market Notifications"

            val soundUri = Uri.parse("android.resource://" + packageName + "/raw/altall_market_notifications")

            val attributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_HIGH
            )

            channel.setSound(soundUri, attributes)

            // ...existing code...
            val urgentChannelId = "urgent_alerts"
            val urgentChannelName = "Urgent Alerts"

            val urgentAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            val urgentChannel = NotificationChannel(
                urgentChannelId,
                urgentChannelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "High priority alerts for new orders"
                enableVibration(true)
                setSound(soundUri, urgentAttributes)
                setBypassDnd(true)
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
            manager.createNotificationChannel(urgentChannel)
        }
    }
}