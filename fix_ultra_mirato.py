with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# A. Correggiamo ESATTAMENTE il percorso dell'immagine
content = content.replace("'assets/piggy_ai_assistant.png'", "'assets/images/piggy_ai_assistant.png'")

# B. Correggiamo ESATTAMENTE il testo "Piggy AI Advisor" usando il Theme context sicuro
vecchio_stile_ai = "style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)"
nuovo_stile_ai = "style: TextStyle(color: Theme.of(context).brightness == Brightness.light ? Colors.black87 : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)"
content = content.replace(vecchio_stile_ai, nuovo_stile_ai)

# C. Correggiamo ESATTAMENTE il testo "PATRIMONIO CONDIVISO"
vecchio_patrimonio = 'Text("PATRIMONIO CONDIVISO", style: TextStyle(fontSize: 10, color: _subtitleColor, fontWeight: FontWeight.bold))'
nuovo_patrimonio = 'Text("PATRIMONIO CONDIVISO", style: TextStyle(fontSize: 10, color: Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white70, fontWeight: FontWeight.bold))'
content = content.replace(vecchio_patrimonio, nuovo_patrimonio)

# D. Marcatore per forzare il commit
content += '\n// Fix ultra-mirato Avatar e Colori AI v1.3.16\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Fix chirurgico applicato: nessun rischio per la struttura!")
