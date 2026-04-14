package com.missionout.responder

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.ComponentActivity

class MissionAlertActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        val incidentPublicId = intent.getStringExtra(MissionAlertNotifier.EXTRA_INCIDENT_PUBLIC_ID).orEmpty()
        val title = intent.getStringExtra(MissionAlertNotifier.EXTRA_TITLE).orEmpty()
        val body = intent.getStringExtra(MissionAlertNotifier.EXTRA_BODY).orEmpty()

        setContentView(
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                setPadding(48, 72, 48, 72)
                setBackgroundColor(Color.parseColor("#08131F"))

                addView(
                    TextView(context).apply {
                        text = "MissionOut Alert"
                        textSize = 18f
                        setTextColor(Color.parseColor("#7FB3FF"))
                    }
                )

                addView(
                    TextView(context).apply {
                        text = title.ifEmpty { "Mission alert" }
                        textSize = 28f
                        setPadding(0, 24, 0, 18)
                        setTextColor(Color.WHITE)
                    }
                )

                addView(
                    TextView(context).apply {
                        text = body.ifEmpty { "Open the responder app for details." }
                        textSize = 18f
                        gravity = Gravity.CENTER
                        setTextColor(Color.parseColor("#D8E2F0"))
                        setPadding(0, 0, 0, 36)
                    }
                )

                addView(
                    Button(context).apply {
                        text = "Responding"
                        setOnClickListener {
                            dispatchAction(
                                action = "responding",
                                incidentPublicId = incidentPublicId,
                                title = title,
                                body = body
                            )
                        }
                    }
                )

                addView(
                    Button(context).apply {
                        text = "Unavailable"
                        setOnClickListener {
                            dispatchAction(
                                action = "not_available",
                                incidentPublicId = incidentPublicId,
                                title = title,
                                body = body
                            )
                        }
                    }
                )
            }
        )
    }

    private fun dispatchAction(
        action: String,
        incidentPublicId: String,
        title: String,
        body: String
    ) {
        if (incidentPublicId.isNotEmpty()) {
            NativeAlertBridge.emitAction(
                context = applicationContext,
                action = action,
                incidentPublicId = incidentPublicId,
                title = title,
                body = body
            )
        }
        MissionAlertNotifier.dismissActiveAlert(applicationContext)
        finish()
    }
}
