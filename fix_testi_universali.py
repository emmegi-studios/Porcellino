import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Rimuoviamo "Voce & Desideri"
content = content.replace("• Online • Voce & Desideri", "• Online • AI Assistant")
content = content.replace("• Voce & Desideri", "• AI Assistant")

# 2. Universalizziamo Info & Crediti
content = content.replace("Un caveau di coppia sicuro", "Un caveau sicuro")

# 3. Universalizziamo il messaggio di benvenuto nella UI
vecchio_benvenuto = "Oink! Sono Piggy, il guardiano del caveau condiviso. Pronto a gestire le spese e i sogni di coppia!"
nuovo_benvenuto = "Oink! Sono Piggy, il tuo AI Advisor. Pronto a gestire le tue finanze, le spese e i tuoi obiettivi!"
content = content.replace(vecchio_benvenuto, nuovo_benvenuto)

# 4. Universalizziamo il Prompt di Sistema di Gemini (se presente)
content = content.replace("caveau di coppia di Marco e Marika", "caveau")
content = content.replace("sogni di coppia", "obiettivi finanziari")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Testi aggiornati: Piggy è ora un'AI universale e 'Voce & Desideri' è stato rimosso!")
