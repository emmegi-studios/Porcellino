import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Troviamo il blocco esatto delle due funzioni (Info e OTA)
pattern = r"(  Future<void> _mostraInfoApp.*?Errore OTA: ' \+ e\.toString\(\)\)\)\);\n\s*\})"
match = re.search(pattern, content, re.DOTALL)

if match:
    metodi_estratti = match.group(1)
    
    # 2. Li cancelliamo da dove si trovano ora (nel posto sbagliato)
    content = content.replace(metodi_estratti, "")
    
    # 3. Li iniettiamo subito dopo l'apertura della classe _HomeScreenState
    content = re.sub(
        r'(class _HomeScreenState extends State<HomeScreen>.*?\{)',
        r'\1\n' + metodi_estratti,
        content
    )
    print("✅ Chirurgia riuscita: Metodi spostati in _HomeScreenState!")
else:
    print("⚠️ Attenzione: Metodi non trovati. Controlla il file lib/main.dart")

# Aggiungiamo un piccolo commento per marcare il commit
content += '\n// Fix: Spostamento metodi OTA in HomeScreen\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
