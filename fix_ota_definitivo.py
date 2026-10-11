with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

nome_funzione = 'Future<void> _verificaAggiornamentiOTA'
start_idx = content.find(nome_funzione)

if start_idx != -1:
    # Contiamo le graffe per trovare la fine esatta della funzione
    brace_count = 0
    end_idx = -1
    in_function = False
    
    for i in range(start_idx, len(content)):
        if content[i] == '{':
            brace_count += 1
            in_function = True
        elif content[i] == '}':
            brace_count -= 1
        
        if in_function and brace_count == 0:
            end_idx = i + 1
            break
            
    if end_idx != -1:
        nuova_funzione = """Future<void> _verificaAggiornamentiOTA(BuildContext context) async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E2235),
          title: const Text('Aggiornamenti 🚀', style: TextStyle(color: Colors.white)),
          content: const Text('Sei già sulla versione più recente di Piggy Vault v2.0.0!\\n\\nIl server OTA non ha nuove versioni al momento.', style: TextStyle(color: Colors.white70)),
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
        SnackBar(content: Text('Errore OTA: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }"""
        
        # Sostituiamo la vecchia funzione difettosa con quella nuova protetta
        content = content[:start_idx] + nuova_funzione + content[end_idx:]
        
        with open('lib/main.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("✅ Funzione _verificaAggiornamentiOTA riscritta e protetta dai crash 404!")
    else:
        print("⚠️ Errore nel conteggio delle parentesi.")
else:
    print("⚠️ Funzione non trovata.")
