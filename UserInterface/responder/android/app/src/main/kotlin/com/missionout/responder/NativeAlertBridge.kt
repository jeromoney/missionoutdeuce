package com.missionout.responder

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.net.Uri
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

object NativeAlertBridge {
    private const val METHOD_CHANNEL = "com.missionout.responder/native_alert"
    private const val EVENT_CHANNEL = "com.missionout.responder/native_alert_events"
    private const val PREFS_NAME = "missionout_native_alert"
    private const val PENDING_EVENT_KEY = "pending_event"

    private var appContext: Context? = null
    private var activity: ComponentActivity? = null
    private var eventSink: EventChannel.EventSink? = null
    private var notificationPermissionLauncher: ActivityResultLauncher<String>? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    fun configure(context: Context, messenger: BinaryMessenger) {
        appContext = context.applicationContext

        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler(::onMethodCall)
        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                    emitPendingEvent()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    fun attachActivity(
        activity: ComponentActivity,
        notificationPermissionLauncher: ActivityResultLauncher<String>
    ) {
        this.activity = activity
        this.notificationPermissionLauncher = notificationPermissionLauncher
    }

    fun detachActivity(activity: ComponentActivity) {
        if (this.activity == activity) {
            this.activity = null
            this.notificationPermissionLauncher = null
        }
    }

    fun onNotificationPermissionResult(granted: Boolean) {
        val result = pendingPermissionResult ?: return
        pendingPermissionResult = null
        val context = appContext
        if (context == null) {
            result.error("context_unavailable", "Application context is unavailable.", null)
            return
        }
        result.success(buildStatusPayload(context))
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                emitPendingEvent()
                val context = appContext
                if (context == null) {
                    result.error("context_unavailable", "Application context is unavailable.", null)
                    return
                }
                result.success(buildStatusPayload(context))
            }

            "refreshCapabilities" -> {
                val context = appContext
                if (context == null) {
                    result.error("context_unavailable", "Application context is unavailable.", null)
                    return
                }
                result.success(buildStatusPayload(context))
            }

            "requestNotificationPermission" -> {
                val context = appContext
                if (context == null) {
                    result.error("context_unavailable", "Application context is unavailable.", null)
                    return
                }

                if (hasNotificationPermission(context) || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                    result.success(buildStatusPayload(context))
                    return
                }

                val launcher = notificationPermissionLauncher
                if (launcher == null) {
                    result.error(
                        "activity_unavailable",
                        "Notification permission requires an active activity.",
                        null
                    )
                    return
                }

                pendingPermissionResult?.error(
                    "request_in_progress",
                    "A notification permission request is already in progress.",
                    null
                )
                pendingPermissionResult = result
                launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }

            "showNativeAlert" -> {
                val title = call.argument<String>("title").orEmpty()
                val body = call.argument<String>("body").orEmpty()
                val incidentPublicId = call.argument<String>("incidentPublicId").orEmpty()
                val context = appContext
                if (context == null || incidentPublicId.isEmpty()) {
                    result.error("invalid_args", "Context or incidentPublicId missing.", null)
                    return
                }

                MissionAlertNotifier.showAlert(
                    context = context,
                    title = title.ifEmpty { "Mission alert" },
                    body = body.ifEmpty { "New incident received." },
                    incidentPublicId = incidentPublicId
                )
                result.success(null)
            }

            "dismissActiveAlert" -> {
                appContext?.let(MissionAlertNotifier::dismissActiveAlert)
                result.success(null)
            }

            "openNotificationPolicySettings" -> {
                val context = appContext
                if (context == null) {
                    result.error("context_unavailable", "Application context is unavailable.", null)
                    return
                }
                launchSettingsIntent(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                result.success(null)
            }

            "openFullScreenIntentSettings" -> {
                val context = appContext
                if (context == null) {
                    result.error("context_unavailable", "Application context is unavailable.", null)
                    return
                }

                val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                        data = Uri.parse("package:${context.packageName}")
                    }
                } else {
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                        putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                    }
                }
                launchSettingsIntent(intent)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    fun emitAction(
        context: Context,
        action: String,
        incidentPublicId: String,
        title: String,
        body: String
    ) {
        val payload = hashMapOf(
            "action" to action,
            "incidentPublicId" to incidentPublicId,
            "title" to title,
            "body" to body
        )

        val sink = eventSink
        if (sink != null) {
            sink.success(payload)
            clearPendingEvent(context)
            return
        }

        context
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(PENDING_EVENT_KEY, JSONObject(payload as Map<*, *>).toString())
            .apply()
    }

    private fun emitPendingEvent() {
        val context = appContext ?: return
        val sink = eventSink ?: return
        val raw = context
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(PENDING_EVENT_KEY, null)
            ?: return

        val json = JSONObject(raw)
        val payload = hashMapOf(
            "action" to json.optString("action"),
            "incidentPublicId" to json.optString("incidentPublicId"),
            "title" to json.optString("title"),
            "body" to json.optString("body")
        )
        sink.success(payload)
        clearPendingEvent(context)
    }

    private fun clearPendingEvent(context: Context) {
        context
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(PENDING_EVENT_KEY)
            .apply()
    }

    private fun buildStatusPayload(context: Context): Map<String, Any> {
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return mapOf(
            "supportsPostNotifications" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU),
            "supportsFullScreenIntentManagement" to
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE),
            "notificationPermissionGranted" to hasNotificationPermission(context),
            "notificationPolicyAccessGranted" to notificationManager.isNotificationPolicyAccessGranted,
            "canUseFullScreenIntent" to canUseFullScreenIntent(notificationManager)
        )
    }

    private fun hasNotificationPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return true
        }
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun canUseFullScreenIntent(notificationManager: NotificationManager): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            notificationManager.canUseFullScreenIntent()
        } else {
            true
        }
    }

    private fun launchSettingsIntent(intent: Intent) {
        val resolved = activity ?: appContext ?: return
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        resolved.startActivity(intent)
    }
}
