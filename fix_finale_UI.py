import re

# 1. Alziamo la versione a +5 per l'OTA
with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    pubspec = f.read()
pubspec = re.sub(r'version: 1\.0\.0\+[0-9]+', 'version: 1.0.0+5', pubspec)
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(pubspec)

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 2. Forziamo il testo del login a un colore chiaro fisso
content = re.sub(
    r'(_isRegistrazione \? "Hai già un account\? Accedi" : "Non hai un account\? Registrati",\s*)style:\s*TextStyle\(color:\s*_subtitleColor\)',
    r'\1style: const TextStyle(color: Colors.white70)',
    content
)

# 3. Agganciamo i bottoni Info e OTA esattamente sotto alla Row dei Temi
match = re.search(r"(label:\s*const\s*Text\('Piggy White',\s*style:\s*TextStyle\(color:\s*Colors\.black87\)\),\s*\n\s*\),\s*\n\s*\]\,\s*\n\s*\),)", content)
if match and "Info & Crediti" not in content:
    bottoni = match.group(0) + """
                    const SizedBox(height: 16),
                    Divider(color: _textColor.withOpacity(0.2)),
                    ListTile(
                      leading: Icon(Icons.info_outline, color: _textColor.withOpacity(0.7)),
                      title: Text('Info & Crediti', style: TextStyle(color: _textColor)),
                      onTap: () => _mostraInfoApp(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.system_update, color: Colors.greenAccent),
                      title: Text('Cerca Aggiornamenti', style: TextStyle(color: _textColor)),
                      onTap: () => _verificaAggiornamentiOTA(context),
                    ),"""
    content = content[:match.start()] + bottoni + content[match.end():]
    print("✅ Bottoni Info e OTA inseriti al millimetro nel menù!")
else:
    print("⚠️ Struttura bottoni non trovata, ma testo login corretto.")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("✅ Testo Login sistemato e versione aggiornata a +5!")
