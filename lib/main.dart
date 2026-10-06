import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('currentTheme') ?? 'Piggy Dark';
  runApp(PiggyVaultApp(initialTheme: savedTheme));
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
  final String initialTheme;
  const PiggyVaultApp({super.key, this.initialTheme = 'Piggy Dark'});
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
  bool _obscurePassword = true;
  bool _isDarkTheme = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadSavedEmail();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDarkTheme = prefs.getBool('piggy_is_dark') ?? true;
      });
    }
  }

  

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('piggy_last_email');
    if (savedEmail != null && mounted) {
      setState(() {
        _emailController.text = savedEmail;
      });
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('piggy_last_email', email);
  }

  Future<void> _eseguiAutenticazione() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compila tutti i campi"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isRegistrazione) {
        if (password != _confirmPasswordController.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Le password non coincidono"), backgroundColor: Colors.red)
          );
          setState(() => _isLoading = false);
          return;
        }
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      } else {
        await _saveEmail(email);
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore: ${e.toString()}"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inserisci prima la tua email per il recupero"), backgroundColor: Colors.orange)
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email di recupero inviata! Controlla la posta."), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore: ${e.toString()}"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _cardBg = _isDarkTheme ? const Color(0xFF1E2235) : Colors.white;
    final _scaffoldBg = _isDarkTheme ? const Color(0xFF0F111A) : const Color(0xFFF0F2F5);
    final _textColor = _isDarkTheme ? Colors.white : Colors.black87;
    final _subtitleColor = Colors.grey.shade400;
    final _primaryColor = Colors.pinkAccent;

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                    Image.asset(
                      'assets/icon/icona_esterna.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.savings, size: 60, color: _primaryColor),
                    ),
              const SizedBox(height: 16),
              const Text("Piggy Vault", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text("Accedi al tuo caveau condiviso", style: TextStyle(fontSize: 14, color: _subtitleColor)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                style: TextStyle(color: _textColor),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email utente",
                  labelStyle: TextStyle(color: _subtitleColor),
                  filled: true,
                  fillColor: _cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: _subtitleColor),
                  filled: true,
                  fillColor: _cardBg,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: _primaryColor),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              if (_isRegistrazione) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: _textColor),
                  decoration: InputDecoration(
                    labelText: "Conferma Password",
                    labelStyle: TextStyle(color: _subtitleColor),
                    filled: true,
                    fillColor: _cardBg,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: _primaryColor),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _eseguiAutenticazione,
                      child: Text(
                        _isRegistrazione ? "Registrati e Crea Account" : "Entra nel Caveau Condiviso",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
              if (!_isRegistrazione) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _resetPassword,
                  child: Text("Password smarrita?", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isRegistrazione = !_isRegistrazione),
                child: Text(
                  _isRegistrazione ? "Hai già un account? Accedi" : "Non hai un account? Registrati",
                  style: TextStyle(color: _subtitleColor),
                ),
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

  HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Richiesta permessi Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _mostraNotificaScadenza(String titolo, String data) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'piggy_vault_scadenze',
      'Scadenze Finanziarie',
      channelDescription: 'Notifiche per scadenze e promemoria di Piggy Vault',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      '📅 Nuova Scadenza: $titolo',
      'Fissata per il giorno $data',
      platformChannelSpecifics,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBudget();
    _loadTheme();
    _caricaPromemoriaDaCloud();
    _initNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTheme();
      _loadBudget();
    }
  }
  bool _isDarkTheme = true;
  List<Map<String, dynamic>> _promemoria = [];

  Future<void> _caricaPromemoriaDaCloud() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users_budget').doc(user.uid).get();
        if (doc.exists && doc.data()!.containsKey('promemoria')) {
          List<dynamic> listaCloud = doc.data()!['promemoria'];
          setState(() {
            _promemoria = listaCloud.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (e) {
      print("Errore caricamento promemoria cloud: $e");
    }
  }

  Future<void> _salvaPromemoriaSuCloud() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users_budget').doc(user.uid).set({
          'promemoria': _promemoria,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Errore salvataggio promemoria cloud: $e");
    }
  }


  

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = prefs.getBool('piggy_is_dark') ?? true;
    });
  }

  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('piggy_is_dark', isDark);
    setState(() {
      _isDarkTheme = isDark;
    });
  }

  


  double _monthlyBudget = 1500.0;

  

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyBudget = prefs.getDouble('piggy_monthly_budget') ?? 1500.0;
    });
  }

  Future<void> _saveBudget(double newBudget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('piggy_monthly_budget', newBudget);
    setState(() {
      _monthlyBudget = newBudget;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users_budget').doc(user.uid).set({
          'monthly_budget': newBudget,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Errore salvataggio budget cloud: $e");
    }
  }

  void _showBudgetDialog() {
    final controller = TextEditingController(text: _monthlyBudget.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text("Imposta Tetto di Spesa Mensile", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Budget (€)",
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annulla", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                _saveBudget(val);
              }
              Navigator.pop(context);
            },
            child: const Text("Salva", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(List<dynamic> docs) {
    double currentMonthExpenses = 0.0;
    final now = DateTime.now();
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] ?? 'uscita';
      final amount = (data['amount'] ?? 0.0).toDouble();
      final dateField = data['date'];
      DateTime? date;
      if (dateField is Timestamp) {
        date = dateField.toDate();
      } else if (dateField is String) {
        date = DateTime.tryParse(dateField);
      }
      
      if (date != null && date.year == now.year && date.month == now.month) {
        if (type == 'uscita' || amount < 0) {
          currentMonthExpenses += amount.abs();
        }
      }
    }

    final progress = _monthlyBudget > 0 ? (currentMonthExpenses / _monthlyBudget).clamp(0.0, 1.0) : 0.0;
    Color progressColor = Colors.greenAccent;
    if (progress >= 1.0) {
      progressColor = Colors.redAccent;
    } else if (progress >= 0.8) {
      progressColor = Colors.orangeAccent;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: progressColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tetto di Spesa Mensile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.pinkAccent, size: 20),
                onPressed: _showBudgetDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Speso: €${currentMonthExpenses.toStringAsFixed(2)}", style: const TextStyle(color: Colors.grey, fontSize: 14)),
              Text("Budget: €${_monthlyBudget.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }


  bool _isInitialLoad = true;

  

  void _setupRealtimeNotifications() {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    FirebaseFirestore.instance.collection('caveau_condiviso').snapshots().listen((snapshot) {
      if (_isInitialLoad) {
        _isInitialLoad = false;
        return;
      }
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final author = data['author'] ?? 'Partner';
            final amount = data['amount'] ?? '0';
            final category = data['category'] ?? 'Spesa';
            final type = data['type'] ?? 'Uscita';

            if (currentUserEmail == null || author != currentUserEmail) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("🔔 Nuova attività da $author: $type di €$amount ($category)"),
                    backgroundColor: const Color(0xFF3B82F6),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }
          }
        }
      }
    });
  }

  bool get _isDark => _currentTheme == 'Piggy Dark';
  Color get _cardBg => _isDark ? const Color(0xFF1E2235) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : Colors.black87;
  Color get _subtitleColor => _isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  Color get _primaryColor => Colors.pinkAccent;
  Color get _scaffoldBg => _isDark ? const Color(0xFF0F111A) : Colors.grey.shade100;

  double patrimonio = 0.0;
  double entrateMese = 0.0;
  double usciteMese = 0.0;
  List<Map<String, dynamic>> transazioni = [];
  String _currentTheme = 'Piggy Dark';
  String _caveauId = '';
  String _nomeUtenteDinamico = 'Utente';
  bool isAiLoading = false;
  List<Map<String, dynamic>> portafogli = [];
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _goalTargetController = TextEditingController();
  String aiPurchaseResult = '';
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _inviteController = TextEditingController();
  String _selectedType = 'Uscita (Spesa)';
  String _selectedCategory = '🐾 Animali';
  final List<String> categorieConEmoji = ['💰 Stipendio / Entrate', '🍔 Cibo & Spesa', '🏠 Casa & Affitto', '🚗 Trasporti', '💡 Bollette & Utenze', '🎉 Svago & Hobby', '🐾 Animali',
  '📦 Altro'];

  
  
  
  
  

  
  
  void _esportaCSV() {
    String csv = 'Data,Categoria,Tipo,Importo,Autore,Note\n;';
    for (var t in transazioni) {
      csv += "${t['data']},${t['category']},${t['tipo']},${t['amount']},${t['author'] ?? 'Utente'},${t['note'] ?? ''}\n";
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text('📊 Esportazione CSV', style: TextStyle(color: _textColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(csv, style: TextStyle(color: _textColor, fontSize: 12)),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () { HapticFeedback.lightImpact();
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV copiato con successo negli appunti!')),
              );
            },
            icon: const Icon(Icons.download, color: Colors.white, size: 16),
            label: const Text('Scarica CSV', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Chiudi', style: TextStyle(color: _subtitleColor)),
          ),
        ],
      ),
    );
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('👤 Profilo & Cloud', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
                    Icon(Icons.cloud_sync, color: _primaryColor),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: Text('Utente Attivo', style: TextStyle(color: _subtitleColor, fontSize: 11)),
                  subtitle: Text(_nomeUtenteDinamico, style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                ListTile(
                  title: Text('Email Collegata', style: TextStyle(color: _subtitleColor, fontSize: 11)),
                  subtitle: Text(widget.userEmail, style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                ListTile(
                  title: Text('Stato Firebase Cloud', style: TextStyle(color: _subtitleColor, fontSize: 11)),
                  subtitle: const Text('Connesso in tempo reale', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                      onPressed: () async { HapticFeedback.lightImpact(); Navigator.pop(context); await FirebaseAuth.instance.signOut(); Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil("/", (route) => false); },
                  child: const Text('Disconnetti Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostraModalImpostazioni() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: _primaryColor),
                        const SizedBox(width: 8),
                        Text('⚙️ Impostazioni & Temi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text('Tema Attivo', style: TextStyle(color: _subtitleColor, fontSize: 11)),
                      subtitle: Text(_currentTheme, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _inviteController,
                      style: TextStyle(color: _textColor),
                      decoration: InputDecoration(
                        hintText: 'Email del partner da invitare',
                        hintStyle: TextStyle(color: _subtitleColor),
                        filled: true,
                        fillColor: _scaffoldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 16),
                    Text('🎨 Scegli Tema Grafico:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textColor)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC2185B)),
                          onPressed: () { HapticFeedback.lightImpact(); setState(() { _currentTheme = 'Piggy Dark'; }); SharedPreferences.getInstance().then((p) => p.setString("currentTheme", _currentTheme)); Navigator.pop(context); },
                          icon: const Icon(Icons.dark_mode, color: Colors.white, size: 16),
                          label: const Text('Piggy Dark', style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200),
                          onPressed: () { HapticFeedback.lightImpact(); setState(() { _currentTheme = 'Piggy White'; }); SharedPreferences.getInstance().then((p) => p.setString("currentTheme", _currentTheme)); Navigator.pop(context); },
                          icon: const Icon(Icons.light_mode, color: Colors.black87, size: 16),
                          label: const Text('Piggy White', style: TextStyle(color: Colors.black87)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  void _mostraModalNuovoObiettivo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("🎯 Nuovo Obiettivo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
              const SizedBox(height: 16),
              TextField(controller: _goalNameController, style: TextStyle(color: _textColor), decoration: InputDecoration(labelText: 'Nome Obiettivo (es. Viaggio)', labelStyle: TextStyle(color: _subtitleColor), fillColor: _scaffoldBg, filled: true)),
              const SizedBox(height: 12),
              TextField(controller: _goalTargetController, keyboardType: TextInputType.number, style: TextStyle(color: _textColor), decoration: InputDecoration(labelText: 'Target in € (es. 1500)', labelStyle: TextStyle(color: _subtitleColor), fillColor: _scaffoldBg, filled: true)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, minimumSize: const Size(double.infinity, 50)),
                onPressed: () { HapticFeedback.lightImpact();
                  if (_goalNameController.text.isNotEmpty && _goalTargetController.text.isNotEmpty) {
                    setState(() {
                      portafogli.add({
                        'nome': _goalNameController.text.trim(),
                        'target': double.tryParse(_goalTargetController.text.replaceAll(',', '.')) ?? 0.0,
                        'attuale': 0.0
                      });
                    });
                    _goalNameController.clear();
                    _goalTargetController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Crea Obiettivo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ]
          )
        );
      }
    );
  }

  void _aggiungiFondiObiettivo(int index) {
    final TextEditingController fundController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text("Finanzia: ${portafogli[index]['nome']}", style: TextStyle(color: _textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(controller: fundController, keyboardType: TextInputType.number, style: TextStyle(color: _textColor), decoration: InputDecoration(hintText: "Importo da aggiungere", hintStyle: TextStyle(color: _subtitleColor))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Annulla", style: TextStyle(color: _subtitleColor))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () { HapticFeedback.lightImpact();
              double val = double.tryParse(fundController.text.replaceAll(',', '.')) ?? 0.0;
              if (val > 0) {
                setState(() {
                  portafogli[index]['attuale'] += val;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Aggiungi", style: TextStyle(color: Colors.white))
          )
        ]
      )
    );
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("📋 Foglio Resoconto Cloud", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
                      IconButton(
                        icon: Icon(Icons.download, color: _primaryColor),
                        tooltip: 'Esporta CSV',
                        onPressed: () { HapticFeedback.lightImpact();
                          _esportaCSV();
                        },
                      ),
                    ],
                  ),
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
                onChanged: (val) => setState(() => _selectedCategory = val ?? '🐾 Animali')),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(labelText: "Note / Descrizione", labelStyle: TextStyle(color: _subtitleColor), filled: true, fillColor: _scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () { HapticFeedback.lightImpact();
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
    try {
      _nomeUtenteDinamico = widget.userEmail.split("@")[0];
      if (_nomeUtenteDinamico.isNotEmpty) {
        _nomeUtenteDinamico = _nomeUtenteDinamico[0].toUpperCase() + _nomeUtenteDinamico.substring(1);
      }
    } catch(e) {}
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🎯 Portafogli a Obiettivi", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textColor)),
                  const SizedBox(height: 12),
                  if (portafogli.isEmpty) Text("Nessun obiettivo attivo. Creane uno!", style: TextStyle(color: _subtitleColor, fontSize: 11)),
                  ...portafogli.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var goal = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(goal['nome'], style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
                            Text("€${goal['attuale'].toStringAsFixed(0)} / €${goal['target'].toStringAsFixed(0)}", style: TextStyle(color: _subtitleColor, fontSize: 11)),
                          ]
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: goal['target'] > 0 ? (goal['attuale'] / goal['target']).clamp(0.0, 1.0) : 0.0, backgroundColor: _scaffoldBg, color: _primaryColor, minHeight: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _aggiungiFondiObiettivo(idx),
                            child: Text("+ Aggiungi fondi", style: TextStyle(color: _primaryColor, fontSize: 12, fontWeight: FontWeight.bold))
                          )
                        ),
                        const SizedBox(height: 4),
                      ]
                    );
                  }).toList(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _scaffoldBg, elevation: 0, minimumSize: const Size(double.infinity, 40)),
                    onPressed: _mostraModalNuovoObiettivo,
                    icon: Icon(Icons.add, color: _primaryColor, size: 16),
                    label: Text("Crea Nuovo Obiettivo", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                  )
                ]
              )
            )
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 14),
          Card(
            color: _cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("📅 Promemoria e Scadenze", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textColor)),
                      Icon(Icons.notifications_active, color: _primaryColor, size: 18),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _promemoria.isEmpty
                      ? Text("Nessuna scadenza imminente. Aggiungi un promemoria!", style: TextStyle(color: _subtitleColor, fontSize: 11))
                      : Column(
                          children: _promemoria.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(p['titolo'].toString(), style: TextStyle(color: _textColor, fontSize: 12)),
                                Text(p['data'].toString(), style: TextStyle(color: _primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )).toList(),
                        ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor.withOpacity(0.1),
                        foregroundColor: _primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final TextEditingController titoloPromemoriaController = TextEditingController();
                        final TextEditingController dataPromemoriaController = TextEditingController(
                          text: "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}"
                        );

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: _cardBg,
                            title: Text("Aggiungi Scadenza", style: TextStyle(color: _textColor)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: titoloPromemoriaController,
                                  style: TextStyle(color: _textColor),
                                  decoration: InputDecoration(
                                    labelText: "Titolo Scadenza",
                                    labelStyle: TextStyle(color: _subtitleColor),
                                    hintText: "es. Affitto o Bolletta",
                                    hintStyle: TextStyle(color: _subtitleColor.withOpacity(0.5)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: dataPromemoriaController,
                                  style: TextStyle(color: _textColor),
                                  decoration: InputDecoration(
                                    labelText: "Data (DD/MM/YYYY)",
                                    labelStyle: TextStyle(color: _subtitleColor),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("Annulla", style: TextStyle(color: _subtitleColor)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
                                onPressed: () {
                                  if (titoloPromemoriaController.text.trim().isNotEmpty) {
                                    String titoloScadenza = titoloPromemoriaController.text.trim();
                                    String dataScadenza = dataPromemoriaController.text.trim();
                                    setState(() {
                                      _promemoria.add({
                                        'titolo': titoloScadenza,
                                        'data': dataScadenza,
                                      });
                                    });
                                    _salvaPromemoriaSuCloud();
                                    _mostraNotificaScadenza(titoloScadenza, dataScadenza);
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text("Salva", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text("+ Aggiungi Scadenza", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: _cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Builder(
                builder: (context) {
                  double rem = patrimonio;
                  double eProg = (rem >= 1000) ? 1.0 : (rem / 1000).clamp(0.0, 1.0);
                  rem -= 1000; if (rem < 0) rem = 0;
                  double cProg = (rem >= 10000) ? 1.0 : (rem / 10000).clamp(0.0, 1.0);
                  rem -= 10000; if (rem < 0) rem = 0;
                  double fProg = (rem >= 50000) ? 1.0 : (rem / 50000).clamp(0.0, 1.0);
                  rem -= 50000; if (rem < 0) rem = 0;
                  double pProg = (rem >= 100000) ? 1.0 : (rem / 100000).clamp(0.0, 1.0);

                  String aName = "Emergenze";
                  IconData aIcon = Icons.shield;
                  Color aColor = Colors.green;
                  double aCurrent = patrimonio;
                  double aTarget = 1000;
                  double aProg = eProg;

                  if (eProg >= 1.0) {
                    aName = "Cuscino";
                    aIcon = Icons.weekend;
                    aColor = Colors.blue;
                    aCurrent = patrimonio - 1000;
                    aTarget = 10000;
                    aProg = cProg;
                  }
                  if (cProg >= 1.0) {
                    aName = "Fortezza";
                    aIcon = Icons.castle;
                    aColor = Colors.purple;
                    aCurrent = patrimonio - 11000;
                    aTarget = 50000;
                    aProg = fProg;
                  }
                  if (fProg >= 1.0) {
                    aName = "Porcellone";
                    aIcon = Icons.savings;
                    aColor = _primaryColor;
                    aCurrent = patrimonio - 61000;
                    aTarget = 100000;
                    aProg = pProg;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(aIcon, color: aColor, size: 22),
                              const SizedBox(width: 8),
                              Text("🏆 Livelli Risparmio", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textColor)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: _scaffoldBg, borderRadius: BorderRadius.circular(12)),
                            child: Text("Livello: $aName", style: TextStyle(fontSize: 11, color: aColor, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Obiettivo Attuale", style: TextStyle(fontSize: 11, color: _subtitleColor)),
                          Text("€ ${aCurrent.toStringAsFixed(0)} / ${aTarget.toStringAsFixed(0)}€", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: aProg, backgroundColor: _scaffoldBg, color: aColor, minHeight: 8),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () => _mostraDettaglioLivello("1. Emergenze", "1.000€", "Fondo di prima sicurezza per imprevisti urgenti.", Icons.shield, Colors.green),
                            child: _buildTappaBadge("Emergenze", "1.000€", Icons.shield, Colors.green, eProg >= 1.0),
                          ),
                          GestureDetector(
                            onTap: () => _mostraDettaglioLivello("2. Cuscino", "10.000€", "Cuscino finanziario per una tranquillità a medio termine.", Icons.weekend, Colors.blue),
                            child: _buildTappaBadge("Cuscino", "10.000€", Icons.weekend, Colors.blue, cProg >= 1.0),
                          ),
                          GestureDetector(
                            onTap: () => _mostraDettaglioLivello("3. Fortezza", "50.000€", "Solida fortezza patrimoniale per investimenti e stabilità.", Icons.castle, Colors.purple),
                            child: _buildTappaBadge("Fortezza", "50.000€", Icons.castle, Colors.purple, fProg >= 1.0),
                          ),
                          GestureDetector(
                            onTap: () => _mostraDettaglioLivello("4. Porcellone", "100.000€", "Il traguardo supremo del caveau finanziario!", Icons.savings, _primaryColor),
                            child: _buildTappaBadge("Porcellone", "100.000€", Icons.savings, _primaryColor, pProg >= 1.0),
                          ),
                        ],
                      ),
                    ],
                  );
                },
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
                onPressed: () async { HapticFeedback.lightImpact();
                  if (currentEmail != null) {
                    await FirebaseFirestore.instance.collection('inviti').doc(currentEmail).delete();
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Rifiuta', style: TextStyle(color: Colors.red))),
              ElevatedButton(
                onPressed: () async { HapticFeedback.lightImpact();
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
