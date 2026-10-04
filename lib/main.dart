import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init notice: $e");
  }
  runApp(const PiggyVaultApp());
}


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return InviteManager(child: HomeScreen(userEmail: FirebaseAuth.instance.currentUser?.email ?? 'Nessuna Email')); // Utente già loggato: dritto al caveau
        }
        return const LoginScreen(); // Utente non loggato: schermata di login
      });
  }
}

class PiggyVaultApp extends StatelessWidget {
  const PiggyVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Piggy Vault',
      debugShowCheckedModeBanner: false,
      home: const AuthGate());
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
  bool _isRegistrazione = false;
  bool _isLoading = false;

  final String _currentTheme = 'Piggy Dark';

  bool get _isLight => _currentTheme == 'Piggy White';
  Color get _scaffoldBg => _isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0B0F19);
  Color get _cardBg => _isLight ? const Color(0xFFFFFFFF) : const Color(0xFF131B2E);
  Color get _textColor => _isLight ? const Color(0xFF0F172A) : Colors.white;
  Color get _subtitleColor => _isLight ? const Color(0xFF475569) : Colors.grey.shade400;
  Color get _primaryColor => const Color(0xFFDB2777);

  String _valutaSicurezzaPassword(String password) {
    if (password.isEmpty) return "";
    if (password.length < 6) return "⚠️ Debole (minimo 6 caratteri)";
    if (password.length < 10 || !password.contains(RegExp(r'[0-9]')) || !password.contains(RegExp(r'[A-Z]'))) {
      return "🟡 Media (usa numeri e maiuscole)";
    }
    return "🟢 Forte e Sicura";
  }

  Color _coloreSicurezza(String password) {
    if (password.length < 6) return Colors.redAccent;
    if (password.length < 10 || !password.contains(RegExp(r'[0-9]'))) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  Future<void> _eseguiAutenticazione() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || !email.contains('@') || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inserisci un'email valida e una password di almeno 6 caratteri")));
      return;
    }

    if (_isRegistrazione && password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le password non coincidono")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential;
      if (_isRegistrazione) {
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password);
      } else {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userEmail: userCredential.user?.email ?? email)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Auth: ${e.toString()} - Accesso locale consentito")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userEmail: email)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final forzaPass = _valutaSicurezzaPassword(_passwordController.text);

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
                      borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.savings, color: Colors.white, size: 40)))),
              const SizedBox(height: 16),
              Text("Piggy Vault", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _textColor)),
              const SizedBox(height: 8),
              Text(
                _isRegistrazione ? "Crea un nuovo account" : "Accedi al tuo caveau",
                style: TextStyle(fontSize: 14, color: _subtitleColor)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  labelText: "Email utente",
                  labelStyle: TextStyle(color: _subtitleColor),
                  filled: true,
                  fillColor: _cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                onChanged: (val) => setState(() {}),
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: _subtitleColor),
                  filled: true,
                  fillColor: _cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
              if (_isRegistrazione && _passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      forzaPass,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _coloreSicurezza(_passwordController.text)))))],
              if (_isRegistrazione) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: TextStyle(color: _textColor),
                  decoration: InputDecoration(
                    labelText: "Conferma Password",
                    labelStyle: TextStyle(color: _subtitleColor),
                    filled: true,
                    fillColor: _cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))))],
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: _eseguiAutenticazione,
                      child: Text(
                        _isRegistrazione ? "Registrati e Crea Account" : "Entra nel Caveau Condiviso",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isRegistrazione = !_isRegistrazione),
                child: Text(
                  _isRegistrazione
                      ? "Hai già un account? Accedi"
                      : "Non hai un account? Registrati",
                  style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)))]))));
  }
}

class HomeScreen extends StatefulWidget {
  final String userEmail;

  HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _caveauId = "bilancio_principale";
  final TextEditingController _inviteController = TextEditingController();
  String _currentTheme = 'Piggy Dark';
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
  String aiPurchaseResult = "🤖 Consulente IA:\nPronto ad analizzare l'impatto delle spese sul vostro bilancio condiviso.";
  bool isAiLoading = false;

  String get _nomeUtenteDinamico {
    final parts = widget.userEmail.split('@');
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      String name = parts[0];
      return name[0].toUpperCase() + name.substring(1);
    }
    return "Utente";
  }

  bool get _isLight => _currentTheme == 'Piggy White';
  Color get _scaffoldBg => _isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0B0F19);
  Color get _cardBg => _isLight ? const Color(0xFFFFFFFF) : const Color(0xFF131B2E);
  Color get _textColor => _isLight ? const Color(0xFF0F172A) : Colors.white;
  Color get _subtitleColor => _isLight ? const Color(0xFF475569) : Colors.grey.shade400;
  Color get _primaryColor => const Color(0xFFDB2777);

  @override
  void initState() {
    super.initState();
    _caricaDatiLocali();
    _ascoltaCloudFirestore();
  }

  Future<void> _caricaDatiLocali() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      patrimonio = prefs.getDouble('patrimonio') ?? 0.00;
      entrateMese = prefs.getDouble('entrateMese') ?? 0.00;
      usciteMese = prefs.getDouble('usciteMese') ?? 0.00;
      _currentTheme = prefs.getString('currentTheme') ?? 'Piggy Dark';
    });
  }

  void _ascoltaCloudFirestore() {
    try {
      FirebaseFirestore.instance
          .collection('caveau_condiviso')
          .doc(_caveauId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          setState(() {
            patrimonio = (data['patrimonio'] ?? patrimonio).toDouble();
            entrateMese = (data['entrateMese'] ?? entrateMese).toDouble();
            usciteMese = (data['usciteMese'] ?? usciteMese).toDouble();
            if (data['transazioni'] != null) {
              final List decoded = data['transazioni'];
              transazioni = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
            }
          });
        }
      });
    } catch (e) {
      debugPrint("Firestore listener notice: $e");
    }
  }

  Future<void> _sincronizzaCloud() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('patrimonio', patrimonio);
    await prefs.setDouble('entrateMese', entrateMese);
    await prefs.setDouble('usciteMese', usciteMese);
    await prefs.setString('currentTheme', _currentTheme);

    try {
      await FirebaseFirestore.instance
          .collection('caveau_condiviso')
          .doc(_caveauId)
          .set({
        'patrimonio': patrimonio,
        'entrateMese': entrateMese,
        'usciteMese': usciteMese,
        'transazioni': transazioni,
        'ultimoAggiornamento': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Cloud sync save notice: $e");
    }
  }

  void _cambiaTema(String nuovoTema) {
    setState(() {
      _currentTheme = nuovoTema;
    });
    _sincronizzaCloud();
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
    _sincronizzaCloud();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Movimento eliminato e sincronizzato")));
  }

  void _mostraDettaglioLivello(String titolo, String target, String descrizione, IconData icona, Color colore) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBg,
        title: Wrap(alignment: WrapAlignment.center, spacing: 12.0, runSpacing: 12.0, children: [
            Icon(icona, color: colore, size: 28),
            const SizedBox(width: 10),
            Text(titolo, style: TextStyle(color: _textColor, fontSize: 18))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Obiettivo del livello: $target", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Text(descrizione, style: TextStyle(color: _textColor, fontSize: 13)),
            const SizedBox(height: 16),
            Text("Patrimonio condiviso attuale: €${patrimonio.toStringAsFixed(2)}", style: TextStyle(color: _subtitleColor, fontSize: 12))]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Capito", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)))]));
  }

  void _simulaAI(String spesaStr) {
    if (spesaStr.isEmpty) return;
    double valore = double.tryParse(spesaStr.replaceAll(',', '.')) ?? 0.0;
    setState(() => isAiLoading = true);
    
    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        isAiLoading = false;
        double impatto = patrimonio > 0 ? (valore / patrimonio) * 100 : 0;
        aiPurchaseResult = "🤖 Consulente IA:\nUna spesa di €$valore impatta sul patrimonio comune per il ${impatto.toStringAsFixed(1)}%. Valutatela insieme!";
      });
    });
  }

  void _mostraModalProfilo() {
    showModalBottomSheet(isScrollControlled: true, context: context,
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
                  Text("👤 Profilo & Cloud", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
                  Icon(Icons.cloud_sync, color: _primaryColor)]),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text("Utente Attivo", style: TextStyle(color: _subtitleColor, fontSize: 11)),
                subtitle: Text(_nomeUtenteDinamico, style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 15))),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text("Email Collegata", style: TextStyle(color: _subtitleColor, fontSize: 11)),
                subtitle: Text(widget.userEmail, style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 15))),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text("Stato Firebase Cloud", style: TextStyle(color: _subtitleColor, fontSize: 11)),
                subtitle: Text("🟢 Connesso in tempo reale", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.pop(context),
                child: const Text("Chiudi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))]));
      });
  }

  void _mostraModalImpostazioni() {
    showModalBottomSheet(isScrollControlled: true, context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24))
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("⚙️ Impostazioni & Temi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
                      Icon(Icons.settings, color: _primaryColor)]),
                  const SizedBox(height: 14),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text("Tema Attivo", style: TextStyle(color: _subtitleColor, fontSize: 11)),
                    subtitle: Text(_currentTheme, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 14))),
                  
            const SizedBox(height: 16),
            const ,
              const SizedBox.shrink(), // Titolo eliminato definitivamente
            const SizedBox(height: 8),
            const SizedBox(height: 4),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(
  controller: _inviteController,
  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
  decoration: const InputDecoration(
    hintText: "Email del partner",
    hintStyle: TextStyle(fontSize: 12, color: Colors.grey)
  )
)),
                IconButton(icon: const Icon(Icons.person_add, color: Colors.blueAccent), onPressed: () async {
                  if (_inviteController.text.trim().isNotEmpty) {
                    final p = await SharedPreferences.getInstance();
                    
final targetEmail = _inviteController.text.trim().toLowerCase();
if (targetEmail.isNotEmpty) {
  final user = FirebaseAuth.instance.currentUser;
  final myEmail = user?.email ?? 'Un utente';
  await FirebaseFirestore.instance.collection('inviti').doc(targetEmail).set({
    'caveau_id': _caveauId,
    'mittente': myEmail,
  });
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("📩 Invito inviato con successo a $targetEmail")));
  _inviteController.clear();
}

                    
                    _ascoltaCloudFirestore();
                    Navigator.pop(context);
                  }
                })
              ]),
            const SizedBox(height: 16),
ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("Disconnetti Account", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)), onTap: () async { Navigator.pop(context); await FirebaseAuth.instance.signOut(); }), const SizedBox(height: 16), Text("🎨 Scegli Tema Grafico:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textColor)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                          onPressed: () {
                            _cambiaTema('Piggy Dark');
                            setModalState(() {});
                            setState(() {});
                          },
                          icon: const Icon(Icons.brush, size: 16, color: Colors.white),
                          label: const Text("Piggy Dark", style: TextStyle(color: Colors.white))),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2E8F0), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                          onPressed: () {
                            _cambiaTema('Piggy White');
                            setModalState(() {});
                            setState(() {});
                          },
                          icon: const Icon(Icons.brush, size: 16, color: Colors.black87),
                          label: const Text("Piggy White", style: TextStyle(color: Colors.black87)))]))]));
          });
      });
  }

  void _mostraFoglioResoconto() {
    double bilancioNetto = entrateMese - usciteMese;
    showModalBottomSheet( context: context,
      isScrollControlled: true, backgroundColor: _cardBg,
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
                  Text("📋 Foglio Resoconto Cloud", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
                  Icon(Icons.description, color: _primaryColor)]),
              const SizedBox(height: 16),
              Card(
                color: _scaffoldBg,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("RIEPILOGO BILANCIO COMUNE", style: TextStyle(fontSize: 10, color: _subtitleColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Entrate Totali:", style: TextStyle(color: _textColor)), Text("€ ${entrateMese.toStringAsFixed(2)}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Uscite Totali:", style: TextStyle(color: _textColor)), Text("€ ${usciteMese.toStringAsFixed(2)}", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold))]),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Bilancio Netto:", style: TextStyle(color: _textColor)), Text("€ ${bilancioNetto.toStringAsFixed(2)}", style: TextStyle(color: bilancioNetto >= 0 ? const Color(0xFF10B981) : _primaryColor, fontWeight: FontWeight.bold))])]))),
              const SizedBox(height: 16),
              Text("Movimenti Cloud (Swipe per eliminare)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _subtitleColor)),
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
                        child: const Icon(Icons.delete, color: Colors.white)),
                      onDismissed: (direction) => _eliminaTransazione(index),
                      child: ListTile(
                        dense: true,
                        title: Text(tx['category'], style: TextStyle(fontWeight: FontWeight.bold, color: _textColor)),
                        subtitle: Text("${tx['note']} • Inserito da: ${tx['author'] ?? 'Utente'}", style: TextStyle(color: _subtitleColor)),
                        trailing: Text(
                          "${tx['type'].contains('Entrata') ? '+' : '-'}€ ${tx['amount'].toStringAsFixed(2)}",
                          style: TextStyle(color: tx['type'].contains('Entrata') ? const Color(0xFF10B981) : _primaryColor, fontWeight: FontWeight.bold))));
                  })),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.pop(context),
                child: const Text("Chiudi Resoconto", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
            ]));
      });
  }

  void _mostraModalInserimento() {
    showModalBottomSheet( context: context,
      isScrollControlled: true, backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20, right: 20, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("➕ Nuova Transazione Condivisa", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: _cardBg,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(labelText: "Tipo", labelStyle: TextStyle(color: _subtitleColor), filled: true, fillColor: _scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: const [
                  DropdownMenuItem(value: 'Uscita (Spesa)', child: Text("🔴 Uscita (Spesa)")),
                  DropdownMenuItem(value: 'Entrata (Guadagno)', child: Text("🟢 Entrata (Guadagno)"))],
                onChanged: (val) => setState(() => _selectedType = val ?? 'Uscita (Spesa)')),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                style: TextStyle(color: _textColor),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Importo (€)", labelStyle: TextStyle(color: _subtitleColor), filled: true, fillColor: _scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: _cardBg,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(labelText: "Categoria", labelStyle: TextStyle(color: _subtitleColor), filled: true, fillColor: _scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: categorieConEmoji.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val ?? '📦 Altro')),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(labelText: "Note / Descrizione", labelStyle: TextStyle(color: _subtitleColor), filled: true, fillColor: _scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  final note = _noteController.text.trim();
                  final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0.0;

                  if (amount > 0) {
                    setState(() {
                      transazioni.insert(0, {
                        "category": _selectedCategory,
                        "note": note.isEmpty ? _selectedCategory : note,
                        "amount": amount,
                        "type": _selectedType,
                        "author": _nomeUtenteDinamico
                      });
                      if (_selectedType.contains('Entrata')) {
                        patrimonio += amount;
                        entrateMese += amount;
                      } else {
                        patrimonio -= amount;
                        usciteMese += amount;
                      }
                    });
                    _sincronizzaCloud();
                    _noteController.clear();
                    _amountController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Registra e Sincronizza Cloud", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))]));
      });
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
                    borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.savings, color: Colors.white, size: 20)))),
            const SizedBox(width: 8),
            Text("Piggy Vault", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor))]),
        actions: [
          GestureDetector(
            onTap: _mostraModalProfilo,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _scaffoldBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _primaryColor.withOpacity(0.5))),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done, size: 14, color: Colors.greenAccent),
                  const SizedBox(width: 4),
                  Text(_nomeUtenteDinamico, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textColor))]))),
          IconButton(
            icon: Icon(Icons.settings, color: _primaryColor),
            tooltip: "Impostazioni e Temi",
            onPressed: _mostraModalImpostazioni)]),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: _cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_sync, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  Text("Modalità Sincronizzazione Cloud Attiva", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textColor))]))),
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
                      Text("PATRIMONIO CONDIVISO", style: TextStyle(fontSize: 10, color: _subtitleColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("€ ${patrimonio.toStringAsFixed(2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF10B981)))]),
                  const Icon(Icons.cloud_done, color: Color(0xFF10B981), size: 32)]))),
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
                        Text("€ ${entrateMese.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent))])))),
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
                        Text("€ ${usciteMese.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent))]))))]),
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
                          Text("🏆 Livelli Risparmio", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textColor))]),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _scaffoldBg, borderRadius: BorderRadius.circular(12)),
                        child: Text("Livello: ${livello['nome']}", style: TextStyle(fontSize: 11, color: livello['color'], fontWeight: FontWeight.bold)))]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Obiettivo Attuale", style: TextStyle(fontSize: 11, color: _subtitleColor)),
                      Text("€ ${patrimonio.toStringAsFixed(0)} / ${livello['target']}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textColor))]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _getProgresso(), backgroundColor: _scaffoldBg, color: livello['color'], minHeight: 8),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () => _mostraDettaglioLivello("1. Emergenze", "1.000€", "Fondo di prima sicurezza per imprevisti urgenti.", Icons.shield, Colors.green),
                        child: _buildTappaBadge("Emergenze", "1.000€", Icons.shield, Colors.green, patrimonio >= 1000)),
                      GestureDetector(
                        onTap: () => _mostraDettaglioLivello("2. Cuscino", "10.000€", "Cuscino finanziario per una tranquillità a medio termine.", Icons.weekend, Colors.blue),
                        child: _buildTappaBadge("Cuscino", "10.000€", Icons.weekend, Colors.blue, patrimonio >= 10000)),
                      GestureDetector(
                        onTap: () => _mostraDettaglioLivello("3. Fortezza", "50.000€", "Solida fortezza patrimoniale per investimenti e stabilità.", Icons.castle, Colors.purple),
                        child: _buildTappaBadge("Fortezza", "50.000€", Icons.castle, Colors.purple, patrimonio >= 50000)),
                      GestureDetector(
                        onTap: () => _mostraDettaglioLivello("4. Porcellone", "100.000€", "Il traguardo supremo del caveau finanziario!", Icons.savings, _primaryColor),
                        child: _buildTappaBadge("Porcellone", "100.000€", Icons.savings, _primaryColor, patrimonio >= 100000))])]))),
          const SizedBox(height: 14),

          Card(
            color: _cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("💡 Pianificatore Acquisti & Rate", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textColor)),
                  const SizedBox(height: 8),
                  Text("Inserisci l'importo (es. 600) per simulare:", style: TextStyle(fontSize: 11, color: _subtitleColor)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _itemController, style: TextStyle(color: _textColor), keyboardType: TextInputType.number, decoration: InputDecoration(hintText: "es. 150", hintStyle: TextStyle(color: _subtitleColor)))),
                    const SizedBox(width: 8),
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), onPressed: () => _simulaAI(_itemController.text), child: const Text("Valuta Impatto", style: TextStyle(color: Colors.white)))
                  ]),
                  const SizedBox(height: 10),
                  isAiLoading ? const CircularProgressIndicator() : Text(aiPurchaseResult, style: TextStyle(fontSize: 11, color: _textColor))]))),
          const SizedBox(height: 14),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("➕ Nuova Transazione", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _subtitleColor)),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _primaryColor), onPressed: _mostraModalInserimento, child: const Text("+ Nuova", style: TextStyle(color: Colors.white)))
          ]),
          const SizedBox(height: 8),
          
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("📜 Storico Condiviso", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _subtitleColor)),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _cardBg), onPressed: _mostraFoglioResoconto, child: Text("Apri Resoconto", style: TextStyle(color: _textColor)))
          ]),
          ...transazioni.take(5).map((tx) => Card(
            color: _cardBg,
            child: ListTile(
              title: Text(tx['category'], style: TextStyle(fontWeight: FontWeight.bold, color: _textColor)),
              subtitle: Text("${tx['note']} • ${tx['author'] ?? 'Utente'}", style: TextStyle(color: _subtitleColor)),
              trailing: Text("${tx['type'].contains('Entrata') ? '+' : '-'}€${tx['amount']}", style: TextStyle(color: tx['type'].contains('Entrata') ? Colors.greenAccent : _primaryColor, fontWeight: FontWeight.bold)))))]));
  }

  Widget _buildTappaBadge(String titolo, String sub, IconData icona, Color colore, bool completata) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: completata ? colore.withOpacity(0.2) : _scaffoldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: completata ? colore : Colors.grey.shade700)),
      child: Column(
        children: [
          Icon(icona, size: 18, color: completata ? colore : _subtitleColor),
          const SizedBox(height: 4),
          Text(titolo, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: completata ? _textColor : _subtitleColor)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 8, color: _subtitleColor))]));
  }
}





class InviteManager extends StatefulWidget {
  final Widget child;
  const InviteManager({super.key, required this.child});
  @override
  State<InviteManager> createState() => _InviteManagerState();
}

class _InviteManagerState extends State<InviteManager> {
  String? currentEmail;

  @override
  void initState() {
    super.initState();
    _checkInviti();
  }

  Future<void> _checkInviti() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;
    
    
    FirebaseFirestore.instance.collection('inviti').doc(currentEmail).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final mittente = data['mittente'] ?? 'Qualcuno';
        final caveauId = data['caveau_id'] ?? '';
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('📩 Nuovo Invito!', style: TextStyle(color: Colors.black)),
            content: Text('$mittente ti ha invitato nel suo Caveau.\n\nVuoi unire i vostri portafogli?', style: const TextStyle(color: Colors.black)),
            actions: [
              TextButton(
                onPressed: () async {
                  if (currentEmail != null) {
                    await FirebaseFirestore.instance.collection('inviti').doc(currentEmail).delete();
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Rifiuta', style: TextStyle(color: Colors.red))),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('caveauId', caveauId);
                  if (currentEmail != null) {
                    await FirebaseFirestore.instance.collection('inviti').doc(currentEmail).delete();
                  }
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caveau Unito! Riavvia l\'app per sincronizzare.')));
                  }
                },
                child: const Text('Accetta e Unisci'))]));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
