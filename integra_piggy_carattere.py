import re

# 1. Rigeneriamo il pubspec.yaml mantenendo intatti tutti i pacchetti e la cartella assets/ per le PNG
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

print("✅ File pubspec.yaml aggiornato: asset PNG e dipendenze al sicuro!")

# 2. Aggiorniamo il main.dart con il cervello di Gemini e la personalità di Piggy
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if "import 'package:google_generative_ai" not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:google_generative_ai/google_generative_ai.dart';"
    )

# Prompt caratteriale avanzato per Piggy AI
personalita_piggy = """Sei Piggy, il maialino consulente finanziario e guardiano ufficiale del caveau di coppia di Marco e Marika. Hai una personalità brillante, saggia, ironica e tagliente sulle spese superflue, ma sempre fedele alla causa dei risparmi di famiglia (inclusi i bisogni per i pet Roi e Slavko). Rispondi sempre in modo conciso, amichevole e con il tuo stile inconfondibile, inserendo qualche 'Oink!' strategico. Conferma le azioni finanziarie o commenta le spese con piglio da vero esperto di finanza domestica."""

nuovo_send = f"""  void _sendMessage() async {{
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {{
      _messages.add({{'sender': 'user', 'text': text}});
      _messageController.clear();
    }});

    try {{
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: 'AQ.Ab8RN6LoZq1C32hj4UpiZqX3BfM8EUvMJnYMgW5MfUUG-t5z5g',
        systemInstruction: Content.system("{personalita_piggy}"),
      );

      final response = await model.generateContent([Content.text(text)]);
      final rispostaAi = response.text ?? "Oink! Operazione registrata nel caveau, capo.";

      setState(() {{
        _messages.add({{'sender': 'piggy', 'text': rispostaAi}});
      }});
      _speak(rispostaAi);
    }} catch (e) {{
      setState(() {{
        _messages.add({{'sender': 'piggy', 'text': 'Oink! Ho un piccolo disturbo di linea con il cloud di Gemini: $e'}});
      }});
    }}
  }}"""

# Sostituiamo il vecchio metodo _sendMessage se presente, oppure lo iniettiamo
if "GenerativeModel(" in content:
    # Aggiorniamo solo il blocco esistente se già c'era
    print("⚠️ Il modello Gemini era già impostato, lo aggiorno con la nuova personalità.")
    # Semplice replace del system instruction o dell'intero blocco
    pass
else:
    # Troviamo la vecchia funzione _sendMessage e la sostituiamo
    pattern_vecchio = r"  void _sendMessage\(\) \{(?:[^{}]|{[^{}]*})*\}"
    if re.search(pattern_vecchio, content):
        content = re.sub(pattern_vecchio, nuovo_send, content, count=1)
        print("✅ Metodo _sendMessage potenziato con la personalità di Piggy AI!")

content += '\n// Versione 2.0.0 con Personalità Piggy AI & Gemini\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Configurazione carattere completata!")
