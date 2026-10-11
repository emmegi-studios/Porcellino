import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Rendiamo il TextField reattivo così l'icona cambia quando scrivi
if "onChanged: (val) => setState(() {})," not in content:
    content = content.replace(
        "controller: _messageController,",
        "controller: _messageController,\n                    onChanged: (val) => setState(() {}),"
    )

# 2. Pattern per trovare l'esatto blocco del vecchio pulsante Send
pattern = r"Container\(\s*decoration:\s*const\s*BoxDecoration\(\s*color:\s*Colors\.pinkAccent,\s*shape:\s*BoxShape\.circle,\s*\),\s*child:\s*IconButton\(\s*icon:\s*const\s*Icon\(Icons\.send,\s*size:\s*20,\s*color:\s*Colors\.white\),\s*onPressed:\s*_sendMessage,\s*\),\s*\)"

nuovo_tasto = """GestureDetector(
                  onLongPressStart: (_) => _startListening(),
                  onLongPressEnd: (_) => _stopListening(),
                  onTap: () {
                    if (_messageController.text.isNotEmpty) {
                      _sendMessage();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tieni premuto per parlare! 🎙️')));
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.redAccent : Colors.pinkAccent,
                      shape: BoxShape.circle,
                      boxShadow: _isListening 
                          ? [BoxShadow(color: Colors.redAccent.withOpacity(0.6), blurRadius: 10, spreadRadius: 3)] 
                          : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : (_messageController.text.isEmpty ? Icons.mic_none : Icons.send),
                      size: 20, 
                      color: Colors.white
                    ),
                  ),
                )"""

if "onLongPressStart" not in content:
    content = re.sub(pattern, nuovo_tasto, content)
    print("✅ Grafica Push-to-Talk Walkie-Talkie iniettata con successo!")
else:
    print("⚠️ Interfaccia vocale già presente!")

content += '\n// Fix v2.0-beta.3: Grafica e animazioni pulsante Walkie-Talkie\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
