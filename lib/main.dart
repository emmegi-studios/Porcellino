import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PiggyVaultApp());
}

class PiggyVaultApp extends StatefulWidget {
  const PiggyVaultApp({super.key});

  @override
  State<PiggyVaultApp> createState() => _PiggyVaultAppState();
}

class _PiggyVaultAppState extends State<PiggyVaultApp> {
  String _currentTheme = 'Porcellino Dark';
  
  // Colori dinamici per Dark e Light pulito
  Color get _scaffoldBg => _currentTheme == 'Porcellino Light' ? const Color(0xFFF1F5F9) : const Color(0xFF0B0F19);
  Color get _cardBg => _currentTheme == 'Porcellino Light' ? const Color(0xFFFFFFFF) : const Color(0xFF131B2E);
  Color get _textColor => _currentTheme == 'Porcellino Light' ? const Color(0xFF0F172A) : Colors.white;
  Color get _primaryColor => const Color(0xFFDB2777);
  Color get _accentColor => const Color(0xFFF472B6);
  Brightness get _brightness => _currentTheme == 'Porcellino Light' ? Brightness.light : Brightness.dark;

  void changeTheme(String themeName) {
    setState(() {
      _currentTheme = themeName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Porcellino',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _brightness,
        scaffoldBackgroundColor: _scaffoldBg,
        primaryColor: _primaryColor,
      ),
      home: LoginScreen(
        onThemeChanged: changeTheme,
        currentTheme: _currentTheme,
        scaffoldBg: _scaffoldBg,
        cardBg: _cardBg,
        textColor: _textColor,
        primaryColor: _primaryColor,
        accentColor: _accentColor,
        brightness: _brightness,
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final Function(String) onThemeChanged;
  final String currentTheme;
  final Color scaffoldBg;
  final Color cardBg;
  final Color textColor;
  final Color primaryColor;
  final Color accentColor;
  final Brightness brightness;

  const LoginScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
    required this.scaffoldBg,
    required this.cardBg,
    required this.textColor,
    required this.primaryColor,
    required this.accentColor,
    required this.brightness,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _autentica() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserisci un'email valida")));
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          userEmail: email,
          onThemeChanged: widget.onThemeChanged,
          currentTheme: widget.currentTheme,
          scaffoldBg: widget.scaffoldBg,
          cardBg: widget.cardBg,
          textColor: widget.textColor,
          primaryColor: widget.primaryColor,
          accentColor: widget.accentColor,
          brightness: widget.brightness,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage('assets/icon/icona_esterna.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text("Porcellino", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: widget.textColor)),
              const SizedBox(height: 36),
              TextField(
                controller: _emailController,
                style: TextStyle(color: widget.textColor),
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  fillColor: widget.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: widget.textColor),
                decoration: InputDecoration(
                  labelText: "Password",
                  filled: true,
                  fillColor: widget.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _autentica,
                child: const Text("Accedi al Caveau", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String userEmail;
  final Function(String) onThemeChanged;
  final String currentTheme;
  final Color scaffoldBg;
  final Color cardBg;
  final Color textColor;
  final Color primaryColor;
  final Color accentColor;
  final Brightness brightness;

  const HomeScreen({
    super.key,
    required this.userEmail,
    required this.onThemeChanged,
    required this.currentTheme,
    required this.scaffoldBg,
    required this.cardBg,
    required this.textColor,
    required this.primaryColor,
    required this.accentColor,
    required this.brightness,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSharedMode = false;
  double patrimonio = 0.00;
  double entrateMese = 0.00;
  double usciteMese = 0.00;

  List<Map<String, dynamic>> transazioni = [];

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
  final _inviteEmailController = TextEditingController();
  final _itemController = TextEditingController();
  String aiPurchaseResult = "Inserisci le tue prime entrate e uscite per sbloccare i consigli personalizzati dell'IA.";
  bool isAiLoading = false;

  String get _nomeUtenteDinamico {
    if (widget.userEmail.contains('@')) {
      String nome = widget.userEmail.split('@')[0];
      return nome[0].toUpperCase() + nome.substring(1);
    }
    return "Utente";
  }

  Map<String, dynamic> _getLivelloPorcellino() {
    if (patrimonio < 1000) {
      return {"nome": "Emergenze", "target": "1.000€", "color": Colors.green};
    } else if (patrimonio < 10000) {
      return {"nome": "Cuscino", "target": "10.000€", "color": Colors.blue};
    } else if (patrimonio < 50000) {
      return {"nome": "Fortezza", "target": "50.000€", "color": Colors.purple};
    } else {
      return {"nome": "Porcellone", "target": "100.000€", "color": widget.primaryColor};
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
        backgroundColor: widget.cardBg,
        title: Text("👥 Invito Inviato!", style: TextStyle(color: widget.textColor)),
        content: Text("Link sicuro per il conto condiviso inviato a:\n\n👉 $email", style: TextStyle(color: widget.textColor)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Ottimo", style: TextStyle(color: widget.primaryColor)))],
      ),
    );
    _inviteEmailController.clear();
  }

  void _mostraModalProfilo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("👤 Profilo Utente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.textColor)),
                  Icon(Icons.person, color: widget.primaryColor),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text("Nome Utente", style: TextStyle(color: Colors.grey, fontSize: 11)),
                subtitle: Text(_nomeUtenteDinamico, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text("Email Registrata", style: TextStyle(color: Colors.grey, fontSize: 11)),
                subtitle: Text(widget.userEmail, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text("Tipo Account", style: TextStyle(color: Colors.grey, fontSize: 11)),
                subtitle: Text("Caveau Privato & Condiviso (Standard)", style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: widget.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.pop(context),
                child: const Text("Chiudi Profilo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostraModalImpostazioni() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("⚙️ Impostazioni & Temi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.textColor)),
                  Icon(Icons.settings, color: widget.primaryColor),
                ],
              ),
              const SizedBox(height: 14),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text("Tema Attivo", style: TextStyle(color: Colors.grey, fontSize: 11)),
                subtitle: Text(widget.currentTheme, style: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const Divider(color: Colors.grey, height: 24),
              Text("🎨 Scegli Tema Grafico:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.textColor)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                      onPressed: () { widget.onThemeChanged('Porcellino Dark'); Navigator.pop(context); },
                      icon: const Icon(Icons.brush, size: 16, color: Colors.white),
                      label: const Text("Porcellino Dark", style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2E8F0), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                      onPressed: () { widget.onThemeChanged('Porcellino Light'); Navigator.pop(context); },
                      icon: const Icon(Icons.brush, size: 16, color: Colors.black87),
                      label: const Text("Porcellino Light", style: TextStyle(color: Colors.black87)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
      backgroundColor: widget.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("📋 Foglio Resoconto Mensile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.textColor)),
                  Icon(Icons.description, color: widget.primaryColor),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: widget.scaffoldBg,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("RIEPILOGO BILANCIO", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Entrate Totali:", style: TextStyle(color: widget.textColor)), Text("€ ${entrateMese.toStringAsFixed(2)}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Uscite Totali:", style: TextStyle(color: widget.textColor)), Text("€ ${usciteMese.toStringAsFixed(2)}", style: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.bold))]),
                      const Divider(color: Colors.grey),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Bilancio Netto:", style: TextStyle(color: widget.textColor)), Text("€ ${bilancioNetto.toStringAsFixed(2)}", style: TextStyle(color: bilancioNetto >= 0 ? const Color(0xFF10B981) : widget.primaryColor, fontWeight: FontWeight.bold))]),
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
                      title: Text(tx['category'], style: TextStyle(fontWeight: FontWeight.bold, color: widget.textColor)),
                      subtitle: Text(tx['note'], style: const TextStyle(color: Colors.grey)),
                      trailing: Text(
                        "${tx['type'].contains('Entrata') ? '+' : '-'}€ ${tx['amount'].toStringAsFixed(2)}",
                        style: TextStyle(color: tx['type'].contains('Entrata') ? const Color(0xFF10B981) : widget.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: widget.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
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
      backgroundColor: widget.cardBg,
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
              Text("➕ Nuova Transazione", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.textColor)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: widget.cardBg,
                style: TextStyle(color: widget.textColor),
                decoration: InputDecoration(labelText: "Tipo", filled: true, fillColor: widget.scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: const [
                  DropdownMenuItem(value: 'Uscita (Spesa)', child: Text("🔴 Uscita (Spesa)")),
                  DropdownMenuItem(value: 'Entrata (Guadagno)', child: Text("🟢 Entrata (Guadagno)")),
                ],
                onChanged: (val) => setState(() => _selectedType = val ?? 'Uscita (Spesa)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                style: TextStyle(color: widget.textColor),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Importo (€)", filled: true, fillColor: widget.scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: widget.cardBg,
                style: TextStyle(color: widget.textColor),
                decoration: InputDecoration(labelText: "Categoria", filled: true, fillColor: widget.scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: categorieConEmoji.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val ?? '📦 Altro'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                style: TextStyle(color: widget.textColor),
                decoration: InputDecoration(labelText: "Note / Descrizione", filled: true, fillColor: widget.scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: widget.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
      backgroundColor: widget.scaffoldBg,
      appBar: AppBar(
        backgroundColor: widget.cardBg,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: AssetImage('assets/icon/icona_esterna.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text("Porcellino", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.textColor)),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _mostraModalProfilo,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: widget.scaffoldBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.primaryColor.withOpacity(0.5))),
              child: Row(
                children: [
                  Icon(Icons.person, size: 14, color: widget.primaryColor),
                  const SizedBox(width: 4),
                  Text(_nomeUtenteDinamico, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.textColor)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: widget.primaryColor),
            tooltip: "Impostazioni e Temi",
            onPressed: _mostraModalImpostazioni,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: widget.cardBg, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isSharedMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: !isSharedMode ? widget.primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text("🔒 Conto Privato", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: !isSharedMode ? Colors.white : widget.textColor))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isSharedMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: isSharedMode ? const Color(0xFF3B82F6) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text("👥 Conto Condiviso", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSharedMode ? Colors.white : widget.textColor))),
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
                  backgroundColor: widget.cardBg,
                  title: Text("👥 Invita Collaboratore", style: TextStyle(color: widget.textColor)),
                  content: TextField(controller: _inviteEmailController, style: TextStyle(color: widget.textColor), decoration: const InputDecoration(labelText: "Email collaboratore")),
                  actions: [TextButton(onPressed: _inviaInvito, child: Text("Invia Email", style: TextStyle(color: widget.primaryColor)))],
                ),
              ),
              icon: const Icon(Icons.email),
              label: const Text("Invia Invito Email a Collaboratore"),
            ),
          ],
          const SizedBox(height: 14),

          // PATRIMONIO TOTALE (Verde smeraldo brillante inalterato)
          Card(
            color: widget.cardBg,
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

          Row(
            children: [
              Expanded(
                child: Card(
                  color: widget.cardBg,
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
                  color: widget.cardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("USCITE MESE", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("€ ${usciteMese.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.primaryColor)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Card(
            color: widget.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("🏆 Livelli Porcellino Risparmio", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.textColor)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: widget.scaffoldBg, borderRadius: BorderRadius.circular(12)),
                        child: Text("Livello: ${livello['nome']}", style: TextStyle(fontSize: 11, color: livello['color'], fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Obiettivo Attuale", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text("€ ${patrimonio.toStringAsFixed(0)} / ${livello['target']}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.textColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _getProgresso(), backgroundColor: widget.scaffoldBg, color: livello['color'], minHeight: 8),
                  const SizedBox(height: 16),
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

          Card(
            color: widget.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("💡 Consulente Finanziario IA", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.textColor)),
                  const SizedBox(height: 8),
                  const Text("Inserisci valore spesa per valutare l'impatto:", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _itemController, style: TextStyle(color: widget.textColor), keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "es. 150"))),
                    const SizedBox(width: 8),
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), onPressed: () => _simulaAI(_itemController.text), child: const Text("Valuta Impatto"))
                  ]),
                  const SizedBox(height: 10),
                  isAiLoading ? const CircularProgressIndicator() : Text(aiPurchaseResult, style: TextStyle(fontSize: 11, color: widget.textColor.withOpacity(0.8))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("➕ Nuova Transazione", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: widget.primaryColor), onPressed: _mostraModalInserimento, child: const Text("+ Nuova"))
          ]),
          const SizedBox(height: 8),
          
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("📜 Storico Transazioni", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: widget.cardBg), onPressed: _mostraFoglioResoconto, child: Text("Apri Resoconto", style: TextStyle(color: widget.textColor)))
          ]),
          ...transazioni.map((tx) => Card(
            color: widget.cardBg,
            child: ListTile(
              title: Text(tx['category'], style: TextStyle(fontWeight: FontWeight.bold, color: widget.textColor)),
              subtitle: Text(tx['note'], style: const TextStyle(color: Colors.grey)),
              trailing: Text("${tx['type'].contains('Entrata') ? '+' : '-'}€${tx['amount']}", style: TextStyle(color: tx['type'].contains('Entrata') ? Colors.greenAccent : widget.primaryColor, fontWeight: FontWeight.bold)),
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
        color: completata ? widget.primaryColor.withOpacity(0.2) : widget.scaffoldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: completata ? widget.primaryColor : Colors.grey.shade700),
      ),
      child: Column(
        children: [
          Text(titolo, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: completata ? widget.textColor : Colors.grey)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 8, color: Colors.grey)),
        ],
      ),
    );
  }
}
