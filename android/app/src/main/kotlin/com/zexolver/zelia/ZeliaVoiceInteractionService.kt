package com.zexolver.zelia

import android.service.voice.VoiceInteractionService

/** No custom behavior needed here -- the actual work happens in
 * ZeliaVoiceInteractionSessionService/ZeliaVoiceInteractionSession. This
 * class existing and being declared in the manifest is what makes ZELIA
 * selectable under Settings > Apps > Default apps > Digital assistant app. */
class ZeliaVoiceInteractionService : VoiceInteractionService()
