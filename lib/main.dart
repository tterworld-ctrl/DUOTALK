
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const DuoTalkApp());
}

class DuoTalkApp extends StatelessWidget {
  const DuoTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DUOTALK',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07111F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D9FF),
        ),
      ),
      home: const TranslatorPage(),
    );
  }
}

class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  final SpeechToText speech = SpeechToText();
  final FlutterTts tts = FlutterTts();

  bool listening = false;
  bool available = false;

  String recognizedText = '';
  String status = 'Нажми на микрофон и говори';

  String sourceLanguage = 'Русский';
  String targetLanguage = 'Испанский';

  String sourceLocale = 'ru_RU';
  String targetLocale = 'es_ES';

  @override
  void initState() {
    super.initState();
    initializeSpeech();
  }

  Future<void> initializeSpeech() async {
    available = await speech.initialize(
      onStatus: (value) {
        if (mounted) {
          setState(() {
            listening = value == 'listening';
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            status = 'Ошибка микрофона: ${error.errorMsg}';
            listening = false;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        status = available
            ? 'Нажми на микрофон и говори'
            : 'Распознавание речи недоступно';
      });
    }
  }

  Future<void> startListening() async {
    if (!available) {
      await initializeSpeech();
    }

    if (!available) {
      setState(() {
        status = 'Проверь разрешение на микрофон';
      });
      return;
    }

    setState(() {
      recognizedText = '';
      status = 'Слушаю тебя...';
      listening = true;
    });

    await speech.listen(
      localeId: sourceLocale,
      onResult: (result) {
        if (mounted) {
          setState(() {
            recognizedText = result.recognizedWords;
          });
        }
      },
    );
  }

  Future<void> stopListening() async {
    await speech.stop();

    if (mounted) {
      setState(() {
        listening = false;
        status = 'Запись завершена';
      });
    }
  }

  Future<void> speakText() async {
    if (recognizedText.isEmpty) {
      setState(() {
        status = 'Сначала произнеси текст';
      });
      return;
    }

    await tts.setLanguage(sourceLocale);
    await tts.setSpeechRate(0.45);
    await tts.speak(recognizedText);
  }

  void changeLanguages() {
    setState(() {
      final oldSource = sourceLanguage;
      sourceLanguage = targetLanguage;
      targetLanguage = oldSource;

      final oldLocale = sourceLocale;
      sourceLocale = targetLocale;
      targetLocale = oldLocale;

      recognizedText = '';
      status = 'Языки изменены';
    });
  }

  @override
  void dispose() {
    speech.stop();
    tts.stop();
    super.dispose();
  }

  Widget languageCard(String label, String language) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF12243A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF23445D)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              language,
              style: const TextStyle(
                color: Color(0xFF00D9FF),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111F),
        centerTitle: true,
        title: const Text(
          'DUOTALK',
          style: TextStyle(
            color: Color(0xFF00D9FF),
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 15),
              const Text(
                'Голосовой перевод',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),

              Row(
                children: [
                  languageCard('С языка', sourceLanguage),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: changeLanguages,
                    icon: const Icon(
                      Icons.swap_horiz,
                      color: Color(0xFF00D9FF),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 10),
                  languageCard('На язык', targetLanguage),
                ],
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 180),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF102238),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF17445D),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Распознанная речь',
                      style: TextStyle(
                        color: Color(0xFF00D9FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      recognizedText.isEmpty
                          ? 'Здесь появится твоя речь...'
                          : recognizedText,
                      style: const TextStyle(fontSize: 19),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: listening ? stopListening : startListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 105,
                  height: 105,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: listening
                        ? Colors.redAccent
                        : const Color(0xFF00BFEA),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D9FF)
                            .withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    listening ? Icons.stop : Icons.mic,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: speakText,
                  icon: const Icon(Icons.volume_up),
                  label: const Text(
                    'Прослушать текст',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF123B56),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
