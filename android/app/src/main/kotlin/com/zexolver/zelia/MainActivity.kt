package com.zexolver.zelia

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges both the assist-gesture launch (ZeliaVoiceInteractionSession)
 * and the always-listening wake-word service (WakeWordService) into
 * Flutter.
 *
 * Assist-launch detection has two paths, matching the two ways this
 * activity can end up handling one:
 *  - Cold start: Dart isn't running yet when the intent arrives, so a
 *    push here would race the engine's own startup. Instead Dart pulls
 *    via consumeAssistLaunch once it's ready (see chat_screen.dart).
 *  - Already running (singleTop -> onNewIntent): Dart's method channel
 *    handler is already registered by now, so this pushes startListening
 *    directly -- no race here since the engine's long since configured.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.zexolver.zelia/assist"
    private var methodChannel: MethodChannel? = null
    private var pendingAssistLaunch = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingAssistLaunch = intent?.action == ZeliaVoiceInteractionSession.ACTION_ASSIST_LISTEN
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeAssistLaunch" -> {
                    result.success(pendingAssistLaunch)
                    pendingAssistLaunch = false
                }
                "startWakeWordService" -> {
                    startForegroundService(Intent(this, WakeWordService::class.java))
                    result.success(null)
                }
                "stopWakeWordService" -> {
                    stopService(Intent(this, WakeWordService::class.java))
                    result.success(null)
                }
                "pauseWakeWordListening" -> {
                    startService(Intent(this, WakeWordService::class.java).setAction(WakeWordService.ACTION_PAUSE))
                    result.success(null)
                }
                "resumeWakeWordListening" -> {
                    startService(Intent(this, WakeWordService::class.java).setAction(WakeWordService.ACTION_RESUME))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        methodChannel = channel
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == ZeliaVoiceInteractionSession.ACTION_ASSIST_LISTEN) {
            methodChannel?.invokeMethod("startListening", null)
        }
    }
}
