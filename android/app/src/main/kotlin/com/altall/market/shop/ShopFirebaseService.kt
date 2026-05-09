package com.altall.market.shop

import android.content.Intent
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class ShopFirebaseService : FirebaseMessagingService() {

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        val data = message.data
        val title = data["title"] ?: "طلب جديد"
        val body = data["body"] ?: "لديك طلب جديد"

        // Always show system notification as fallback
        NotificationHelper.showFullScreenNotification(this, title, body)

        // Still start the overlay service as before
        val intent = Intent(this, OrderOverlayService::class.java).apply {
            putExtra("title", title)
            putExtra("body", body)
        }
        startService(intent)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // إذا عندك رفع توكن للسيرفر ضيفه هنا
    }
}