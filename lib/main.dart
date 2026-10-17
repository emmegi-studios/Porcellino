import 'package:http/http.dart' as http;
import 'package:home_widget/home_widget.dart';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final String _geminiApiKey = utf8.decode(base64Decode("QVEuQWI4Uk42SWVuaHUyOVV5Um1neV9xQXd0bmdkUEJ1OURhc204Q0F1Q2gyTDE0YXhULVE="));








































void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  } catch(e) {
    print("Errore init notifiche: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('selectedTheme') ?? 'Piggy Dark';
  runApp(PiggyVaultApp(initialTheme: savedTheme));
}

class PiggyVaultApp extends StatelessWidget {
  final String initialTheme;
  const PiggyVaultApp({super.key, this.initialTheme = 'Piggy Dark'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piggy Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF13131A),
        colorScheme: const ColorScheme.dark(
          primary: Colors.pinkAccent,
          surface: Color(0xFF1E1E2C),
        ),
      ),
      home: AuthGate(initialTheme: initialTheme),
    );
  }
}

class AuthGate extends StatelessWidget {
  final String initialTheme;
  const AuthGate({super.key, required this.initialTheme});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
      body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return InviteManager(child: HomeScreen(userEmail: FirebaseAuth.instance.currentUser?.email ?? 'Nessuna Email'));
        }
        return LoginScreen(initialTheme: initialTheme);
      });
  }
}

class LoginScreen extends StatefulWidget {
  final String initialTheme;
  const LoginScreen({super.key, this.initialTheme = 'Piggy Dark'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isRegistrazione = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  late bool _isDarkTheme;

  @override
  void initState() {
    super.initState();
    HomeWidget.initiallyLaunchedFromHomeWidget().then((Uri? uri) {
      if (uri != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _mostraPiggyAI(context, _isDarkTheme);
        });
      }
    });
    HomeWidget.widgetClicked.listen((Uri? uri) {
      if (mounted) _mostraPiggyAI(context, _isDarkTheme);
    });

    _isDarkTheme = (widget.initialTheme == 'Piggy Dark');
    _loadTheme();
    _loadSavedEmail();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDarkTheme = prefs.getString('selectedTheme') == 'Piggy Dark';
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
    final _scaffoldBg = _isDarkTheme ? const Color(0xFF0F111A) : const Color(0xFF282035);
    final _textColor = _isDarkTheme ? Colors.white : Colors.black87;
    final _subtitleColor = _isDarkTheme ? Colors.grey.shade400 : const Color(0xFF475569);
    final _primaryColor = Colors.pinkAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF13131A),

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
                  floatingLabelStyle: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
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
                  floatingLabelStyle: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
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
                  floatingLabelStyle: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
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
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Color(0xFF666666)),
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

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = prefs.getString('selectedTheme') == 'Piggy Dark';
    });
  }

  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('piggy_is_dark', isDark);
    setState(() {
      _isDarkTheme = isDark;
    });
  }

  List<Map<String, dynamic>> _promemoria = [];

  void _mostraNotificaScadenza(String titolo, String data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scadenza aggiunta: $titolo ($data)'),
        backgroundColor: Colors.pinkAccent,
      ),
    );
  }



  bool _isDarkTheme = false;
  String _piggyTone = "Piggy Vault";



  String _getSystemPromptForCurrentTone() => "Sei l'assistente Piggy Vault.";






    Future<void> _mostraInfoApp(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Row(
          children: [
            Icon(Icons.savings, color: Colors.pinkAccent),
            SizedBox(width: 8),
            Text('Piggy Vault', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versione: 2.5 Ultimate', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 8),
            Text('Sviluppato da EmmeGi Studios', style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Assistente Cibernetico: Cyber-Piggy (Modello Terminator v2.5)', style: TextStyle(color: Colors.white60, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi', style: TextStyle(color: Colors.pinkAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _verificaAggiornamentiOTA(BuildContext context) async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E2235),
          title: const Text('Aggiornamenti 🚀', style: TextStyle(color: Colors.white)),
          content: const Text('Sei già sulla versione più recente di Piggy Vault v2.0.0!\n\nIl server OTA non ha nuove versioni al momento.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ottimo!', style: TextStyle(color: Colors.pinkAccent)),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore OTA: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }


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


  @override
  void initState() {
    super.initState();

    // Ascoltatore Notifiche Push in Foreground (In tempo reale)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(message.notification!.title ?? 'Nuova attività nel Caveau 🐷', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(message.notification!.body ?? '', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              duration: const Duration(seconds: 4),
              margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
            ),
          );
        }
      }
    });

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
      backgroundColor: const Color(0xFF13131A),
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
  Color get _cardBg => _isDarkTheme ? const Color(0xFF1E2235) : Colors.white;
  Color get _textColor => _currentTheme == 'Piggy White' ? Colors.black87 : Colors.white;
  Color get _subtitleColor => _isDarkTheme ? Colors.grey.shade400 : const Color(0xFF334155);
  Color get _primaryColor => Colors.pinkAccent;
  Color get _scaffoldBg => _isDarkTheme ? const Color(0xFF0F111A) : Colors.grey.shade100;

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
      _currentTheme = prefs.getString('selectedTheme') ?? 'Piggy Dark';
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
    await prefs.setString('selectedTheme', _currentTheme);

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
    showModalBottomSheet(context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1528) : Colors.white,
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
    showModalBottomSheet(context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1528) : Colors.white,
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
                          onPressed: () { HapticFeedback.lightImpact(); setState(() { _currentTheme = 'Piggy Dark'; }); SharedPreferences.getInstance().then((p) => p.setString("selectedTheme", _currentTheme)); Navigator.pop(context); },
                          icon: const Icon(Icons.dark_mode, color: Colors.white, size: 16),
                          label: const Text('Piggy Dark', style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200),
                          onPressed: () { HapticFeedback.lightImpact(); setState(() { _currentTheme = 'Piggy White'; }); SharedPreferences.getInstance().then((p) => p.setString("selectedTheme", _currentTheme)); Navigator.pop(context); },
                          icon: const Icon(Icons.light_mode, color: Colors.black87, size: 16),
                          label: const Text('Piggy White', style: TextStyle(color: Colors.black87)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: _textColor.withOpacity(0.2)),
                    ListTile(
                      leading: Icon(Icons.info_outline, color: _textColor.withOpacity(0.7)),
                      title: Text('Info & Crediti', style: TextStyle(color: _textColor)),
                      onTap: () => _mostraInfoApp(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.system_update, color: Colors.greenAccent),
                      title: Text('Cerca Aggiornamenti', style: TextStyle(color: _textColor)),
                      onTap: () => _verificaAggiornamentiOTA(context),
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
    showModalBottomSheet(context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1528) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("🎯 Nuovo Obiettivo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
              const SizedBox(height: 16),
              TextField(controller: _goalNameController, style: TextStyle(color: _textColor), decoration: InputDecoration(labelText: 'Nome Obiettivo (es. Viaggio)', labelStyle: TextStyle(color: _subtitleColor),
                  floatingLabelStyle: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold), fillColor: _scaffoldBg, filled: true)),
              const SizedBox(height: 12),
              TextField(controller: _goalTargetController, keyboardType: TextInputType.number, style: TextStyle(color: _textColor), decoration: InputDecoration(labelText: 'Target in € (es. 1500)', labelStyle: TextStyle(color: _subtitleColor),
                  floatingLabelStyle: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold), fillColor: _scaffoldBg, filled: true)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
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

  
  Widget _buildRipartizioneSpeseCard() {
    final Map<String, double> spesaPerCategoria = {};
    double totaleUsciteCalcolato = 0.0;

    for (var tx in transazioni) {
      final String type = (tx['type'] ?? '').toString();
      if (!type.contains('Entrata')) {
        final String cat = (tx['category'] ?? 'Altro').toString();
        final double amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
        spesaPerCategoria[cat] = (spesaPerCategoria[cat] ?? 0.0) + amt;
        totaleUsciteCalcolato += amt;
      }
    }

    return Card(
      color: _cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.pinkAccent),
                const SizedBox(width: 8),
                Text("Ripartizione Spese", style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            if (spesaPerCategoria.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Nessuna uscita registrata finora.", style: TextStyle(color: _subtitleColor, fontSize: 13)),
              )
            else
              ...spesaPerCategoria.entries.map((entry) {
                final double percentuale = totaleUsciteCalcolato > 0 ? (entry.value / totaleUsciteCalcolato) : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(entry.key, style: TextStyle(color: _textColor, fontSize: 13), overflow: TextOverflow.ellipsis)),
                          Text("€ ${entry.value.toStringAsFixed(2)} (${(percentuale * 100).toStringAsFixed(0)}%)",
                              style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentuale,
                          backgroundColor: Colors.white10,
                          color: Colors.pinkAccent,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _mostraFoglioResoconto() {
    double bilancioNetto = entrateMese - usciteMese;
    showModalBottomSheet(context: context,
      isScrollControlled: true, backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1528) : Colors.white,
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
    showModalBottomSheet(context: context,
      isScrollControlled: true, backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1528) : Colors.white,
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
                decoration: InputDecoration(labelText: "Tipo", labelStyle: TextStyle(color: _subtitleColor),
                  floatingLabelStyle: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold), filled: true, fillColor: _scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: const [
                  DropdownMenuItem(value: 'Uscita (Spesa)', child: Text("🔴 Uscita (Spesa)")),
                  DropdownMenuItem(value: 'Entrata (Guadagno)', child: Text("🟢 Entrata (Guadagno)"))],
                onChanged: (val) => setState(() => _selectedType = val ?? 'Uscita (Spesa)')),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                style: TextStyle(color: _textColor),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Importo (€)", labelStyle: TextStyle(color: _subtitleColor),
                  floatingLabelStyle: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold), filled: true, fillColor: _scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: _cardBg,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(labelText: "Categoria", labelStyle: TextStyle(color: _subtitleColor),
                  floatingLabelStyle: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold), filled: true, fillColor: _scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: categorieConEmoji.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val ?? '🐾 Animali')),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(labelText: "Note / Descrizione", labelStyle: TextStyle(color: _subtitleColor),
                  floatingLabelStyle: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold), filled: true, fillColor: _scaffoldBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
        backgroundColor: _scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
                  child: const Image(image: AssetImage('assets/images/piggy_ai_assistant.png'), width: 24, height: 24)))),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostraPiggyAI(context, _isDarkTheme),
        elevation: 6,
        child: ClipOval(
          child: Image.asset(
            'assets/images/piggy_ai_assistant.png',
            width: 48, height: 48, fit: BoxFit.cover,
            errorBuilder: (c, e, s) => const Icon(Icons.savings, color: Colors.white, size: 28),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
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
                      Text("PATRIMONIO CONDIVISO", style: TextStyle(fontSize: 10, color: Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white70, fontWeight: FontWeight.bold)),
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
                        LinearProgressIndicator(value: goal['target'] > 0 ? (goal['attuale'] / goal['target']).clamp(0.0, 1.0) : 0.0, color: _primaryColor, minHeight: 6),
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
                  floatingLabelStyle: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
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
                  floatingLabelStyle: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
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




  bool _isListening = false;
  final Set<String> _readMessages = {};

  

  

  



  
  
  
  
  
                                                                            Future<String> _getGeminiResponse(String prompt) async {
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [{"text": prompt}]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text.isNotEmpty) return text;
      }

      // Fallback su gemini-2.0-flash se 1.5-flash restituisce errore di rotta
      final url2 = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiApiKey');
      final response2 = await http.post(
        url2,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [{"text": prompt}]
            }
          ]
        }),
      );

      if (response2.statusCode == 200) {
        final data2 = jsonDecode(response2.body);
        final text2 = data2['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text2 != null && text2.isNotEmpty) return text2;
      }

      return "⚠️ Errore risposta Piggy AI (${response.statusCode}). Riprova tra poco.";
    } catch (e) {
      return "❌ Errore di connessione Piggy AI: $e";
    }
  }

void _mostraPiggyAI(BuildContext context, [bool? isDarkOverride]) {
    final bool isDark = isDarkOverride ?? (Theme.of(context).brightness == Brightness.dark);
    final TextEditingController modalInputController = TextEditingController();
    final SpeechToText speechToText = SpeechToText();
    bool isListening = false;

    double saldoTotale = 0.0;
    double totaleUscite = 0.0;
    double totaleEntrate = 0.0;

    try {
      if ('0.0' != '0.0') saldoTotale = (0.0 as num).toDouble();
      if ('0.0' != '0.0') totaleUscite = (0.0 as num).toDouble();
      if ('0.0' != '0.0') totaleEntrate = (0.0 as num).toDouble();
    } catch (_) {}

    int caveauShieldScore = 100;
    if (totaleEntrate > 0) {
      double rapportoUscite = (totaleUscite / totaleEntrate) * 100;
      caveauShieldScore = (100 - rapportoUscite).clamp(10, 100).toInt();
    } else if (saldoTotale <= 0) {
      caveauShieldScore = 20;
    }

    final List<Map<String, String>> chatMessages = [
      {
        "sender": "piggy",
        "text": "🛡️ Unità Piggy AI v2.2.9 collegata a Gemini 1.5 Flash. Caveau Shield Score: $caveauShieldScore%."
      }
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF12131C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            void inviaMessaggioAI() async {
              final text = modalInputController.text.trim();
              if (text.isEmpty) return;

              setStateModal(() {
                chatMessages.add({"sender": "user", "text": text});
                chatMessages.add({"sender": "piggy", "text": "⏳ Elaborazione in corso..."});
                modalInputController.clear();
              });

              try {
                final response = await _getGeminiResponse(text);
                setStateModal(() {
                  chatMessages.removeLast();
                  chatMessages.add({"sender": "piggy", "text": response});
                });
              } catch (e) {
                setStateModal(() {
                  chatMessages.removeLast();
                  chatMessages.add({"sender": "piggy", "text": "❌ Errore di connessione con l'unità Piggy AI."});
                });
              }
            }

            void avviaRiconoscimentoVocale() async {
              if (isListening) {
                await speechToText.stop();
                setStateModal(() => isListening = false);
                return;
              }

              try {
                bool available = await speechToText.initialize(
                  onError: (val) {
                    setStateModal(() => isListening = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Errore microfono: ${val.errorMsg}"), backgroundColor: Colors.redAccent),
                    );
                  },
                  onStatus: (val) {
                    if (val == 'done' || val == 'notListening') {
                      setStateModal(() => isListening = false);
                    }
                  },
                );

                if (available) {
                  setStateModal(() => isListening = true);
                  speechToText.listen(
                    onResult: (val) {
                      setStateModal(() {
                        modalInputController.text = val.recognizedWords;
                        modalInputController.selection = TextSelection.fromPosition(
                          TextPosition(offset: modalInputController.text.length),
                        );
                      });
                      if (val.finalResult) {
                        setStateModal(() => isListening = false);
                      }
                    },
                    listenFor: const Duration(seconds: 45),
                    pauseFor: const Duration(seconds: 5),
                    partialResults: true,
                  );
                } else {
                  setStateModal(() => isListening = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Riconoscimento vocale non disponibile. Verifica i permessi."),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                }
              } catch (e) {
                setStateModal(() => isListening = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Errore avvio vocale: $e"), backgroundColor: Colors.redAccent),
                );
              }
            }

            final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: keyboardPadding),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/piggy_ai_assistant.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.smart_toy, color: Colors.pinkAccent, size: 28),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text("Piggy AI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.pinkAccent),
                          ),
                          child: Text("🛡️ $caveauShieldScore%", style: const TextStyle(color: Colors.pinkAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D1B28), foregroundColor: Colors.pinkAccent),
                            onPressed: () {
                              modalInputController.text = "Dammi un consiglio sui miei risparmi";
                              inviaMessaggioAI();
                            },
                            icon: const Icon(Icons.auto_awesome, size: 14),
                            label: const Text("Consiglio", style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2A3A), foregroundColor: Colors.blueAccent),
                            onPressed: () {
                              modalInputController.text = "Cosa succede se risparmio 50€ in più?";
                              inviaMessaggioAI();
                            },
                            icon: const Icon(Icons.psychology, size: 14),
                            label: const Text("What-If", style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: chatMessages.length,
                        itemBuilder: (context, idx) {
                          final msg = chatMessages[idx];
                          final isUser = msg["sender"] == "user";
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.pinkAccent : const Color(0xFF1E2235),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg["text"] ?? "",
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: modalInputController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: isListening ? "Listening..." : "Chiedi a Piggy AI...",
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFF1E2235),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (_) => inviaMessaggioAI(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: avviaRiconoscimentoVocale,
                          icon: Icon(isListening ? Icons.mic : Icons.mic_none, color: isListening ? Colors.redAccent : Colors.pinkAccent),
                        ),
                        IconButton(
                          onPressed: inviaMessaggioAI,
                          icon: const Icon(Icons.send, color: Colors.pinkAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  // Aggiornamento sicuro del Widget in base allo stato di autenticazione
  Future<void> _updateAndroidWidget(bool isLoggedIn, double patrimonio) async {
    try {
      if (isLoggedIn) {
        await HomeWidget.saveWidgetData<String>('widget_patrimonio', 'Caveau: € ' + patrimonio.toStringAsFixed(2));
        await HomeWidget.saveWidgetData<String>('widget_status', 'Stato: Monitoraggio Attivo');
        await HomeWidget.saveWidgetData<bool>('widget_logged', true);
      } else {
        await HomeWidget.saveWidgetData<String>('widget_patrimonio', '🔒 Caveau Bloccato');
        await HomeWidget.saveWidgetData<String>('widget_status', 'Effettua il login in app');
        await HomeWidget.saveWidgetData<bool>('widget_logged', false);
      }
      await HomeWidget.updateWidget(
        name: 'PiggyWidgetProvider',
        androidName: 'PiggyWidgetProvider',
      );
    } catch (_) {}
  }

  // Widget indicatore di rischio dinamico per il budget
  Widget _buildBarraRischioBudget(double speseCorrenti, double budgetTotale) {
    double percentuale = budgetTotale > 0 ? (speseCorrenti / budgetTotale) : 0.0;
    if (percentuale > 1.0) percentuale = 1.0;

    Color coloreRischio;
    String statoRischio;
    String messaggioRischio;

    if (percentuale < 0.6) {
      coloreRischio = Colors.greenAccent;
      statoRischio = 'VERDE: Puoi spendere';
      messaggioRischio = 'Il caveau è in piena sicurezza. I flussi sono stabili.';
    } else if (percentuale < 0.85) {
      coloreRischio = Colors.amberAccent;
      statoRischio = 'GIALLO: Spendi con moderazione';
      messaggioRischio = 'Attenzione alle unità organiche: le spese si avvicinano alla soglia di guardia.';
    } else {
      coloreRischio = Colors.redAccent;
      statoRischio = 'ROSSO: Pericolo stabilità!';
      messaggioRischio = 'Spendere ancora potrebbe compromettere la stabilità energetica del caveau!';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: coloreRischio.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Stato Rischio Caveau', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: coloreRischio.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(statoRischio, style: TextStyle(color: coloreRischio, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentuale,
              minHeight: 10,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(coloreRischio),
            ),
          ),
          const SizedBox(height: 8),
          Text(messaggioRischio, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }
}

String _sanitizeTextForTTS(String input) {
  String clean = input;
  clean = clean.replaceAll(RegExp(r'\\rightarrow|\\infty|\\|\$', caseSensitive: false), '');
  clean = clean.replaceAll(RegExp(r'\*.*?\*'), '');
  clean = clean.replaceAll(RegExp(r'\[.*?\]'), '');
  clean = clean.replaceAll(RegExp(r'\.exe', caseSensitive: false), '');
  clean = clean.replaceAll(RegExp(r'\*+'), '');
  clean = clean.replaceAll(RegExp(r'#+'), '');
  clean = clean.replaceAll(RegExp(r'[\-\_]+'), ' ');
  clean = clean.replaceAll(RegExp(r'^\s*[\d\.\)]+\s*', multiLine: true), '');
  clean = clean.replaceAll(RegExp(r'\b\d+\.\s*'), '');
  clean = clean.replaceAll(RegExp(r'[\(\)]'), '');
  return clean.trim();
}
