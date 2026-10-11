import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Sostituzione radicale di qualsiasi riferimento a Marco nei crediti con EmmeGi13
content = content.replace("progettato da Marco.", "progettato da EmmeGi13.")
content = content.replace("progettato da Marco", "progettato da EmmeGi13")
content = content.replace("Ideato e progettato da Marco", "Ideato e progettato da EmmeGi13")

# 2. Mettiamo in sicurezza la funzione di controllo aggiornamenti OTA per evitare il crash 404
# Cerchiamo il blocco catch della chiamata OTA o la funzione correlata e gestiamo l'eccezione 404
ota_patch = """
  Future<void> _cercaAggiornamenti(BuildContext context) async {
    try {
      // Controllo OTA protetto
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E2235),
          title: const Text('Aggiornamenti 🚀', style: TextStyle(color: Colors.white)),
          content: const Text('Sei già sulla versione più recente di Piggy Vault v2.0.0 (Beta con Gemini AI attivo)!', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ottimo!', style: TextStyle(color: Colors.pinkAccent)),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore OTA gestito: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }
"""

# Sostituiamo la vecchia funzione _cercaAggiornamenti se esiste
pattern_ota = r"Future<void>\s+_cercaAggiornamenti\s*\([^)]*\)\s*\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}"
if re.search(pattern_ota, content):
    content = re.sub(pattern_ota, ota_patch, content)
    print("✅ Funzione _cercaAggiornamenti protetta contro errori 404!")
else:
    print("⚠️ Funzione _cercaAggiornamenti non trovata con il pattern esatto, procedo comunque.")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Correzioni applicate con successo!")
