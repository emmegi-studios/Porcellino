import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PiggyVaultApp());
}

class PiggyVaultApp extends StatelessWidget {
  const PiggyVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Porcellino',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
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
  String _currentTheme = 'Porcellino Dark';

  bool get _isLight => _currentTheme == 'Porcellino Light';
  Color get _scaffoldBg => _isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0B0F19);
  Color get _cardBg => _isLight ? const Color(0xFFFFFFFF) : const Color(0xFF131B2E);
  Color get _textColor => _isLight ? const Color(0xFF0F172A) : Colors.white;
  Color get _subtitleColor => _isLight ? const Color(0xFF475569) : Colors.grey.shade400;
  Color get _primaryColor => const Color(0xFFDB2777);

  void _autentica() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserisci un'email valida")));
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(userEmail: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icon/icona_esterna.png',
                  width: 70,
                  height: 70,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.savings, color: Colors.white, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text("Porcellino", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _textColor)),
              const SizedBox(height: 36),
              TextField(
                controller: _emailController,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: _subtitleColor),
                  filled: true,
                  fillColor: _cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: _subtitleColor),
                  filled: true,
                  fillColor: _cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
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

  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentTheme = 'Porcellino Dark';
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

  String get _nomeUtenteDinamico => widget.userEmail.contains('marika') ? "Marika" : "Marcogrillone";

  bool get _isLight => _currentTheme == 'Porcellino Light';
  Color get _scaffoldBg => _isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0B0F19);
  Color get _cardBg => _isLight ? const Color(0xFFFFFFFF) : const Color(0xFF131B2E);
  Color get _textColor => _isLight ? const Color(0xFF0F172A) : Colors.white;
  Color get _subtitleColor => _isLight ? const Color(0xFF475569) : Colors.grey.shade400;
  Color get _primaryColor => const Color(0xFFDB2777);

  @override
  void initState() {
    super.initState();
    _caricaDatiLocali();
  }

  Future<void> _caricaDatiLocali() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      patrimonio = prefs.getDouble('patrimonio') ?? 0.00;
      entrateMese = prefs.getDouble('entrateMese') ?? 0.00;
      usciteMese = prefs.getDouble('usciteMese') ?? 0.00;
      _currentTheme = prefs.getString('currentTheme') ?? 'Porcellino Dark';
      
      final String? txString = prefs.getString('transazioni');
      if (txString != null) {
        final List decoded = jsonDecode(txString);
        transazioni = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    });
  }

  Future<void> _salvaDatiLocali() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('patrimonio', patrimonio);
    await prefs.setDouble('entrateMese', entrateMese);
    await prefs.setDouble('usciteMese', usciteMese);
    await prefs.setString('currentTheme', _currentTheme);
    await prefs.setString('transazioni', jsonEncode(transazioni));
  }

  void _cambiaTema(String nuovoTema) {
    setState(() {
      _currentTheme = nuovoTema;
    });
    _salvaDatiLocali();
  }

  Map<String, dynamic> _getLivelloPorcellino() {
    if (patrimonio < 1000) {
      return {"nome": "Emergenze", "target": "1.000€", "color": Colors.green, "icon": Icons.shield};
    } else if (patrimonio < 10000) {
      return {"nome": "Cuscino", "target": "10.000€", "color": Colors.blue, "icon": Icons.weekend};
    } else if (patrimonio < 50000) {
      return {"nome": "Fortezza", "target": "50.000€", "color": Colors.purple, "icon": Icons.castle};
    } else {
      return {"nome": "Porcellone", "target": "100.000€", "color": _primaryColor, "icon": Icons.savings};
    }
  }

  double _getProgresso() => (patrimonio / 100000.0).clamp(0.0, 1.0);

  void _eliminaTransazione(int index) {
    setState(() {
      final tx = transazioni[index];
      double amount = tx['amount'];
      if (tx['type'].contains('Entrata')) {
        patrimonio -= amount;
        entrateMese -= amount;
      } else {
        patrimonio += amount;
        usciteMese -= amount;
      }
      transazioni.removeAt(index);
    });
    _salvaDatiLocali();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transazione eliminata")));
  }

  void _mostraDettaglioLivello(String titolo, String target, String descrizione, IconData icona, Color colore) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBg,
        title: Row(
          children: [
            Icon(icona, color: colore, size: 28),
            const SizedBox(width: 10),
            Text(titolo, style: TextStyle(color: _textColor, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Obiettivo del livello: $target", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Text(descrizione, style: TextStyle(color: _textColor, fontSize: 13)),
            const SizedBox(height: 16),
            Text("Il tuo patrimonio attuale: €${patrimonio.toStringAsFixed(2)}", style: TextStyle(color: _subtitleColor, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Capito", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
        backgroundColor: _cardBg,
        title: Text("👥 Invito Inviato!", style: TextStyle(color: _textColor)),
        content: Text("Link sicuro per il conto condiviso inviato a:\n\n👉 $email\n\nMarika potrà installare l'app e accedere con questa email per sincronizzare i dati!", style: TextStyle(color: _textColor)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Ottimo", style: TextStyle(color: _primaryColor)))],
      ),
    );
    _inviteEmailController.clear();
  }

  void _mostraModalProfilo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
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
                  Text("👤 Profilo Utente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
                  Icon(Icons.person, color: _primaryColor),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text("Nome Utente", style: TextStyle(color: _subtitleColor, fontSize: 11)),
                subtitle: Text(_nomeUtenteDinamico, style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text("Email Registrata", style: TextStyle(color: _subtitleColor, fontSize: 11)),
                subtitle: Text(widget.userEmail, style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text("Tipo Account", style: TextStyle(color: _subtitleColor, fontSize: 11)),
                subtitle: Text("Caveau Privato & Condiviso (Standard)", style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
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
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("⚙️ Impostazioni & Temi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
                      Icon(Icons.settings, color: _primaryColor),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text("Tema Attivo", style: TextStyle(color: _subtitleColor, fontSize: 11)),
                    subtitle: Text(_currentTheme, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Divider(color: _subtitleColor, height: 24),
                  Text("🎨 Scegli Tema Grafico:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textColor)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                          onPressed: () {
                            _cambiaTema('Porcellino Dark');
                            setModalState(() {});
                            setState(() {});
                          },
                          icon: const Icon(Icons.brush, size: 16, color: Colors.white),
                          label: const Text("Porcellino Dark", style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2E8F0), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                          onPressed: () {
                            _cambiaTema('Porcellino Light');
                            setModalState(() {});
                            setState(() {});
                          },
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
      },
    );
  }

  void _mostraFoglioResoconto() {
    double bilancioNetto = entrateMese - usciteMese;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
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
                  Text("📋 Foglio Resoconto Mensile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
                  Icon(Icons.description, color: _primaryColor),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: _scaffoldBg,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("RIEPILOGO BILANCIO", style: TextStyle(fontSize: 10, color: _subtitleColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Entrate Totali:", style: TextStyle(color: _textColor)), Text("€ ${entrateMese.toStringAsFixed(2)}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Uscite Totali:", style: TextStyle(color: _textColor)), Text("€ ${usciteMese.toStringAsFixed(2)}", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold))]),
                      Divider(color: _subtitleColor),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Bilancio Netto:", style: TextStyle(color: _textColor)), Text("€ ${bilancioNetto.toStringAsFixed(2)}", style: TextStyle(color: bilancioNetto >= 0 ? const Color(0xFF10B981) : _primaryColor, fontWeight: FontWeight.bold))]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text("Dettaglio Movimenti (Swipe o elimina)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _subtitleColor)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: transazioni.length,
                  itemBuilder: (context, index) {
                    final tx = transazioni[index];
                    return Dismissible(
                      key: Key('${tx['category']}_${tx['amount']}_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) => _eliminaTransazione(index),
                      child: ListTile(
                        dense: true,
                        title: Text(tx['category'], style: TextStyle(fontWeight: FontWeight.bold, color: _textColor)),
                        subtitle: Text(tx['note'], style: TextStyle(color: _subtitleColor)),
                        trailing: Text(
                          "${tx['type'].contains('Entrata') ? '+' : '-'}€ ${tx['amount'].toStringAsFixed(2)}",
                          style: TextStyle(color: tx['type'].contains('Entrata') ? const Color(0xFF10B981) : _primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
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
      backgroundColor: _cardBg,
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
              Text("➕ Nuova Transazione", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: _cardBg,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(labelText: "Tipo", labelStyle: TextStyle(color: _subtitleColor), filled: true, fillColor: _scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: const [
                  DropdownMenuItem(value: 'Uscita (Spesa)', child: Text("🔴 Uscita (Spesa)")),
                  DropdownMenuItem(value: 'Entrata (Guadagno)', child: Text("🟢 Entrata (Guadagno)")),
                ],
                onChanged: (val) => setState(() => _selectedType = val ?? 'Uscita (Spesa)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                style: TextStyle(color: _textColor),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Importo (€)", labelStyle: TextStyle(color: _subtitleColor), filled: true, fillColor: _scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: _cardBg,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(labelText: "Categoria", labelStyle: TextStyle(color: _subtitleColor), filled: true, fillColor: _scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: categorieConEmoji.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val ?? '📦 Altro'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(labelText: "Note / Descrizione", labelStyle: TextStyle(color: _subtitleColor), filled: true, fillColor: _scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
                    _salvaDatiLocali();
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
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/icona_esterna.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.savings, color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text("Porcellino", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _mostraModalProfilo,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _scaffoldBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _primaryColor.withOpacity(0.5))),
              child: Row(
                children: [
                  Icon(Icons.person, size: 14, color: _primaryColor),
                  const SizedBox(width: 4),
                  Text(_nomeUtenteDinamico, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textColor)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: _primaryColor),
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
            decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isSharedMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: !isSharedMode ? _primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text("🔒 Conto Privato", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: !isSharedMode ? Colors.white : _textColor))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isSharedMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: isSharedMode ? const Color(0xFF3B82F6) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text("👥 Conto Condiviso", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSharedMode ? Colors.white : _textColor))),
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
                  backgroundColor: _cardBg,
                  title: Text("👥 Invita Marika / Collaboratore", style: TextStyle(color: _textColor)),
                  content: TextField(controller: _inviteEmailController, style: TextStyle(color: _textColor), decoration: const InputDecoration(labelText: "Email collaboratore (es. marika@email.com)")),
                  actions: [TextButton(onPressed: _inviaInvito, child: Text("Invia Invito", style: TextStyle(color: _primaryColor)))],
                ),
              ),
              icon: const Icon(Icons.email, color: Colors.white),
              label: const Text("Invia Invito Email a Collaboratore", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
          const SizedBox(height: 14),

          Card(
            color: _cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("PATRIMONIO TOTALE", style: TextStyle(fontSize: 10, color: _subtitleColor, fontWeight: FontWeight.bold)),
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
                  color: _cardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ENTRATE MESE", style: TextStyle(fontSize: 9, color: _subtitleColor, fontWeight: FontWeight.bold)),
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
                  color: _cardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("USCITE MESE", style: TextStyle(fontSize: 9, color: _subtitleColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("€ ${usciteMese.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Card(
            color: _cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(livello['icon'], color: livello['color'], size: 22),
                          const SizedBox(width: 8),
                          Text("🏆 Livelli Risparmio", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textColor)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _scaffoldBg, borderRadius: BorderRadius.circular(12)),
                        child: Text("Livello: ${livello['nome']}", style: TextStyle(fontSize: 11, color: livello['color'], fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Obiettivo Attuale", style: TextStyle(fontSize: 11, color: _subtitleColor)),
                      Text("€ ${patrimonio.toStringAsFixed(0)} / ${livello['target']}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _getProgresso(), backgroundColor: _scaffoldBg, color: livello['color'], minHeight: 8),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () => _mostraDettaglioLivello("1. Emergenze", "1.000€", "Fondo di prima sicurezza per imprevisti urgenti.", Icons.shield, Colors.green),
                        child: _buildTappaBadge("Emergenze", "1.000€", Icons.shield, Colors.green, patrimonio >= 1000),
                      ),
                      GestureDetector(
                        onTap: () => _mostraDettaglioLivello("2. Cuscino", "10.000€", "Cuscino finanziario per una tranquillità a medio termine.", Icons.weekend, Colors.blue),
                        child: _buildTappaBadge("Cuscino", "10.000€", Icons.weekend, Colors.blue, patrimonio >= 10000),
                      ),
                      GestureDetector(
                        onTap: () => _mostraDettaglioLivello("3. Fortezza", "50.000€", "Solida fortezza patrimoniale per investimenti e stabilità.", Icons.castle, Colors.purple),
                        child: _buildTappaBadge("Fortezza", "50.000€", Icons.castle, Colors.purple, patrimonio >= 50000),
                      ),
                      GestureDetector(
                        onTap: () => _mostraDettaglioLivello("4. Porcellone", "100.000€", "Il traguardo supremo del caveau finanziario!", Icons.savings, _primaryColor),
                        child: _buildTappaBadge("Porcellone", "100.000€", Icons.savings, _primaryColor, patrimonio >= 100000),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Card(
            color: _cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("💡 Consulente Finanziario IA", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textColor)),
                  const SizedBox(height: 8),
                  Text("Inserisci valore spesa per valutare l'impatto:", style: TextStyle(fontSize: 11, color: _subtitleColor)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _itemController, style: TextStyle(color: _textColor), keyboardType: TextInputType.number, decoration: InputDecoration(hintText: "es. 150", hintStyle: TextStyle(color: _subtitleColor)))),
                    const SizedBox(width: 8),
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), onPressed: () => _simulaAI(_itemController.text), child: const Text("Valuta Impatto", style: TextStyle(color: Colors.white)))
                  ]),
                  const SizedBox(height: 10),
                  isAiLoading ? const CircularProgressIndicator() : Text(aiPurchaseResult, style: TextStyle(fontSize: 11, color: _textColor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("➕ Nuova Transazione", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _subtitleColor)),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _primaryColor), onPressed: _mostraModalInserimento, child: const Text("+ Nuova", style: TextStyle(color: Colors.white)))
          ]),
          const SizedBox(height: 8),
          
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("📜 Storico Transazioni", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _subtitleColor)),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _cardBg), onPressed: _mostraFoglioResoconto, child: Text("Apri Resoconto", style: TextStyle(color: _textColor)))
          ]),
          ...transazioni.take(5).map((tx) => Card(
            color: _cardBg,
            child: ListTile(
              title: Text(tx['category'], style: TextStyle(fontWeight: FontWeight.bold, color: _textColor)),
              subtitle: Text(tx['note'], style: TextStyle(color: _subtitleColor)),
              trailing: Text("${tx['type'].contains('Entrata') ? '+' : '-'}€${tx['amount']}", style: TextStyle(color: tx['type'].contains('Entrata') ? Colors.greenAccent : _primaryColor, fontWeight: FontWeight.bold)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTappaBadge(String titolo, String sub, IconData icona, Color colore, bool completata) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: completata ? colore.withOpacity(0.2) : _scaffoldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: completata ? colore : Colors.grey.shade700),
      ),
      child: Column(
        children: [
          Icon(icona, size: 18, color: completata ? colore : _subtitleColor),
          const SizedBox(height: 4),
          Text(titolo, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: completata ? _textColor : _subtitleColor)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 8, color: _subtitleColor)),
        ],
      ),
    );
  }
}
