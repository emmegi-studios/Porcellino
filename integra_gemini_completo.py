import re

# 1. Scriviamo un pubspec.yaml pulito e blindato con tutte le dipendenze
pubspec_content = """name: family_budget_app
description: Un caveau di coppia sicuro, privato e intelligente.
publish_to: 'none'
version: 2.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.15.3
  firebase_messaging: ^14.7.10
  speech_to_text: ^6.5.1
  flutter_tts: ^3.8.3
  google_generative_ai: ^0.4.3
  package_info_plus: ^5.0.1
  dio: ^5.4.0
  open_filex: ^4.3.2
  path_provider: ^2.1.1

flutter:
  uses-material-design: true
  assets:
    - assets/
"""

with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(pubspec_content)

print("✅ File pubspec.yaml rigenerato con tutti i pacchetti necessari!")

# 2. Modifichiamo il main.dart per integrare Gemini nel widget dell'AI
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Aggiungiamo l'import di Gemini se non c'è
if "import 'package:google_generative_ai" not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:google_generative_ai/google_generative_ai.dart';"
    )

# Sostituiamo il metodo _sendMessage con la versione potenziata da Gemini AI
vecchio_send = """  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _messageController.clear();
    });

    // Risposta simulata di Piggy per ora
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        _messages.add({
          'sender': 'piggy',
          'text': 'Oink! Ho ricevuto: "' + text + '". Sto elaborando il tuo caveau!'
        });
      });
      _speak('Oink! Ho ricevuto la tua richiesta.');
    });
  }"""

nuovo_send = f"""  void _sendMessage() async {{
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {{
      _messages.add({{'sender': 'user', 'text': text}});
      _messageController.clear();
    }});

    // Chiamata al cervello di Gemini AI con la tua API Key
    try {{
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: 'AQ.Ab8RN6LoZq1C32hj4UpiZqX3BfM8EUvMJnYMgW5MfUUG-t5z5g',
        systemInstruction: Content.system("Sei Piggy, l'AI di un'app finanziaria di coppia. Leggi la frase dell'utente e rispondi in modo amichevole e conciso, confermando l'azione finanziaria (es. spesa registrata, obiettivo aggiornato)."),
      );

      final response = await model.generateContent([Content.text(text)]);
      final rispostaAi = response.text ?? "Oink! Operazione registrata nel caveau.";

      setState(() {{
        _messages.add({{'sender': 'piggy', 'text': rispostaAi}});
      }});
      _speak(rispostaAi);
    }} catch (e) {{
      setState(() {{
        _messages.add({{'sender': 'piggy', 'text': 'Oink! Errore di connessione con il cervello di Gemini: $e'}});
      }});
    }}
  }}"""

if "GenerativeModel(" not in content:
    content = content.replace(vecchio_send, nuovo_send)
    print("✅ Cervello Gemini AI integrato nel metodo _sendMessage!")

content += '\n// Versione 2.0.0 con Gemini AI integrato\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Integrazione completata con successo!")
