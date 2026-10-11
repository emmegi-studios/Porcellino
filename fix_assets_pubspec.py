with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

# Aggiungiamo le sottocartelle degli asset se mancano
if "assets/icon/" not in content:
    content = content.replace(
        "  assets:\n    - assets/",
        "  assets:\n    - assets/\n    - assets/icon/\n    - assets/images/"
    )
    with open('pubspec.yaml', 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ Sottocartelle asset (icon e images) aggiunte correttamente a pubspec.yaml!")
else:
    print("⚠️ Sottocartelle già presenti.")
