package com.zexolver.zelia

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.service.voice.VoiceInteractionSession

/**
 * Minimal assistant session: rather than rendering a custom floating
 * overlay UI (the full VoiceInteractionSession model most system
 * assistants use), this just brings ZELIA's own chat screen to the
 * front with ACTION_ASSIST_LISTEN and finishes immediately -- MainActivity
 * picks that action up and tells the Flutter side to start listening
 * right away, matching the "hold home, ZELIA's ready to listen" feel
 * without maintaining a second UI implementation as an overlay.
 */
class ZeliaVoiceInteractionSession(context: Context) : VoiceInteractionSession(context) {
    override fun onShow(args: Bundle?, showFlags: Int) {
        super.onShow(args, showFlags)
        val intent = Intent(context, MainActivity::class.java).apply {
            action = ACTION_ASSIST_LISTEN
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        context.startActivity(intent)
        finish()
    }

    companion object {
        const val ACTION_ASSIST_LISTEN = "com.zexolver.zelia.ACTION_ASSIST_LISTEN"
    }
}
