import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Correggiamo il percorso dell'immagine dell'AI
content = content.replace("'assets/piggy_ai_assistant.png'", "'assets/images/piggy_ai_assistant.png'")

# 2. Rendiamo dinamici i titoli hardcoded (come "Piggy AI Advisor" e altri titoli in grassetto)
content = re.sub(
    r"style:\s*TextStyle\(color:\s*Colors\.white,\s*fontWeight:\s*FontWeight\.bold",
    r"style: TextStyle(color: _currentTheme == 'Piggy White' ? Colors.black87 : Colors.white, fontWeight: FontWeight.bold",
    content
)
content = re.sub(
    r"style:\s*const\s*TextStyle\(color:\s*Colors\.white,\s*fontWeight:\s*FontWeight\.bold",
    r"style: TextStyle(color: _currentTheme == 'Piggy White' ? Colors.black87 : Colors.white, fontWeight: FontWeight.bold",
    content
)

# 3. Rendiamo dinamico il _subtitleColor per il Patrimonio Condiviso e le altre label
content = content.replace("color: _subtitleColor", "color: _currentTheme == 'Piggy White' ? Colors.black54 : Colors.white70")

# 4. Aggiungiamo un commento per il commit
content += '\n// Fix UI: Path Immagine AI e Colori Tema Bianco v1.3.15\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Avatar AI e Colori Tema Bianco riparati chirurgicamente!")
