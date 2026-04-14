package com.missionout.responder

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MissionAlertFirebaseMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
            .edit()
            .putString(KEY_LAST_PUSH_TOKEN, token)
            .apply()
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val incidentPublicId =
            message.data[KEY_INCIDENT_PUBLIC_ID]?.takeIf { it.isNotBlank() } ?: return
        val title = message.data[KEY_TITLE]
            ?: message.notification?.title
            ?: "Mission alert"
        val body = message.data[KEY_BODY]
            ?: message.notification?.body
            ?: "Open the responder app for details."

        MissionAlertNotifier.showAlert(
            context = applicationContext,
            title = title,
            body = body,
            incidentPublicId = incidentPublicId
        )
        NativeAlertBridge.emitAction(
            context = applicationContext,
            action = "received",
            incidentPublicId = incidentPublicId,
            title = title,
            body = body
        )
    }

    companion object {
        private const val PREFS_NAME = "missionout_native_push"
        private const val KEY_LAST_PUSH_TOKEN = "last_push_token"
        private const val KEY_INCIDENT_PUBLIC_ID = "incident_public_id"
        private const val KEY_TITLE = "title"
        private const val KEY_BODY = "body"
    }
}
