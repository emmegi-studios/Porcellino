import yaml

# Leggi pubspec.yaml
with open('pubspec.yaml', 'r') as f:
    lines = f.readlines()

# Controlla se c'è già la configurazione flutter_icons
content = "".join(lines)
if "flutter_icons:" not in content:
    # Aggiungi la configurazione alla fine
    with open('pubspec.yaml', 'a') as f:
        f.write("\nflutter_icons:\n  image_path: \"assets/icon/icona_esterna.png\"\n  android: true\n  ios: true\n")
print("Configurazione aggiunta con successo!")
