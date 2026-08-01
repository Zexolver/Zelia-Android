package com.zexolver.zelia

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.rementia.openwakeword.lib.WakeWordEngine
import com.rementia.openwakeword.lib.model.WakeWordModel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Foreground service hosting the always-listening "hey jarvis" wake word
 * (com.rementia.openwakeword.lib -- vendored openWakeWord port, see its
 * NOTICE.md; uses the same ONNX models the desktop already runs via
 * Python openwakeword, no retraining needed). Only runs while the
 * "Always listen" setting is on (settings_screen.dart). A persistent
 * notification is both an Android requirement for a continuous-
 * microphone foreground service and matches this project's "nothing
 * hidden" principle -- the user always sees when she's listening in the
 * background.
 *
 * "hey jarvis" is meant to be a stopgap: once a custom "hey Zelia" model
 * is trained (see CLAUDE.md-tracked plan), this stays around only as an
 * opt-in fallback, not the default.
 */
class WakeWordService : Service() {
    private val scope = CoroutineScope(Dispatchers.Default + Job())
    private var engine: WakeWordEngine? = null

    companion object {
        const val CHANNEL_ID = "zelia_wake_word"
        const val NOTIFICATION_ID = 1
        const val ACTION_PAUSE = "com.zexolver.zelia.WAKE_WORD_PAUSE"
        const val ACTION_RESUME = "com.zexolver.zelia.WAKE_WORD_RESUME"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForegroundWithNotification()
        startEngine()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PAUSE -> engine?.stop()
            ACTION_RESUME -> engine?.start()
        }
        return START_STICKY
    }

    private fun startEngine() {
        val model = WakeWordModel(name = "Hey Jarvis", modelPath = "hey_jarvis_v0.1.onnx", threshold = 0.5f)
        val newEngine = WakeWordEngine(context = this, models = listOf(model))
        engine = newEngine
        scope.launch {
            newEngine.detections.collect {
                // Release the mic before handing off to the assist flow's
                // own speech_to_text capture -- AudioRecord doesn't
                // reliably support two simultaneous owners.
                newEngine.stop()
                val launchIntent = Intent(this@WakeWordService, MainActivity::class.java).apply {
                    action = ZeliaVoiceInteractionSession.ACTION_ASSIST_LISTEN
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                startActivity(launchIntent)
            }
        }
        newEngine.start()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID, "ZELIA wake word", NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shown while ZELIA is listening for \"hey jarvis\" in the background."
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun startForegroundWithNotification() {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ZELIA is listening")
            .setContentText("Say \"hey jarvis\" to talk to her")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    override fun onDestroy() {
        engine?.release()
        engine = null
        scope.cancel()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
