import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper around speech_to_text (mic -> transcript) and flutter_tts
/// (reply text -> spoken audio) -- both wrap the device's own native
/// engines, no ZELIA server round-trip needed for the voice conversion
/// itself, only for the actual question/answer.
class VoiceService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttReady = false;

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Starts listening, calling `onResult` once with the final transcript
  /// when the user stops speaking (or the recognizer decides they have).
  /// `onListeningChange` fires true right as capture starts and false
  /// once it ends (for updating a mic button's appearance). Returns
  /// false immediately (no callbacks fire) if the mic permission is
  /// denied or the device has no speech recognizer available.
  Future<bool> startListening({
    required void Function(String text) onResult,
    void Function(bool listening)? onListeningChange,
  }) async {
    if (!await _ensureMicPermission()) return false;

    if (!_sttReady) {
      _sttReady = await _stt.initialize();
      if (!_sttReady) return false;
    }

    await _stt.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          onResult(result.recognizedWords.trim());
        }
      },
      listenOptions: SpeechListenOptions(cancelOnError: true, partialResults: false),
    );
    onListeningChange?.call(true);
    // speech_to_text has no single "done" callback for this call shape --
    // poll its own isListening flag instead of adding a fixed timer, so
    // this tracks whatever silence-timeout the platform recognizer itself
    // decides on rather than guessing a duration.
    _watchListeningState(onListeningChange);
    return true;
  }

  void _watchListeningState(void Function(bool listening)? onListeningChange) async {
    while (_stt.isListening) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    onListeningChange?.call(false);
  }

  void stopListening() {
    _stt.stop();
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();
}
