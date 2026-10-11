with open('lib/main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Stampiamo le righe intorno al login logo per vederle chiaramente
for i in range(195, min(225, len(lines))):
    print(f"{i+1}: {lines[i].strip()}")

