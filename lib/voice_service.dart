import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  String _lastWords = '';

  Future<void> initSpeech() async {
    await _speech.initialize();
  }

  void startListening() {
    _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
      },
    );
  }

  Future<String> stopListening() async {
    await _speech.stop();
    return _lastWords;
  }

  Future<void> initTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
  }

  void speak(String text) async {
    await _tts.speak(text);
  }
}

