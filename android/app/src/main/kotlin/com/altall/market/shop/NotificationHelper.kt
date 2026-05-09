package com.altall.market.shop

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person

object NotificationHelper {

    private const val CHANNEL_ID = "urgent_alerts"

    fun showFullScreenNotification(context: Context, title: String, body: String) {

        // شاشة الطلب
        val fullScreenIntent = Intent(context, IncomingOrderActivity::class.java)
        fullScreenIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            0,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // زر قبول (نفس الشاشة)
        val answerIntent = PendingIntent.getActivity(
            context,
            1,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // زر رفض (يغلق الإشعار فقط)
        val declineIntent = PendingIntent.getActivity(
            context,
            2,
            Intent(), // لا يفتح شيء
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val caller = Person.Builder()
            .setName("طلب جديد")
            .build()

        val callStyle = NotificationCompat.CallStyle.forIncomingCall(
            caller,
            answerIntent,
            declineIntent
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setStyle(callStyle)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setAutoCancel(true)

        with(NotificationManagerCompat.from(context)) {
            notify(9999, builder.build())
        }
    }
}