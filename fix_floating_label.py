with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Sostituiamo la riga del labelStyle aggiungendo subito sotto il floatingLabelStyle
vecchia_riga = "labelStyle: TextStyle(color: _subtitleColor),"
nuova_riga = "labelStyle: TextStyle(color: _subtitleColor),\n                  floatingLabelStyle: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),"

content = content.replace(vecchia_riga, nuova_riga)

# Aggiungiamo il marcatore per forzare Git a registrare la modifica
content += '\n// Fix visibilità floating label Login v1.3.21\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Floating label colorate di rosa e rese visibili con successo!")
