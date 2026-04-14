package com.missionout.responder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class MissionAlertActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val incidentPublicId = intent.getStringExtra(MissionAlertNotifier.EXTRA_INCIDENT_PUBLIC_ID).orEmpty()
        if (incidentPublicId.isEmpty()) {
            return
        }

        val title = intent.getStringExtra(MissionAlertNotifier.EXTRA_TITLE).orEmpty()
        val body = intent.getStringExtra(MissionAlertNotifier.EXTRA_BODY).orEmpty()

        val responderAction = when (action) {
            ACTION_RESPONDING -> "responding"
            ACTION_UNAVAILABLE -> "not_available"
            else -> return
        }

        NativeAlertBridge.emitAction(
            context = context,
            action = responderAction,
            incidentPublicId = incidentPublicId,
            title = title,
            body = body
        )
        MissionAlertNotifier.dismissActiveAlert(context)
    }

    companion object {
        const val ACTION_RESPONDING = "com.missionout.responder.ACTION_RESPONDING"
        const val ACTION_UNAVAILABLE = "com.missionout.responder.ACTION_UNAVAILABLE"

        fun intent(
            context: Context,
            action: String,
            incidentPublicId: String,
            title: String,
            body: String
        ): Intent {
            return Intent(context, MissionAlertActionReceiver::class.java).apply {
                this.action = action
                putExtra(MissionAlertNotifier.EXTRA_INCIDENT_PUBLIC_ID, incidentPublicId)
                putExtra(MissionAlertNotifier.EXTRA_TITLE, title)
                putExtra(MissionAlertNotifier.EXTRA_BODY, body)
            }
        }
    }
}
