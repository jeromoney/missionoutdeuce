package com.missionout.responder

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.RingtoneManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object MissionAlertNotifier {
    const val EXTRA_INCIDENT_PUBLIC_ID = "incident_public_id"
    const val EXTRA_TITLE = "title"
    const val EXTRA_BODY = "body"

    private const val URGENT_CHANNEL_ID = "missionout_responder_urgent"
    private const val URGENT_CHANNEL_NAME = "Mission alerts"
    private const val NOTIFICATION_ID = 22041

    fun showAlert(
        context: Context,
        title: String,
        body: String,
        incidentPublicId: String
    ) {
        createChannel(context)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val fullScreenIntent = Intent(context, MissionAlertActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_INCIDENT_PUBLIC_ID, incidentPublicId)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            1001,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val respondingIntent = PendingIntent.getBroadcast(
            context,
            1002,
            MissionAlertActionReceiver.intent(
                context = context,
                action = MissionAlertActionReceiver.ACTION_RESPONDING,
                incidentPublicId = incidentPublicId,
                title = title,
                body = body
            ),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val unavailableIntent = PendingIntent.getBroadcast(
            context,
            1003,
            MissionAlertActionReceiver.intent(
                context = context,
                action = MissionAlertActionReceiver.ACTION_UNAVAILABLE,
                incidentPublicId = incidentPublicId,
                title = title,
                body = body
            ),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, URGENT_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(fullScreenPendingIntent)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .addAction(0, "Responding", respondingIntent)
            .addAction(0, "Unavailable", unavailableIntent)
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
            .setVibrate(longArrayOf(0, 600, 300, 600, 300, 900))
            .build()

        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        vibrateDevice(context)
    }

    fun dismissActiveAlert(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            URGENT_CHANNEL_ID,
            URGENT_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Full-screen responder mission alerts"
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            setBypassDnd(true)
            enableVibration(true)
        }
        manager.createNotificationChannel(channel)
    }

    private fun vibrateDevice(context: Context) {
        val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return
        if (!vibrator.hasVibrator()) {
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createWaveform(longArrayOf(0, 500, 250, 500), -1)
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(longArrayOf(0, 500, 250, 500), -1)
        }
    }
}
