import 'package:flutter/material.dart';
import 'dart:async';
import 'package:jarvis_ai_assistant/voice_service.dart';
import 'package:jarvis_ai_assistant/gpt_service.dart';
import 'package:jarvis_ai_assistant/models/message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env.local");
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarvis AI Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const VoiceAssistantScreen(),
    );
  }
}

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final GPTService _gptService = GPTService();
  final ScrollController _scrollController = ScrollController();

  bool _isListening = false;
  bool _isThinking = false;

  List<Message> _messages = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _voiceService.initSpeech().then((_) {
      _voiceService.initTTS();
      _startListeningAutomatically();
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startListeningAutomatically() {
    _voiceService.startListening();
    setState(() {
      _isListening = true;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _toggleListening() async {
    if (_isListening) {
      final text = await _voiceService.stopListening();
      setState(() {
        _isListening = false;
        _isThinking = true;
        _messages.add(Message(text: text, isUser: true));
      });
      _scrollToBottom();

      final reply = await _gptService.getResponse(text);
      setState(() {
        _messages.add(Message(text: reply, isUser: false));
        _isThinking = false;
      });
      _scrollToBottom();

      _voiceService.speak(reply);

      _startListeningAutomatically(); // resume listening
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Jarvis'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[_messages.length - 1 - index];
                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? Colors.deepPurple
                            : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontStyle: msg.isUser
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isThinking)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Jarvis is thinking...",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _toggleListening,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final glow = 0.6 + (_animationController.value * 0.4);
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple.withOpacity(glow),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(glow),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "Jarvis",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
