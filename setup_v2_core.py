import re
import os

# 1. Aggiungiamo i pacchetti in pubspec.yaml e alziamo la versione a 2.0.0+1
with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    pubspec = f.read()

deps = """
  firebase_messaging: ^14.7.10
  speech_to_text: ^6.5.1
  flutter_tts: ^3.8.3"""

if 'speech_to_text' not in pubspec:
    pubspec = re.sub(r'(cupertino_icons:.*)', r'\1' + deps, pubspec)
    pubspec = re.sub(r'version: .*', 'version: 2.0.0+1', pubspec)
    with open('pubspec.yaml', 'w', encoding='utf-8') as f:
        f.write(pubspec)

# 2. Aggiungiamo i permessi del Microfono e della Vibrazione per Android
manifest_path = 'android/app/src/main/AndroidManifest.xml'
if os.path.exists(manifest_path):
    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = f.read()
    
    perms = """
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.INTERNET"/>
    """
    if 'RECORD_AUDIO' not in manifest:
        manifest = manifest.replace('<application', perms + '<application')
        with open(manifest_path, 'w', encoding='utf-8') as f:
            f.write(manifest)

# 3. Inizializziamo FCM e Importiamo i moduli in main.dart
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if "import 'package:speech_to_text" not in content:
    imports = """import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
"""
    content = content.replace("import 'package:firebase_core/firebase_core.dart';", "import 'package:firebase_core/firebase_core.dart';\n" + imports)

init_fcm = """
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  } catch(e) {
    print("Errore init notifiche: $e");
  }
"""

if 'messaging.requestPermission' not in content:
    content = re.sub(r'(await Firebase\.initializeApp\([^)]*\);)', r'\1\n' + init_fcm, content)

content += '\n// Setup V2.0: Fondamenta Motore Push, STT e TTS inserite\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Setup V2.0 completato: Pacchetti, Permessi e FCM pronti!")
