import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Correggiamo la firma in Info & Crediti da Marco a EmmeGi13
content = content.replace("Ideato e progettato da Marco.", "Ideato e progettato da EmmeGi13.")
content = content.replace("Ideato e progettato da Marco", "Ideato e progettato da EmmeGi13")

# 2. Ripristiniamo l'uso delle immagini PNG originali al posto dei placeholder rosa
# Sostituiamo i Container rosa del logo con il widget Image.asset corretto
vecchio_logo_pattern = r"Container\(\s*width:\s*40,\s*height:\s*40,\s*decoration:\s*BoxDecoration\(\s*color:\s*Colors\.pinkAccent,\s*borderRadius:\s*BorderRadius\.circular\(10\),\s*\),\s*\)"
nuovo_logo = "ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/logo.png', width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.pinkAccent)))"

if re.search(vecchio_logo_pattern, content):
    content = re.sub(vecchio_logo_pattern, nuovo_logo, content)
    print("✅ Logo PNG ripristinato con fallback di sicurezza!")
else:
    print("⚠️ Struttura logo già ottimizzata o differente.")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Firma aggiornata a EmmeGi13 e grafica sistemata!")
