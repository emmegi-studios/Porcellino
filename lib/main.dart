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
      home: const LoginScreen(),
    );
  }
}

// 1. AUTENTICAZIONE VIA EMAIL
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;

  void _autentica() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty && email.contains('@')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(userEmail: email)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inserisci un'email valida per accedere")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("🐷", style: TextStyle(fontSize: 60)),
              const SizedBox(height: 12),
              const Text("Piggy Vault", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              const Text("Il tuo caveau finanziario intelligente", style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 36),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB2777),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _autentica,
                child: Text(isLogin ? "Accedi al Caveau" : "Registrati", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? "Non hai un account? Registrati" : "Hai già un account? Accedi", style: const TextStyle(color: Color(0xFFF472B6))),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// 2. SCHERMATA PRINCIPALE DINAMICA E PERSONALIZZABILE
class HomeScreen extends StatefulWidget {
  final String userEmail;
  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSharedMode = false; // False = Privato, True = Condiviso

  double patrimonio = 0.00;
  double entrateMese = 0.00;
  double usciteMese = 0.00;

  List<Map<String, dynamic>> transazioni = [];
  List<Map<String, dynamic>> salvadanai = [];

  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'entrata';

  final _piggyTitleController = TextEditingController();
  final _piggyTargetController = TextEditingController();

  final _itemController = TextEditingController();
  final _monthlySaveController = TextEditingController();
  String aiPurchaseResult = "Inserisci un bene e l'accumulo mensile previsto per calcolare il piano dell'AI.";
  bool isAiLoading = false;

  String _getLivelloPatrimonio() {
    if (patrimonio < 5000) return "Livello 1: Risparmiatore Novizio (Meta: 5.000€)";
    if (patrimonio < 25000) return "Livello 2: Accumulatore Dinamico (Meta: 25.000€)";
    if (patrimonio < 60000) return "Livello 3: Investitore Strategico (Meta: 60.000€)";
    if (patrimonio < 100000) return "Livello 4: Maestro del Caveau (Meta: 100.000€)";
    return "🏆 Livello Max: Custode del Caveau dei 100k+!";
  }

  void _simulaAccumuloAI(String oggetto, String risparmioMensileStr) {
    if (oggetto.isEmpty) return;
    double risparmioMensile = double.tryParse(risparmioMensileStr.replaceAll(',', '.')) ?? 150.00;
    if (risparmioMensile <= 0) risparmioMensile = 150.00;

    setState(() => isAiLoading = true);
    
    Future.delayed(const Duration(milliseconds: 900), () {
      setState(() {
        isAiLoading = false;
        double costoStimato = 1000.00;
        String oggLower = oggetto.toLowerCase();
        if (oggLower.contains('auto') || oggLower.contains('macchina') || oggLower.contains('moto')) costoStimato = 7500.00;
        if (oggLower.contains('telefono') || oggLower.contains('smartphone') || oggLower.contains('console')) costoStimato = 650.00;
        if (oggLower.contains('casa') || oggLower.contains('ristrutturazione')) costoStimato = 20000.00;

        int mesiNecessari = (costoStimato / risparmioMensile).ceil();

        aiPurchaseResult = "🤖 Analisi AI per '$oggetto' (Stima: €${costoStimato.toStringAsFixed(0)}):\n\n"
            "• 💰 Accantonando €${risparmioMensile.toStringAsFixed(0)} al mese:\n"
            "• ⏳ Tempo stimato: Circa $mesiNecessari mesi (${(mesiNecessari / 12).toStringAsFixed(1)} anni).\n"
            "• 💡 Obiettivo tracciabile nel tuo salvadanaio personalizzato!";
      });
    });
  }

  void _mostraModalNuovoSalvadanaio() {
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
              const Text("🏦 Nuovo Salvadanaio Obiettivo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              TextField(
                controller: _piggyTitleController,
                decoration: InputDecoration(labelText: "Nome Obiettivo (es. Viaggio, Auto)", filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _piggyTargetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Importo Target (€)", filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  final title = _piggyTitleController.text.trim();
                  final target = double.tryParse(_piggyTargetController.text.trim().replaceAll(',', '.')) ?? 0.0;
                  if (title.isNotEmpty && target > 0) {
                    setState(() {
                      salvadanai.add({"title": title, "current": 0.0, "target": target});
                    });
                    _piggyTitleController.clear();
                    _piggyTargetController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Crea Salvadanaio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
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
                onChanged: (val) => setState(() => _selectedType = val ?? 'entrata'),
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

  void _mostraInvitoCondiviso() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("👥 Gestione Conto Condiviso", style: TextStyle(color: Colors.white)),
        content: const Text("Invita un partner a gestire questo caveau condiviso.\n\nLink di invito generato:\n👉 piggyvault.app/join?invite=shared_vault_secure", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Chiudi", style: TextStyle(color: Color(0xFFDB2777))),
          )
        ],
      ),
    );
  }

  void _mostraFoglioResoconto() {
    double bilancioNetto = entrateMese - usciteMese;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                      const Text("RIEPILOGO BILANCIO", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
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
              const Text("Dettaglio Movimenti", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Row(
          children: [
            const Text("🐷 ", style: TextStyle(fontSize: 20)),
            Text(isSharedMode ? "Piggy Vault [Condiviso]" : "Piggy Vault [Privato]", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isSharedMode ? Icons.group : Icons.lock, color: isSharedMode ? const Color(0xFF3B82F6) : const Color(0xFF10B981)),
            tooltip: isSharedMode ? "Passa a Privato" : "Passa a Condiviso",
            onPressed: () {
              setState(() {
                isSharedMode = !isSharedMode;
              });
            },
          ),
          if (isSharedMode)
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white70),
              tooltip: "Invita utente",
              onPressed: _mostraInvitoCondiviso,
            ),
          IconButton(
            icon: const Icon(Icons.description, color: Color(0xFFF472B6)),
            tooltip: "Foglio Resoconto",
            onPressed: _mostraFoglioResoconto,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text("Utente loggato: ${widget.userEmail}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 10),

          // 1. Patrimonio e Livelli verso i 100k
          Card(
            color: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isSharedMode ? "PATRIMONIO GRUPPO / FAMIGLIA" : "PATRIMONIO PERSONALE", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("€ ${patrimonio.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                    child: Text(_getLivelloPatrimonio(), style: const TextStyle(fontSize: 11, color: Color(0xFFF472B6), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. SIMULATORE AI: ACCUMULO INTELLIGENTE
          const Text("🤖 SIMULATORE AI: PIANO DI ACCUMULO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Cosa desideri acquistare?", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      hintText: "es. Scooter, TV OLED, Viaggio",
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Quanto puoi accantonare al mese? (€)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _monthlySaveController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: "es. 150",
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777)),
                        onPressed: () => _simulaAccumuloAI(_itemController.text.trim(), _monthlySaveController.text.trim()),
                        child: const Text("Calcola AI", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  isAiLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Color(0xFFDB2777))))
                      : Text(aiPurchaseResult, style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. SALVADANAI GESTITI DALL'UTENTE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("🏦 SALVADANAI E OBIETTIVI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB2777),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _mostraModalNuovoSalvadanaio,
                icon: const Icon(Icons.add, size: 14, color: Colors.white),
                label: const Text("Nuovo", style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          salvadanai.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("Nessun salvadanaio creato. Clicca su 'Nuovo' per impostare il tuo primo obiettivo di risparmio!", style: TextStyle(fontSize: 12, color: Colors.grey)),
                )
              : Column(
                  children: salvadanai.map((piggy) {
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
                  }).toList(),
                ),
          const SizedBox(height: 20),

          // 4. STORICO TRANSAZIONI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("📜 STORICO MOVIMENTI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
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
          transazioni.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("Nessuna transazione registrata. Aggiungi entrate o uscite per popolare il caveau.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                )
              : Column(
                  children: transazioni.map((tx) => Card(
                        color: const Color(0xFF0F172A),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          title: Text(tx['category'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(tx['note']),
                          trailing: Text(
                            "${tx['type'] == 'entrata' ? '+' : '-'}€ ${tx['amount'].toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: tx['type'] == 'entrata' ? const Color(0xFF10B981) : const Color(0xFFDB2777),
                            ),
                          ),
                        ),
                      )).toList(),
                ),
        ],
      ),
    );
  }
}
