import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Aggiungiamo le variabili di stato per il riconoscimento vocale
vecchie_var = "final FlutterTts _tts = FlutterTts();"
nuove_var = "final FlutterTts _tts = FlutterTts();\n  final stt.SpeechToText _speech = stt.SpeechToText();\n  bool _isListening = false;"
if 'stt.SpeechToText _speech' not in content:
    content = content.replace(vecchie_var, nuove_var)

# 2. Inseriamo le funzioni del Walkie-Talkie prima di _sendMessage()
ptt_methods = """
  void _startListening() async {
    HapticFeedback.mediumImpact(); // Vibrazione quando premi
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _messageController.text = val.recognizedWords;
        }),
        localeId: 'it_IT',
      );
    }
  }

  void _stopListening() {
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
      if (_messageController.text.isNotEmpty) {
        _sendMessage(); // Invia il comando in automatico appena rilasci!
      }
    }
  }
"""

if '_startListening' not in content:
    content = content.replace("  void _sendMessage() {", ptt_methods + "\n  void _sendMessage() {")

content += '\n// Logica Push-to-Talk STT aggiunta v2.0-beta.2\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Cervello Push-to-Talk installato!")
