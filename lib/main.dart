
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';

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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF071426),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C8FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
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
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isTranslating = false;
  bool _isSpeaking = false;

  bool _russianToSpanish = true;

  String _recognizedText = '';
  String _translatedText = '';
  String _error = '';

  String get sourceLanguage =>
      _russianToSpanish ? 'Русский' : 'Español';

  String get targetLanguage =>
      _russianToSpanish ? 'Español' : 'Русский';

  String get sourceLocale =>
      _russianToSpanish ? 'ru_RU' : 'es_ES';

  String get targetLocale =>
      _russianToSpanish ? 'es-ES' : 'ru-RU';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeTts();
  }

  Future<void> _initializeSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          setState(() {
            _isListening = _speech.isListening;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _error = 'Ошибка микрофона: ${error.errorMsg}';
            _isListening = false;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _speechAvailable = available;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось запустить микрофон';
      });
    }
  }

  Future<void> _initializeTts() async {
    await _tts.setLanguage(targetLocale);
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      await _initializeSpeech();
    }

    if (!_speechAvailable) {
      setState(() {
        _error = 'Распознавание речи недоступно на телефоне';
      });
      return;
    }

    await _tts.stop();

    setState(() {
      _recognizedText = '';
      _translatedText = '';
      _error = '';
      _isListening = true;
    });

    try {
      await _speech.listen(
        localeId: sourceLocale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _error = 'Не удалось начать запись';
      });
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    if (_recognizedText.trim().isEmpty) {
      setState(() {
        _error = 'Речь не распознана. Попробуй ещё раз.';
      });
      return;
    }

    await _translate();
  }

  Future<void> _translate() async {
    final text = _recognizedText.trim();

    if (text.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _error = '';
      _translatedText = '';
    });

    try {
      final languagePair = _russianToSpanish ? 'ru|es' : 'es|ru';

      final uri = Uri.https(
        'api.mymemory.translated.net',
        '/get',
        {
          'q': text,
          'langpair': languagePair,
        },
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Ошибка сервиса перевода');
      }

      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (data['responseStatus'] != 200) {
        throw Exception(
          data['responseDetails'] ?? 'Перевод не выполнен',
        );
      }

      final translated = data['responseData']['translatedText']
          ?.toString();

      if (translated == null || translated.isEmpty) {
        throw Exception('Пустой ответ переводчика');
      }

      if (!mounted) return;

      setState(() {
        _translatedText = translated;
        _isTranslating = false;
      });

      await _speakTranslation();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isTranslating = false;
        _error = 'Не удалось перевести. Проверь интернет и попробуй снова.';
      });
    }
  }

  Future<void> _speakTranslation() async {
    if (_translatedText.isEmpty) return;

    try {
      await _tts.stop();
      await _tts.setLanguage(targetLocale);
      await _tts.setSpeechRate(0.48);

      setState(() {
        _isSpeaking = true;
      });

      await _tts.speak(_translatedText);

      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
        _error = 'Не удалось озвучить перевод';
      });
    }
  }

  Future<void> _swapLanguages() async {
    if (_isListening) {
      await _speech.stop();
    }

    await _tts.stop();

    setState(() {
      _russianToSpanish = !_russianToSpanish;
      _recognizedText = '';
      _translatedText = '';
      _error = '';
      _isListening = false;
    });

    await _tts.setLanguage(targetLocale);
  }

  void _clearText() {
    setState(() {
      _recognizedText = '';
      _translatedText = '';
      _error = '';
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF071426),
        centerTitle: true,
        title: const Text(
          'DUOTALK',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: Color(0xFF00C8FF),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _clearText,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Очистить',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 15),

              const Text(
                'Голосовой переводчик',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Говори на своём языке',
                style: TextStyle(color: Colors.white60),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: _languageCard(
                      sourceLanguage,
                      'Я говорю',
                    ),
                  ),
                  IconButton(
                    onPressed: _swapLanguages,
                    icon: const Icon(
                      Icons.swap_horiz,
                      size: 36,
                      color: Color(0xFF00C8FF),
                    ),
                  ),
                  Expanded(
                    child: _languageCard(
                      targetLanguage,
                      'Перевод',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _textCard(
                title: 'Распознанная речь',
                text: _recognizedText,
                placeholder: 'Здесь появится твоя речь...',
                icon: Icons.mic_none,
              ),

              const SizedBox(height: 16),

              _textCard(
                title: 'Перевод',
                text: _translatedText,
                placeholder: 'Здесь появится перевод...',
                icon: Icons.translate,
              ),

              const SizedBox(height: 25),

              if (_isTranslating)
                const Column(
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF00C8FF),
                    ),
                    SizedBox(height: 12),
                    Text('Переводим...'),
                  ],
                ),

              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton.icon(
                  onPressed: _isTranslating
                      ? null
                      : (_isListening
                          ? _stopListening
                          : _startListening),
                  icon: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    size: 29,
                  ),
                  label: Text(
                    _isListening
                        ? 'ОСТАНОВИТЬ И ПЕРЕВЕСТИ'
                        : 'НАЧАТЬ ГОВОРИТЬ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening
                        ? Colors.redAccent
                        : const Color(0xFF007DAA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: _translatedText.isEmpty || _isSpeaking
                      ? null
                      : _speakTranslation,
                  icon: const Icon(Icons.volume_up),
                  label: Text(
                    _isSpeaking
                        ? 'ВОСПРОИЗВЕДЕНИЕ...'
                        : 'ПРОСЛУШАТЬ ПЕРЕВОД',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00C8FF),
                    side: const BorderSide(
                      color: Color(0xFF00C8FF),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'DUOTALK • Перевод между людьми',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageCard(String language, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 17,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF102640),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00A9D6).withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Text(
            language,
            style: const TextStyle(
              color: Color(0xFF00C8FF),
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textCard({
    required String title,
    required String text,
    required String placeholder,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 135),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF102640),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF00C8FF),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            text.isEmpty ? placeholder : text,
            style: TextStyle(
              fontSize: 17,
              height: 1.4,
              color: text.isEmpty ? Colors.white38 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
