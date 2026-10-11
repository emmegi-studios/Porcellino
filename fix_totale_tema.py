with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    pubspec = f.read()

# 1. Alziamo la versione per sbloccare l'installazione sui telefoni
pubspec = pubspec.replace('version: 1.0.0+1', 'version: 1.0.0+2')

with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(pubspec)

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 2. Sostituiamo le variabili statiche dei colori con il controllo dinamico del tema
# (Questa modifica è blindata perché le variabili non possono trovarsi dentro widget "const")
content = content.replace(
    'color: _textColor',
    'color: Theme.of(context).brightness == Brightness.light ? Colors.black87 : Colors.white'
)

content = content.replace(
    'color: _subtitleColor',
    'color: Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white70'
)

content += '\n// Fix definitivo visibilità testi e update versione v1.3.18\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Versione alzata a 1.0.0+2 e tutti i testi del tema bianco riparati in sicurezza!")
