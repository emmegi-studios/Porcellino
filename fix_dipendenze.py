import re
import os

# 1. Puliamo eventuali inserimenti sporchi
with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r'\n\s*firebase_messaging:.*', '', content)
content = re.sub(r'\n\s*speech_to_text:.*', '', content)
content = re.sub(r'\n\s*flutter_tts:.*', '', content)

with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ File pubspec pulito, procedo con l'installazione nativa (potrebbe volerci 1 minuto)...")

# 2. Usiamo Flutter nativo per installare le dipendenze vocali, push e l'AI di Gemini!
os.system('flutter pub add firebase_messaging speech_to_text flutter_tts google_generative_ai')
