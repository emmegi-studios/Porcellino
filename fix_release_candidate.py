import re

# 1. Alziamo la versione alla 1.4.0 (build +6 per l'OTA)
with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    pubspec = f.read()
pubspec = re.sub(r'version: 1\.0\.0\+[0-9]+', 'version: 1.4.0+6', pubspec)
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(pubspec)

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 2. Risolviamo il Memory Leak: Aggiungiamo il dispose() nel LoginScreen
login_dispose = """
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
"""

if '_emailController.dispose()' not in content:
    # Cerchiamo la dichiarazione della classe di stato del Login per inserirlo appena sotto
    content = re.sub(
        r'(class _LoginScreenState extends State<LoginScreen> \{)', 
        r'\1' + login_dispose, 
        content
    )
    print("✅ Memory Leak risolto: Controller del Login smontati correttamente!")
else:
    print("✅ Memory Leak già gestito.")

content += '\n// Release Definitiva v1.4.0: Fix Memory Leak\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Preparazione Release Definitiva v1.4.0 completata!")
