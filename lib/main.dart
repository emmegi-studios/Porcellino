import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCA9XmgopjNTzdkhDnw60fMx-sxD8e9SM8",
      authDomain: "porcellino-b2841.firebaseapp.com",
      databaseURL: "https://porcellino-b2841-default-rtdb.europe-west1.firebasedatabase.app",
      projectId: "porcellino-b2841",
      storageBucket: "porcellino-b2841.firebasestorage.app",
      messagingSenderId: "629577093985",
      appId: "1:629577093985:web:e1f59170285d7da80dab20",
    ),
  );
  runApp(const PorcellinoApp());
}

class PorcellinoApp extends StatelessWidget {
  const PorcellinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Porcellino',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020617),
        cardColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFDB2777),
          secondary: Color(0xFF10B981),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
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
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _quickLogin(String name) async {
    final email = "${name.toLowerCase()}@porcellino.app";
    const pass = "porcellino123";
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
    } catch (_) {
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
      await cred.user?.updateDisplayName(name);
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
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFDB2777),
                child: Text("🐷", style: TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: 16),
              const Text(
                "Porcellino Native",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Text(
                "Personal & Shared Finance",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _quickLogin("Marco"),
                      icon: const Text("👤"),
                      label: const Text("Marco", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _quickLogin("Marika"),
                      icon: const Text("👤"),
                      label: const Text("Marika", style: TextStyle(color: Color(0xFFF472B6))),
                    ),
                  ),
                ],
              ),
            ],
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
  bool isShared = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? user?.email?.split('@')[0] ?? 'Utente';
    final pathPrefix = isShared ? 'shared' : 'personal/${user?.uid}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Row(
          children: [
            const Text("🐷 ", style: TextStyle(fontSize: 20)),
            Text(username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.pinkAccent),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("👥 Condiviso")),
                    selected: isShared,
                    selectedColor: const Color(0xFFDB2777),
                    onSelected: (val) => setState(() => isShared = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("🔒 Personale")),
                    selected: !isShared,
                    selectedColor: const Color(0xFFDB2777),
                    onSelected: (val) => setState(() => isShared = false),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance.ref('${pathPrefix}_transactions').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return const Center(child: Text("Nessuna transazione trovata."));
                }

                Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<Map<String, dynamic>> items = [];
                map.forEach((key, value) {
                  items.add({"id": key, ...Map<String, dynamic>.from(value)});
                });

                double totale = 0;
                for (var item in items) {
                  double amount = (item['amount'] as num).toDouble();
                  if (item['type'] == 'entrata') {
                    totale += amount;
                  } else {
                    totale -= amount;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("PATRIMONIO TOTALE", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("€ ${totale.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("STORICO TRANSAZIONI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...items.map((tx) => Card(
                          color: const Color(0xFF0F172A),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(tx['category'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text("${tx['note'] ?? ''} • ${tx['createdBy'] ?? ''}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            trailing: Text(
                              "${tx['type'] == 'entrata' ? '+' : '-'}€ ${(tx['amount'] as num).toDouble().toStringAsFixed(2)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tx['type'] == 'entrata' ? const Color(0xFF10B981) : const Color(0xFFDB2777),
                              ),
                            ),
                          ),
                        )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFDB2777),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddTransactionDialog(context, pathPrefix, username),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, String pathPrefix, String username) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nuova Transazione", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Importo (€)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Note / Descrizione", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777), minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;

                FirebaseDatabase.instance.ref('${pathPrefix}_transactions').push().set({
                  'type': 'uscita',
                  'amount': amount,
                  'category': '🛒 Spesa',
                  'note': noteController.text,
                  'createdBy': username,
                  'createdAt': DateTime.now().toIso8601String(),
                });

                Navigator.pop(context);
              },
              child: const Text("Salva Transazione", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
