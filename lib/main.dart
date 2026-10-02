import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PiggyVaultApp());
}

class PiggyVaultApp extends StatelessWidget {
  const PiggyVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piggy Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617),
        primaryColor: const Color(0xFFDB2777),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double patrimonio = 1250.00;
  double entrateMese = 2000.00;
  double usciteMese = 750.00;

  List<Map<String, dynamic>> transazioni = [
    {"category": "Stipendio", "note": "Acconto", "amount": 2000.00, "type": "entrata"},
    {"category": "Spesa", "note": "Supermercato", "amount": 120.00, "type": "uscita"},
    {"category": "Bollette", "note": "Luce e Gas", "amount": 130.00, "type": "uscita"},
  ];

  List<Map<String, dynamic>> salvadanai = [
    {"title": "Vacanza Estiva", "current": 450.00, "target": 1000.00},
    {"title": "Nuova Auto", "current": 800.00, "target": 5000.00},
  ];

  String aiResponse = "Ciao! Sono il tuo assistente AI di Piggy Vault. Analizzo le tue spese per aiutarti a risparmiare.";
  bool isAiLoading = false;

  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'uscita';

  void _askAi(String tipoAnalisi) {
    setState(() => isAiLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        isAiLoading = false;
        if (tipoAnalisi == "consigli") {
          double tassoRisparmio = ((entrateMese - usciteMese) / entrateMese) * 100;
          aiResponse = "💡 Risparmio stimato al ${tassoRisparmio.toStringAsFixed(0)}% questo mese. Ottimo lavoro!";
        } else {
          aiResponse = "📊 Analisi completata: Le uscite principali riguardano spesa e utenze.";
        }
      });
    });
  }

  // Modale per generare il Foglio di Resoconto Mensile
  void _mostraFoglioResoconto() {
    double bilancioNetto = entrateMese - usciteMese;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("📋 Foglio Resoconto Mensile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Icon(Icons.description, color: Color(0xFFDB2777)),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF1E293B),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("RIEPILOGO ATTUALE", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Entrate Totali:"), Text("€ ${entrateMese.toStringAsFixed(2)}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Uscite Totali:"), Text("€ ${usciteMese.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFDB2777), fontWeight: FontWeight.bold))]),
                      const Divider(color: Colors.grey),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Bilancio Netto:"), Text("€ ${bilancioNetto.toStringAsFixed(2)}", style: TextStyle(color: bilancioNetto >= 0 ? const Color(0xFF10B981) : const Color(0xFFDB2777), fontWeight: FontWeight.bold))]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Dettaglio Movimenti del Mese", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: transazioni.length,
                  itemBuilder: (context, index) {
                    final tx = transazioni[index];
                    return ListTile(
                      dense: true,
                      title: Text(tx['category'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(tx['note']),
                      trailing: Text(
                        "${tx['type'] == 'entrata' ? '+' : '-'}€ ${tx['amount'].toStringAsFixed(2)}",
                        style: TextStyle(color: tx['type'] == 'entrata' ? const Color(0xFF10B981) : const Color(0xFFDB2777), fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.pop(context),
                child: const Text("Chiudi Resoconto", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      },
    );
  }

  void _mostraModalInserimento() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20, right: 20, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("➕ Aggiungi Movimento", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              TextField(controller: _categoryController, decoration: InputDecoration(labelText: "Categoria", filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _noteController, decoration: InputDecoration(labelText: "Nota", filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: "Importo (€)", filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: const Color(0xFF1E293B),
                decoration: InputDecoration(filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: const [
                  DropdownMenuItem(value: 'entrata', child: Text("🟢 Entrata (+)")),
                  DropdownMenuItem(value: 'uscita', child: Text("🔴 Uscita (-)")),
                ],
                onChanged: (val) => setState(() => _selectedType = val ?? 'uscita'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  final cat = _categoryController.text.trim();
                  final note = _noteController.text.trim();
                  final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0.0;

                  if (cat.isNotEmpty && amount > 0) {
                    setState(() {
                      transazioni.insert(0, {"category": cat, "note": note.isEmpty ? cat : note, "amount": amount, "type": _selectedType});
                      if (_selectedType == 'entrata') {
                        patrimonio += amount;
                        entrateMese += amount;
                      } else {
                        patrimonio -= amount;
                        usciteMese += amount;
                      }
                    });
                    _categoryController.clear();
                    _noteController.clear();
                    _amountController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Registra Movimento", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Row(
          children: [
            Text("🐷 ", style: TextStyle(fontSize: 22)),
            Text("Piggy Vault", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description, color: Color(0xFFF472B6)),
            tooltip: "Foglio Resoconto",
            onPressed: _mostraFoglioResoconto,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Patrimonio Totale
          Card(
            color: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PATRIMONIO TOTALE", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("€ ${patrimonio.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // 2. Entrate e Uscite del Mese
          Row(
            children: [
              Expanded(
                child: Card(
                  color: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ENTRATE MESE", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("€ ${entrateMese.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  color: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("USCITE MESE", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("€ ${usciteMese.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFDB2777))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Bottone rapido Foglio Resoconto Mensile
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _mostraFoglioResoconto,
            icon: const Icon(Icons.assessment, color: Color(0xFFF472B6)),
            label: const Text("Genera Foglio Resoconto Mensile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),

          // 4. Grafico a Torta / Ripartizione Categorie
          const Text("🍰 RIPARTIZIONE SPESE (GRAFICO A FETTA)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(children: [Icon(Icons.circle, size: 10, color: Color(0xFFDB2777)), SizedBox(width: 6), Text("Spesa (48%)", style: TextStyle(fontSize: 12, color: Colors.white70))]),
                      Row(children: [Icon(Icons.circle, size: 10, color: Color(0xFF3B82F6)), SizedBox(width: 6), Text("Bollette (52%)", style: TextStyle(fontSize: 12, color: Colors.white70))]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      value: 0.48,
                      backgroundColor: Color(0xFF3B82F6),
                      color: Color(0xFFDB2777),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 5. Assistente AI
          const Text("🤖 ASSISTENTE FINANZIARIO AI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFFF472B6), size: 20),
                      SizedBox(width: 8),
                      Text("Piggy AI Advisor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  isAiLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Color(0xFFDB2777))))
                      : Text(aiResponse, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.3)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                        onPressed: () => _askAi("consigli"),
                        child: const Text("💡 Consigli", style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                        onPressed: () => _askAi("spese"),
                        child: const Text("📊 Analisi Spese", style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 6. Salvadanai
          const Text("🏦 SALVADANAI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          ...salvadanai.map((piggy) {
            double progress = (piggy['current'] / piggy['target']).clamp(0.0, 1.0);
            return Card(
              color: const Color(0xFF0F172A),
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(piggy['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("€ ${piggy['current']} / € ${piggy['target']}", style: const TextStyle(fontSize: 12, color: Color(0xFFF472B6))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFF1E293B),
                        color: const Color(0xFFDB2777),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

          // 7. Storico Transazioni
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("📜 STORICO TRANSAZIONI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB2777),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _mostraModalInserimento,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text("Nuova", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...transazioni.map((tx) => Card(
                color: const Color(0xFF0F172A),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  title: Text(tx['category'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(tx['note'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Text(
                    "${tx['type'] == 'entrata' ? '+' : '-'}€ ${tx['amount'].toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: tx['type'] == 'entrata' ? const Color(0xFF10B981) : const Color(0xFFDB2777),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
