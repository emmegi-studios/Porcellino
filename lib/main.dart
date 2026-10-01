import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Errore Firebase: $e");
  }
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
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFDB2777),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF0F172A),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Color(0xFFDB2777))),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
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
  final _nameController = TextEditingController();
  bool isRegistering = false;
  String errorMessage = '';

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = "Compila tutti i campi obbligatori.");
      return;
    }

    try {
      if (isRegistering) {
        if (name.isEmpty) {
          setState(() => errorMessage = "Inserisci il tuo nome utente.");
          return;
        }
        if (password != _confirmPasswordController.text.trim()) {
          setState(() => errorMessage = "Le password non coincidono.");
          return;
        }
        if (password.length < 6) {
          setState(() => errorMessage = "La password deve essere di almeno 6 caratteri.");
          return;
        }
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await cred.user?.sendEmailVerification();
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      }
    } catch (e) {
      setState(() => errorMessage = "Errore: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDB2777),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text("🪙", style: TextStyle(fontSize: 40))),
                ),
                const SizedBox(height: 16),
                const Text("Piggy Vault", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text("Smart Wealth Management", style: TextStyle(fontSize: 12, color: Color(0xFFF472B6))),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isRegistering ? "Crea un nuovo account" : "Accedi all'applicazione", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (errorMessage.isNotEmpty) ...[
                        Text(errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                        const SizedBox(height: 12),
                      ],
                      if (isRegistering) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Nome Utente (es. Marco)",
                            prefixIcon: Icon(Icons.person, color: Color(0xFFDB2777)),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Indirizzo Email",
                          prefixIcon: Icon(Icons.email, color: Color(0xFFDB2777)),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock, color: Color(0xFFDB2777)),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDB2777),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _submitAuth,
                        child: Text(
                          isRegistering ? "Registrati" : "Accedi",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isRegistering = !isRegistering;
                            errorMessage = '';
                          });
                        },
                        child: Center(
                          child: Text(
                            isRegistering ? "Hai già un account? Accedi qui" : "Non hai un account? Registrati ora",
                            style: const TextStyle(color: Color(0xFFF472B6), fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool isShared = true;

  String get pathPrefix => isShared ? "shared" : "private_${FirebaseAuth.instance.currentUser?.uid ?? 'user'}";
  String get username => FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Marco';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFDB2777),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text("🪙", style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text("Piggy Vault", style: TextStyle(fontSize: 10, color: Color(0xFFF472B6))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.pinkAccent),
            onPressed: () => _openSettingsDialog(context),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('${pathPrefix}_transactions').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          List<Map<String, dynamic>> items = [];
          double patrimonio = 0;
          double entrateMese = 0;
          double usciteMese = 0;

          if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
            try {
              Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              map.forEach((key, value) {
                if (value is Map) {
                  items.add({"id": key, ...Map<String, dynamic>.from(value)});
                }
              });
              items.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));

              final now = DateTime.now();
              for (var item in items) {
                double amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                String type = item['type'] ?? 'uscita';
                DateTime txDate = DateTime.tryParse(item['createdAt'] ?? '') ?? now;
                bool isCurrentMonth = txDate.month == now.month && txDate.year == now.year;

                if (type == 'entrata') {
                  patrimonio += amount;
                  if (isCurrentMonth) entrateMese += amount;
                } else {
                  patrimonio -= amount;
                  if (isCurrentMonth) usciteMese += amount;
                }
              }
            } catch (_) {}
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: const Color(0xFF0F172A),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("ENTRATE MESE", style: TextStyle(fontSize: 9, color: Colors.grey)),
                            Text("€ ${entrateMese.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      color: const Color(0xFF0F172A),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("USCITE MESE", style: TextStyle(fontSize: 9, color: Colors.grey)),
                            Text("€ ${usciteMese.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDB2777))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text("📜 STORICO TRANSAZIONI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: Text("Nessuna transazione registrata.", style: TextStyle(fontSize: 12, color: Colors.grey))),
                ),
              ...items.map((tx) => Card(
                    color: const Color(0xFF0F172A),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(tx['category'] ?? 'Spesa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text("${tx['note'] ?? ''} • ${tx['createdBy'] ?? ''}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      trailing: Text(
                        "${tx['type'] == 'entrata' ? '+' : '-'}€ ${(tx['amount'] as num).toDouble().toStringAsFixed(2)}",
                        style: TextStyle(fontWeight: FontWeight.bold, color: tx['type'] == 'entrata' ? const Color(0xFF10B981) : const Color(0xFFDB2777)),
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFDB2777),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          final amountController = TextEditingController();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              title: const Text("Nuova Transazione"),
              content: TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Importo (€)")),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777)),
                  onPressed: () {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount > 0) {
                      FirebaseDatabase.instance.ref('${pathPrefix}_transactions').push().set({
                        'type': 'uscita',
                        'amount': amount,
                        'category': 'Spesa',
                        'note': 'Transazione',
                        'createdBy': username,
                        'createdAt': DateTime.now().toIso8601String(),
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Salva"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("Impostazioni"),
        content: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () {
            Navigator.pop(context);
            FirebaseAuth.instance.signOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text("Disconnetti Account"),
        ),
      ),
    );
  }
}
