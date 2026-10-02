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
      title: 'Porcellino',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
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
      setState(() => securityMessage = "🟢 Password forte!");
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
              const Text("Porcellino", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              const Text("PRE-ALPHA V1.0", style: TextStyle(fontSize: 11, color: Color(0xFFF472B6), fontWeight: FontWeight.bold)),
              const SizedBox(height: 36),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  fillColor: const Color(0xFF131B2E),
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
                  fillColor: const Color(0xFF131B2E),
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
                    fillColor: const Color(0xFF131B2E),
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
                child: Text(isLogin ? "Accedi a Porcellino" : "Registrati", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  // Categorie con le emoji ufficiali di Porcellino
  final List<String> categorieConEmoji = [
    '🛒 Spesa / Alimentari',
    '🏠 Bollette & Casa',
    '🚗 Auto & Trasporti',
    '🐾 Animali / Pet Care',
    '🍕 Svago & Ristoranti',
    '💼 Stipendio / Entrata',
    '📦 Altro'
  ];
  String _selectedCategory = '🛒 Spesa / Alimentari';

  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'Uscita (Spesa)';

  final _piggyTitleController = TextEditingController();
  final _piggyTargetController = TextEditingController();
  final _inviteEmailController = TextEditingController();

  final _itemController = TextEditingController();
  final _monthlySaveController = TextEditingController();
  String aiPurchaseResult = "Inserisci le tue prime entrate e uscite per sbloccare i consigli personalizzati dell'IA.";
  bool isAiLoading = false;

  // Le 4 tappe originali di Porcellino Road to 100k
  Map<String, dynamic> _getLivelloPorcellino() {
    if (patrimonio < 1000) {
      return {"nome": "Emergenze", "target": "1.000€", "icon": "🟢", "color": Colors.greenAccent};
    } else if (patrimonio < 10000) {
      return {"nome": "Cuscino", "target": "10.000€", "icon": "🛡️", "color": Colors.blueAccent};
    } else if (patrimonio < 50000) {
      return {"nome": "Fortezza", "target": "50.000€", "icon": "🏰", "color": Colors.purpleAccent};
    } else {
      return {"nome": "Porcellone", "target": "100.000€", "icon": "👑", "color": Color(0xFFDB2777)};
    }
  }

  double _getProgresso() => (patrimonio / 100000.0).clamp(0.0, 1.0);

  void _simulaAI(String spesaStr) {
    if (spesaStr.isEmpty) return;
    double valore = double.tryParse(spesaStr.replaceAll(',', '.')) ?? 0.0;
    setState(() => isAiLoading = true);
    
    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        isAiLoading = false;
        double impatto = patrimonio > 0 ? (valore / patrimonio) * 100 : 0;
        aiPurchaseResult = "🤖 Consulente IA:\nUna spesa di €$valore impatta sul tuo patrimonio per il ${impatto.toStringAsFixed(1)}%. Gestiscila con prudenza!";
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
        backgroundColor: const Color(0xFF131B2E),
        title: const Text("📧 Invito Inviato!"),
        content: Text("Link sicuro per il conto condiviso inviato con successo a:\n\n👉 $email"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Ottimo", style: TextStyle(color: Color(0xFFDB2777))))],
      ),
    );
    _inviteEmailController.clear();
  }

  void _mostraModalNuovoSalvadanaio() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131B2E),
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
                decoration: InputDecoration(labelText: "Nome Obiettivo", filled: true, fillColor: const Color(0xFF0B0F19), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _piggyTargetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Importo Target (€)", filled: true, fillColor: const Color(0xFF0B0F19), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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

  void _mostraFoglioResoconto() {
    double bilancioNetto = entrateMese - usciteMese;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131B2E),
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
                color: const Color(0xFF0B0F19),
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
                        "${tx['type'].contains('Entrata') ? '+' : '-'}€ ${tx['amount'].toStringAsFixed(2)}",
                        style: TextStyle(color: tx['type'].contains('Entrata') ? const Color(0xFF10B981) : const Color(0xFFDB2777), fontWeight: FontWeight.bold),
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
      backgroundColor: const Color(0xFF131B2E),
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
              const Text("➕ Nuova Transazione", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: const Color(0xFF0B0F19),
                decoration: InputDecoration(labelText: "Tipo", filled: true, fillColor: const Color(0xFF0B0F19), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: const [
                  DropdownMenuItem(value: 'Uscita (Spesa)', child: Text("🔴 Uscita (Spesa)")),
                  DropdownMenuItem(value: 'Entrata (Guadagno)', child: Text("🟢 Entrata (Guadagno)")),
                ],
                onChanged: (val) => setState(() => _selectedType = val ?? 'Uscita (Spesa)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Importo (€)", filled: true, fillColor: const Color(0xFF0B0F19), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF0B0F19),
                decoration: InputDecoration(labelText: "Categoria", filled: true, fillColor: const Color(0xFF0B0F19), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: categorieConEmoji.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val ?? '📦 Altro'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(labelText: "Note / Descrizione", filled: true, fillColor: const Color(0xFF0B0F19), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  final note = _noteController.text.trim();
                  final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0.0;

                  if (amount > 0) {
                    setState(() {
                      transazioni.insert(0, {"category": _selectedCategory, "note": note.isEmpty ? _selectedCategory : note, "amount": amount, "type": _selectedType});
                      if (_selectedType.contains('Entrata')) {
                        patrimonio += amount;
                        entrateMese += amount;
                      } else {
                        patrimonio -= amount;
                        usciteMese += amount;
                      }
                    });
                    _noteController.clear();
                    _amountController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Registra Transazione", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final livello = _getLivelloPorcellino();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: Row(
          children: [
            const Text("🐷 ", style: TextStyle(fontSize: 20)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Porcellino", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text("PRE-ALPHA V1.0", style: TextStyle(fontSize: 9, color: Color(0xFFF472B6))),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF131B2E), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.person, size: 14, color: Color(0xFFF472B6)),
                const SizedBox(width: 4),
                Text("Marco", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
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
          // SELETTORE PRIVATO / CONDIVISO
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF131B2E), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isSharedMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: !isSharedMode ? const Color(0xFFDB2777) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text("🔒 Conto Privato", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isSharedMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: isSharedMode ? const Color(0xFF3B82F6) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text("👥 Conto Condiviso", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
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
                  backgroundColor: const Color(0xFF131B2E),
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

          // 1. PATRIMONIO TOTALE
          Card(
            color: const Color(0xFF131B2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("PATRIMONIO TOTALE", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("€ ${patrimonio.toStringAsFixed(2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                  const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981), size: 32),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ENTRATE E USCITE MESE
          Row(
            children: [
              Expanded(
                child: Card(
                  color: const Color(0xFF131B2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ENTRATE MESE", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("€ ${entrateMese.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  color: const Color(0xFF131B2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("USCITE MESE", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("€ ${usciteMese.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFDB2777)),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. LIVELLI PORCELLINO RISPARMIO (4 TAPPE)
          Card(
            color: const Color(0xFF131B2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("🏆 Livelli Porcellino Risparmio", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF0B0F19), borderRadius: BorderRadius.circular(12)),
                        child: Text("Livello: ${livello['nome']}", style: TextStyle(fontSize: 11, color: livello['color'], fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Obiettivo Attuale", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text("€ ${patrimonio.toStringAsFixed(0)} / ${livello['target']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _getProgresso(), backgroundColor: const Color(0xFF0B0F19), color: livello['color'], minHeight: 8),
                  const SizedBox(height: 16),
                  // Le 4 tappe visive
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTappaBadge("1. Emergenze", "1.000€", patrimonio >= 1000),
                      _buildTappaBadge("2. Cuscino", "10.000€", patrimonio >= 10000),
                      _buildTappaBadge("3. Fortezza", "50.000€", patrimonio >= 50000),
                      _buildTappaBadge("4. Porcellone", "100.000€", patrimonio >= 100000),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. CONSULENTE FINANZIARIO IA
          Card(
            color: const Color(0xFF131B2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("💡 Consulente Finanziario IA", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text("Inserisci valore spesa per valutare l'impatto:", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _itemController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "es. 150"))),
                    const SizedBox(width: 8),
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), onPressed: () => _simulaAI(_itemController.text), child: const Text("Valuta Impatto"))
                  ]),
                  const SizedBox(height: 10),
                  isAiLoading ? const CircularProgressIndicator() : Text(aiPurchaseResult, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. NUOVA TRANSAZIONE & STORICO
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("➕ Nuova Transazione", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777)), onPressed: _mostraModalInserimento, child: const Text("+ Nuova"))
          ]),
          const SizedBox(height: 8),
          
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("📜 Storico Transazioni", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)), onPressed: _mostraFoglioResoconto, child: const Text("Apri Resoconto"))
          ]),
          ...transazioni.map((tx) => Card(
            color: const Color(0xFF131B2E),
            child: ListTile(
              title: Text(tx['category'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(tx['note']),
              trailing: Text("${tx['type'].contains('Entrata') ? '+' : '-'}€${tx['amount']}", style: TextStyle(color: tx['type'].contains('Entrata') ? Colors.greenAccent : Color(0xFFDB2777), fontWeight: FontWeight.bold)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTappaBadge(String titolo, String sub, bool completata) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: completata ? const Color(0xFFDB2777).withOpacity(0.2) : const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: completata ? const Color(0xFFDB2777) : Colors.grey.shade800),
      ),
      child: Column(
        children: [
          Text(titolo, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: completata ? Colors.white : Colors.grey)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 8, color: Colors.grey)),
        ],
      ),
    );
  }
}
