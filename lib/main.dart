import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FamilyBudgetApp());
}

class FamilyBudgetApp extends StatelessWidget {
  const FamilyBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piggy Vault',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFE91E63),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE91E63),
          secondary: Color(0xFF00E676),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  bool _isPinMode = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      bool canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (canAuthenticate) {
        bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Autenticati per accedere a Piggy Vault',
          options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
        );
        if (didAuthenticate) {
          _navigateToHome();
        }
      }
    } catch (e) {
      setState(() { _isPinMode = true; });
    }
  }

  void _verifyPin() {
    if (_pinController.text == "1234") {
      _navigateToHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PIN errato. Usa 1234 di default.")),
      );
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen(userEmail: "marco@piggyvault.app")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.savings, size: 90, color: Color(0xFFE91E63)),
              const SizedBox(height: 20),
              const Text("Piggy Vault", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              const Text("Il tuo salvadanaio e assistente finanziario", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              if (!_isPinMode)
                ElevatedButton.icon(
                  onPressed: _checkBiometrics,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text("Accedi con Biometria"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63), foregroundColor: Colors.white),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Inserisci PIN (es. 1234)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _verifyPin,
                child: const Text("Sblocca con PIN"),
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  double patrimonio = 1250.0;
  double entrateMese = 2400.0;
  double usciteMese = 1150.0;
  String _currentTheme = 'Piggy Dark';
  String _piggyTone = "Spietato";
  String _nomeUtenteDinamico = "Marco";
  bool isAiLoading = false;
  
  List<dynamic> transazioni = [
    {"category": "🛒 Spesa", "note": "Supermercato", "amount": 85.50, "type": "Uscita (Spesa)", "author": "Marco"},
    {"category": "💼 Lavoro", "note": "Stipendio", "amount": 2400.0, "type": "Entrata", "author": "Marco"},
    {"category": "🐾 Animali", "note": "Veterinario Roi", "amount": 60.0, "type": "Uscita (Spesa)", "author": "Marco"}
  ];
  List<dynamic> portafogli = [
    {"nome": "Fondo Emergenza", "target": 1000.0, "attuale": 450.0}
  ];
  List<dynamic> _promemoria = [
    {"titolo": "Bolletta Luce", "data": "20-10-2026"}
  ];

  final List<String> categorieConEmoji = [
    '🛒 Spesa', '🐾 Animali', '🏠 Casa', '💡 Bollette', '🚗 Auto', '🎉 Svago', '💼 Lavoro'
  ];

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _goalTargetController = TextEditingController();
  
  String _selectedType = 'Uscita (Spesa)';
  String _selectedCategory = '🛒 Spesa';

  Color get _scaffoldBg => _currentTheme == 'Piggy Dark' ? const Color(0xFF121212) : Colors.grey.shade100;
  Color get _cardBg => _currentTheme == 'Piggy Dark' ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textColor => _currentTheme == 'Piggy Dark' ? Colors.white : Colors.black87;
  Color get _subtitleColor => _currentTheme == 'Piggy Dark' ? Colors.grey.shade400 : Colors.grey.shade600;
  Color get _primaryColor => const Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _caricaPreferenze();
  }

  void _caricaPreferenze() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTheme = prefs.getString("selectedTheme") ?? 'Piggy Dark';
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _mostraModalProfilo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Profilo Utente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
            const SizedBox(height: 10),
            Text("Email: ${widget.userEmail}", style: TextStyle(color: _subtitleColor)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Chiudi"),
            )
          ],
        ),
      ),
    );
  }

  void _mostraModalImpostazioni() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Impostazioni e Temi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
            const SizedBox(height: 20),
            ListTile(
              title: Text("Tema Scuro (Piggy Dark)", style: TextStyle(color: _textColor)),
              trailing: Radio<String>(
                value: 'Piggy Dark',
                groupValue: _currentTheme,
                onChanged: (val) {
                  setState(() { _currentTheme = val!; });
                  SharedPreferences.getInstance().then((p) => p.setString("selectedTheme", _currentTheme));
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text("Tema Chiaro (Piggy White)", style: TextStyle(color: _textColor)),
              trailing: Radio<String>(
                value: 'Piggy White',
                groupValue: _currentTheme,
                onChanged: (val) {
                  setState(() { _currentTheme = val!; });
                  SharedPreferences.getInstance().then((p) => p.setString("selectedTheme", _currentTheme));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostraModalNuovoObiettivo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("🎯 Nuovo Obiettivo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
            const SizedBox(height: 16),
            TextField(controller: _goalNameController, style: TextStyle(color: _textColor), decoration: InputDecoration(labelText: 'Nome Obiettivo')),
            const SizedBox(height: 12),
            TextField(controller: _goalTargetController, keyboardType: TextInputType.number, style: TextStyle(color: _textColor), decoration: InputDecoration(labelText: 'Target in €')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
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
              child: const Text("Crea Obiettivo"),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _aggiungiFondiObiettivo(int index) {
    final TextEditingController fundController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text("Finanzia: ${portafogli[index]['nome']}", style: TextStyle(color: _textColor)),
        content: TextField(controller: fundController, keyboardType: TextInputType.number, style: TextStyle(color: _textColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
          ElevatedButton(
            onPressed: () {
              double val = double.tryParse(fundController.text.replaceAll(',', '.')) ?? 0.0;
              if (val > 0) {
                setState(() { portafogli[index]['attuale'] += val; });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Aggiungi"),
          )
        ],
      ),
    );
  }

  void _mostraModalInserimento() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 24),
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
              items: const [
                DropdownMenuItem(value: 'Uscita (Spesa)', child: Text("🔴 Uscita (Spesa)")),
                DropdownMenuItem(value: 'Entrata (Guadagno)', child: Text("🟢 Entrata (Guadagno)"))
              ],
              onChanged: (val) => setState(() => _selectedType = val ?? 'Uscita (Spesa)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              style: TextStyle(color: _textColor),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Importo (€)"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: _cardBg,
              style: TextStyle(color: _textColor),
              items: categorieConEmoji.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val ?? '🛒 Spesa'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              style: TextStyle(color: _textColor),
              decoration: const InputDecoration(labelText: "Nota / Descrizione"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
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
                  _noteController.clear();
                  _amountController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text("Registra Transazione"),
            )
          ],
        ),
      ),
    );
  }

  void _mostraPiggyAI(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.psychology, size: 48, color: Color(0xFFE91E63)),
            const SizedBox(height: 12),
            Text("Piggy AI Assistant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
            const SizedBox(height: 12),
            Text("Ciao Marco! Analizzando il tuo caveau, la gestione finanziaria è stabile. Continua così e tieni d'occhio le spese superflue.", style: TextStyle(color: _subtitleColor)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Chiudi"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        title: Text("Piggy Vault", style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
        backgroundColor: _cardBg,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: _primaryColor),
            onPressed: _mostraModalImpostazioni,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        onPressed: () => _mostraPiggyAI(context),
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: _cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("PATRIMONIO CONDIVISO", style: TextStyle(fontSize: 10, color: _subtitleColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("€ ${patrimonio.toStringAsFixed(2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Card(
                  color: _cardBg,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ENTRATE", style: TextStyle(fontSize: 9, color: _subtitleColor)),
                        Text("€ ${entrateMese.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  color: _cardBg,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("USCITE", style: TextStyle(fontSize: 9, color: _subtitleColor)),
                        Text("€ ${usciteMese.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: _mostraModalInserimento,
            child: const Text("+ Nuova Transazione", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 16),
          Text("Ultime Transazioni", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textColor)),
          const SizedBox(height: 8),
          ...transazioni.map((tx) => Card(
            color: _cardBg,
            child: ListTile(
              title: Text(tx['category'], style: TextStyle(fontWeight: FontWeight.bold, color: _textColor)),
              subtitle: Text("${tx['note']} • ${tx['author']}", style: TextStyle(color: _subtitleColor)),
              trailing: Text(
                "${tx['type'].contains('Entrata') ? '+' : '-'}€${tx['amount'].toStringAsFixed(2)}",
                style: TextStyle(
                  color: tx['type'].contains('Entrata') ? Colors.greenAccent : _primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
