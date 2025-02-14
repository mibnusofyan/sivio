import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({super.key});

  @override
  State<SpeechToTextPage> createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    if (await Permission.microphone.request().isGranted) {
      _speechEnabled = await _speechToText.initialize();

      var availableLocales = await _speechToText.locales();
      var indonesianLocale = availableLocales
          .where((locale) => locale.localeId == 'id_ID')
          .toList();

      if (indonesianLocale.isEmpty) {
        print('Bahasa Indonesia tidak tersedia di perangkat ini');
      }

      setState(() {});
    }
  }

  Future<void> _startListening() async {
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
        });
      },
      localeId: 'id_ID',
      cancelOnError: true,
      partialResults: true,
    );
    setState(() {});
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Tekan tombol dan mulai berbicara',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _lastWords,
                  style: const TextStyle(fontSize: 24.0),
                ),
              ),
            ),
            if (!_speechEnabled)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Speech to text tidak tersedia.',
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _speechToText.isNotListening ? _startListening : _stopListening,
        tooltip: 'Listen',
        child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
