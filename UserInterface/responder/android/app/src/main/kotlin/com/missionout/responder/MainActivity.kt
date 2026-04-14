package com.missionout.responder

import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private val notificationPermissionLauncher: ActivityResultLauncher<String> =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            NativeAlertBridge.onNotificationPermissionResult(granted)
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NativeAlertBridge.configure(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        NativeAlertBridge.attachActivity(this, notificationPermissionLauncher)
    }

    override fun onDestroy() {
        NativeAlertBridge.detachActivity(this)
        super.onDestroy()
    }
}
