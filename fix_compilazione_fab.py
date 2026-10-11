import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Correggiamo l'apostrofo che ha "rotto" la stringa (usiamo i doppi apici di contenimento)
content = content.replace("'Usa l'icona in basso a destra 👉'", '"Usa l\'icona in basso a destra 👉"')

# 2. Rimuoviamo TUTTI i FAB inseriti per errore nel file (es. nella schermata di Login)
# L'espressione regolare intercetta l'esatto blocco del bottone e lo riporta allo stato originale
content = re.sub(
    r"([ \t]*)floatingActionButton:\s*FloatingActionButton\([\s\S]*?_mostraPiggyAI[\s\S]*?size:\s*28\),\s*\),\s*\),\s*\),\s*body:", 
    r"\1body:", 
    content
)

# 3. Inseriamo il FAB in modo mirato SOLAMENTE all'interno del Scaffold della _HomeScreenState
idx_home = content.find("class _HomeScreenState")
if idx_home != -1:
    idx_build = content.find("Widget build(BuildContext context)", idx_home)
    idx_body = content.find("body:", idx_build)
    
    # Verifichiamo che esista un body e applichiamo l'iniezione
    if idx_body != -1:
        good_fab = """floatingActionButton: FloatingActionButton(
        onPressed: () => _mostraPiggyAI(context),
        backgroundColor: Colors.pinkAccent,
        elevation: 6,
        child: ClipOval(
          child: Image.asset(
            'assets/images/piggy_ai_assistant.png',
            width: 48, height: 48, fit: BoxFit.cover,
            errorBuilder: (c, e, s) => const Icon(Icons.savings, color: Colors.white, size: 28),
          ),
        ),
      ),
      body:"""
        # Sostituiamo il "body:" trovato con il nuovo blocco "FloatingActionButton + body:"
        content = content[:idx_body] + good_fab + content[idx_body+5:]

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Errori di sintassi e posizionamento FAB risolti con precisione millimetrica!")
