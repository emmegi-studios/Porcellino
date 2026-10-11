import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Testi Universali e pulizia
content = content.replace("Un caveau di coppia sicuro", "Un caveau sicuro e intelligente")
content = content.replace("• Online • Voce & Desideri", "• Online • AI Assistant")
content = content.replace(
    "Oink! Sono Piggy, il guardiano del caveau condiviso. Pronto a gestire le spese e i sogni di coppia!",
    "Oink! Sono Piggy, il tuo AI Advisor personale. Pronto a gestire le tue finanze e i tuoi sogni!"
)

# 2. Trasformazione del Cervello di Gemini (Rendiamolo VIVO)
vecchio_prompt_pattern = r"Content\.system\([^)]+\)"
nuovo_prompt = """Content.system("Sei Piggy, l'AI Advisor finanziario dell'app Piggy Vault. Non sei un robot freddo, ma un maialino saggio, ironico e brillante! Usa sempre un tono discorsivo, amichevole, fai battute sui risparmi, dai consigli reali e usa emoji 🐷💰. NON usare frasi preimpostate. Analizza ciò che dice l'utente, commentalo con il tuo stile inconfondibile, e comportati come un vero assistente vivo e super intelligente.")"""
if "Content.system(" in content:
    content = re.sub(vecchio_prompt_pattern, nuovo_prompt, content)

# 3. Avvisiamo che il vecchio box incastrato è disattivato (senza cancellarlo e rischiare bug)
content = content.replace("'Piggy AI Advisor'", "'Piggy AI (Spostato)'")
content = content.replace("'• Online • AI Assistant'", "'Usa l\'icona in basso a destra 👉'")

# 4. Creiamo la modale (BottomSheet) super elegante per la Chat
bottom_sheet_func = """
  void _mostraPiggyAI(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final _isDarkTheme = Theme.of(context).brightness == Brightness.dark;
        final _cardBg = _isDarkTheme ? const Color(0xFF1E2235) : Colors.white;
        final _textColor = _isDarkTheme ? Colors.white : Colors.black87;
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          ClipOval(child: Image.asset('assets/images/piggy_ai_assistant.png', width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.savings, color: Colors.pinkAccent))),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Piggy AI Advisor', style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                              const Text('• Online • Intelligenza Artificiale', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                            ],
                          ),
                          const Spacer(),
                          IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isUser = msg['sender'] == 'user';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.pinkAccent.withOpacity(0.2) : (_isDarkTheme ? const Color(0xFF2A2E45) : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isUser ? Colors.pinkAccent.withOpacity(0.5) : Colors.transparent),
                              ),
                              child: Text(msg['text'] ?? '', style: TextStyle(color: _textColor, fontSize: 15)),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(color: _textColor),
                              decoration: InputDecoration(
                                hintText: 'Chiedi a Piggy...',
                                hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                                filled: true,
                                fillColor: _isDarkTheme ? const Color(0xFF0F111A) : Colors.grey.shade100,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              onSubmitted: (_) { 
                                _sendMessage(); 
                                Future.delayed(const Duration(milliseconds: 500), () => setModalState((){}));
                                Future.delayed(const Duration(milliseconds: 2500), () => setModalState((){}));
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTapDown: (_) { _startListening(); setModalState((){}); },
                            onTapUp: (_) { _stopListening(); setModalState((){}); Future.delayed(const Duration(milliseconds: 2500), () => setModalState((){})); },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _isListening ? Colors.redAccent : Colors.pinkAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }
"""

# 5. Iniettiamo la modale nel codice
if "void _mostraPiggyAI" not in content:
    content = content.replace("  void _sendMessage()", bottom_sheet_func + "\n  void _sendMessage()")

# 6. Iniettiamo il Tasto Fluttuante (FAB) sulla schermata Home
fab_code = """
      floatingActionButton: FloatingActionButton(
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
      body: """
# Sostituzione chirurgica
if "floatingActionButton:" not in content:
    content = content.replace("      body: Center(", fab_code + "Center(")
    content = content.replace("body: Center(", fab_code + "Center(")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Piggy AI è stato trasformato in una VERA Intelligenza Artificiale fluttuante!")
