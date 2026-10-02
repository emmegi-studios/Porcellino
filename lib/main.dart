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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isLogin = true;
  String securityMessage = "";

  void _checkPasswordSecurity(String password) {
    if (password.length < 6) {
      setState(() => securityMessage = "⚠️ Sicurezza bassa: almeno 6 caratteri");
    } else if (!password.contains(RegExp(r'[0-9]')) || !password.contains(RegExp(r'[A-Z]'))) {
      setState(() => securityMessage = "🟡 Sicurezza media: inserisci maiuscola e numero");
    } else {
      setState(() => securityMessage = "🟢 Sicurezza ottima: password forte!");
    }
  }

  void _autentica() {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserisci un'email valida")));
      return;
    }
    if (pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserisci la password")));
      return;
    }
    if (!isLogin) {
      if (pass != confirmPass) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le password non coincidono!")));
        return;
      }
      if (pass.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La password deve essere di almeno 6 caratteri")));
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(userEmail: email)),
    );
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
                onChanged: (val) {
                  if (!isLogin) _checkPasswordSecurity(val);
                },
                decoration: InputDecoration(
                  labelText: "Password",
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              if (!isLogin) ...[
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerLeft, child: Text(securityMessage, style: const TextStyle(fontSize: 11, color: Colors.amber))),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Conferma Password",
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
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
                onPressed: () => setState(() {
                  isLogin = !isLogin;
                  securityMessage = "";
                }),
                child: Text(isLogin ? "Non hai un account? Registrati" : "Hai già un account? Accedi", style: const TextStyle(color: Color(0xFFF472B6))),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String userEmail;
  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSharedMode = false;
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
  final _inviteEmailController = TextEditingController();

  final _itemController = TextEditingController();
  final _monthlySaveController = TextEditingController();
  String aiPurchaseResult = "Inserisci un bene e l'accumulo mensile per calcolare il piano AI.";
  bool isAiLoading = false;

  // I livelli Road to 100k originali con icone e tappe mirate
  Map<String, dynamic> _getLivelloOriginale() {
    if (patrimonio < 1000) {
      return {"nome": "Fondo Cuscinetto", "target": "1.000€", "icon": "🛡️", "color": Colors.blueAccent};
    } else if (patrimonio < 10000) {
      return {"nome": "Risparmiatore Dinamico", "target": "10.000€", "icon": "📈", "color": Colors.orangeAccent};
    } else if (patrimonio < 35000) {
      return {"nome": "Investitore Strategico", "target": "35.000€", "icon": "💼", "color": Colors.purpleAccent};
    } else if (patrimonio < 70000) {
      return {"nome": "Maestro del Caveau", "target": "70.000€", "icon": "⚡", "color": const Color(0xFFDB2777)};
    } else if (patrimonio < 100000) {
      return {"nome": "Aspirante 100k", "target": "100.000€", "icon": "🚀", "color": Colors.amber};
    } else {
      return {"nome": "Custode dei 100k+", "target": "Traguardo Raggiunto", "icon": "🏆", "color": const Color(0xFF10B981)};
    }
  }

  double _getProgresso() => (patrimonio / 100000.0).clamp(0.0, 1.0);

  void _simulaAI(String oggetto, String risparmioStr) {
    if (oggetto.isEmpty) return;
    double risparmio = double.tryParse(risparmioStr.replaceAll(',', '.')) ?? 150.00;
    if (risparmio <= 0) risparmio = 150.00;

    setState(() => isAiLoading = true);
    
    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        isAiLoading = false;
        double stima = oggetto.toLowerCase().contains('auto') ? 7500.0 : 1000.0;
        int mesi = (stima / risparmio).ceil();
        aiPurchaseResult = "🤖 AI Plan per '$oggetto' (€$stima):\n• Accantonando €$risparmio/mese\n• Tempo stimato: ~$mesi mesi (${(mesi/12).toStringAsFixed(1)} anni).";
      });
    });
  }

  void _inviaInvito() {
    final email = _inviteEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserisci un'email valida")));
      return;
    }
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("📧 Invito Inviato!"),
        content: Text("Link di accesso sicuro inviato con successo a:\n\n👉 $email"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Ottimo", style: TextStyle(color: Color(0xFFDB2777))))],
      ),
    );
    _inviteEmailController.clear();
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

  @override
  Widget build(BuildContext context) {
    final livello = _getLivelloOriginale();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("🐷 Piggy Vault", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
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
          const SizedBox(height: 12),

          // SELETTORE PRIVATO / CONDIVISO
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isSharedMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: !isSharedMode ? const Color(0xFFDB2777) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text("🔒 Conto Privato", style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isSharedMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: isSharedMode ? const Color(0xFF3B82F6) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text("👥 Conto Condiviso", style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isSharedMode) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF0F172A),
                  title: const Text("👥 Invita Collaboratore"),
                  content: TextField(controller: _inviteEmailController, decoration: const InputDecoration(labelText: "Email collaboratore")),
                  actions: [TextButton(onPressed: _inviaInvito, child: const Text("Invia Email"))],
                ),
              ),
              icon: const Icon(Icons.email),
              label: const Text("Invia Invito Email a Collaboratore"),
            ),
          ],
          const SizedBox(height: 14),

          // PATRIMONIO E LIVELLO ORIGINALE CON ICONA ROAD TO 100K
          Card(
            color: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isSharedMode ? "PATRIMONIO CONDIVISO" : "PATRIMONIO PERSONALE", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("€ ${patrimonio.toStringAsFixed(2)}", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: livello['color'].withOpacity(0.4))),
                    child: Row(
                      children: [
                        Text(livello['icon'], style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(livello['nome'], style: TextStyle(fontSize: 12, color: livello['color'], fontWeight: FontWeight.bold)),
                          Text("Target: ${livello['target']}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ])),
                        Text("${(_getProgresso() * 100).toStringAsFixed(1)}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _getProgresso(), backgroundColor: const Color(0xFF1E293B), color: livello['color'], minHeight: 6),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // SIMULATORE AI
          Card(
            color: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🤖 Simulatore AI di Accumulo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(controller: _itemController, decoration: const InputDecoration(hintText: "Cosa vuoi comprare? (es. Scooter)")),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _monthlySaveController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Accantonamento €/mese"))),
                    const SizedBox(width: 8),
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777)), onPressed: () => _simulaAI(_itemController.text, _monthlySaveController.text), child: const Text("Calcola"))
                  ]),
                  const SizedBox(height: 8),
                  isAiLoading ? const CircularProgressIndicator() : Text(aiPurchaseResult, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // SALVADANAI OBIETTIVO UTENTE
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("🏦 Salvadanai Obiettivo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777)),
              onPressed: _mostraModalNuovoSalvadanaio,
              child: const Text("+ Nuovo"),
            )
          ]),
          ...salvadanai.map((p) => Card(color: const Color(0xFF0F172A), child: ListTile(title: Text(p['title']), subtitle: Text("€${p['current']} / €${p['target']}")))),
          const SizedBox(height: 14),

          // STORICO MOVIMENTI
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("📜 Storico Movimenti", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777)),
              onPressed: _mostraModalInserimento,
              child: const Text("+ Nuova"),
            )
          ]),
          ...transazioni.map((tx) => Card(
            color: const Color(0xFF0F172A),
            child: ListTile(
              title: Text(tx['category']),
              subtitle: Text(tx['note']),
              trailing: Text("${tx['type'] == 'entrata' ? '+' : '-'}€${tx['amount']}"),
            ),
          )),
        ],
      ),
    );
  }
}
