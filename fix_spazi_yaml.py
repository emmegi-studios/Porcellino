import re

with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

# Le dipendenze scritte con l'indentazione perfetta (2 spazi)
dipendenze = """
  firebase_messaging: ^14.7.10
  speech_to_text: ^6.5.1
  flutter_tts: ^3.8.3
  google_generative_ai: ^0.4.3"""

if 'google_generative_ai' not in content:
    # Agganciamo le dipendenze subito sotto cupertino_icons
    content = re.sub(r'(cupertino_icons:.*)', r'\1' + dipendenze, content)
    print("✅ Pacchetti inseriti nel file pubspec.yaml con spaziatura perfetta!")
else:
    print("⚠️ Pacchetti già presenti.")

with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(content)
