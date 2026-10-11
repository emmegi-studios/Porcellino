import re

# 1. Alziamo la versione per fluidificare i prossimi aggiornamenti OTA
with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    pubspec = f.read()
pubspec = re.sub(r'version: 1\.0\.0\+[0-9]+', 'version: 1.0.0+4', pubspec)
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(pubspec)

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 2. Correggiamo i getter nella HomeScreen (righe 597-598)
content = re.sub(
    r'Color\s+get\s+_textColor\s*=>\s*[^;]+;',
    "Color get _textColor => _currentTheme == 'Piggy White' ? Colors.black87 : Colors.white;",
    content
)
content = re.sub(
    r'Color\s+get\s+_subtitleColor\s*=>\s*[^;]+;',
    "Color get _subtitleColor => _currentTheme == 'Piggy White' ? Colors.black54 : Colors.grey.shade400;",
    content
)

# 3. Correggiamo il colore sottotitolo hardcoded nella LoginScreen (riga 180)
content = content.replace(
    "final _subtitleColor = Colors.grey.shade400;",
    "final _subtitleColor = _isDarkTheme ? Colors.grey.shade400 : Colors.black54;"
)

content += '\n// Fix definitivo Colori Getters Tema Bianco v1.3.20\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Getters dei colori aggiornati con successo e versione passata a +4!")
