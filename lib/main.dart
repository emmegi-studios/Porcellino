import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

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
      title: 'Porcellino OS',
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFDB2777),
                  shape: BoxShape.circle,
                ),
                child: const Text("🐷", style: TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: 16),
              const Text("Porcellino OS", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text("Personal & Shared Finance V4.0", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _quickLogin("Marco"),
                      child: const Text("👤 Marco", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _quickLogin("Marika"),
                      child: const Text("👤 Marika", style: TextStyle(color: Color(0xFFF472B6), fontWeight: FontWeight.bold)),
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
        elevation: 0,
        title: Row(
          children: [
            const Text("🐷 ", style: TextStyle(fontSize: 22)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text("Porcellino OS V4.0", style: TextStyle(fontSize: 10, color: Color(0xFFF472B6))),
              ],
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isShared = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isShared ? const Color(0xFFDB2777) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text("👥 Bilancio Condiviso", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isShared = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isShared ? const Color(0xFFDB2777) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text("🔒 Personale Privato", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance.ref('${pathPrefix}_transactions').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                List<Map<String, dynamic>> items = [];
                double patrimonio = 0;
                double entrateMese = 0;
                double usciteMese = 0;
                Map<String, double> categoryTotals = {};

                if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                  Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  map.forEach((key, value) {
                    items.add({"id": key, ...Map<String, dynamic>.from(value)});
                  });
                  items.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));

                  final now = DateTime.now();
                  for (var item in items) {
                    double amount = (item['amount'] as num).toDouble();
                    String type = item['type'] ?? 'uscita';
                    String cat = item['category'] ?? 'Altro';

                    DateTime txDate = DateTime.tryParse(item['createdAt'] ?? '') ?? now;
                    bool isCurrentMonth = txDate.month == now.month && txDate.year == now.year;

                    if (type == 'entrata') {
                      patrimonio += amount;
                      if (isCurrentMonth) entrateMese += amount;
                    } else {
                      patrimonio -= amount;
                      if (isCurrentMonth) {
                        usciteMese += amount;
                        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amount;
                      }
                    }
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // CARD PATRIMONIO
                    Card(
                      color: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1E293B))),
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

                    // ENTRATE E USCITE MESE
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("ENTRATE MESE", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("USCITE MESE", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text("€ ${usciteMese.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDB2777))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // GRAFICO A TORTA
                    if (categoryTotals.isNotEmpty) ...[
                      Card(
                        color: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("📊 Analisi Spese Mensili per Categoria", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 160,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 35,
                                    sections: categoryTotals.entries.map((entry) {
                                      return PieChartSectionData(
                                        color: _getCategoryColor(entry.key),
                                        value: entry.value,
                                        title: '${((entry.value / usciteMese) * 100).toStringAsFixed(0)}%',
                                        radius: 40,
                                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // SALVADANAI & OBIETTIVI
                    PocketsWidget(pathPrefix: pathPrefix),
                    const SizedBox(height: 16),

                    // SPESE RICORRENTI
                    RecurringWidget(pathPrefix: pathPrefix),
                    const SizedBox(height: 16),

                    // LIVELLI RISPARMIO
                    SavingsLevelWidget(patrimonio: patrimonio),
                    const SizedBox(height: 16),

                    // CONSULENTE IA
                    SimulatorWidget(patrimonio: patrimonio),
                    const SizedBox(height: 16),

                    // STORICO TRANSAZIONI
                    const Text("📜 STORICO TRANSAZIONI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text("Nessuna transazione registrata.", style: TextStyle(fontSize: 12, color: Colors.grey))),
                      ),
                    ...items.map((tx) => Card(
                          color: const Color(0xFF0F172A),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            title: Text(tx['category'] ?? 'Spesa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text("${tx['note'] ?? 'Nessuna nota'} • ${tx['createdBy'] ?? ''}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${tx['type'] == 'entrata' ? '+' : '-'}€ ${(tx['amount'] as num).toDouble().toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: tx['type'] == 'entrata' ? const Color(0xFF10B981) : const Color(0xFFDB2777),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                  onPressed: () {
                                    FirebaseDatabase.instance.ref('${pathPrefix}_transactions/${tx['id']}').remove();
                                  },
                                ),
                              ],
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

  Color _getCategoryColor(String category) {
    if (category.contains('🛒')) return Colors.pinkAccent;
    if (category.contains('🏠')) return Colors.amber;
    if (category.contains('🚗')) return Colors.blueAccent;
    if (category.contains('🐶')) return Colors.purpleAccent;
    if (category.contains('🍕')) return Colors.orangeAccent;
    return Colors.emeraldAccent;
  }

  void _showAddTransactionDialog(BuildContext context, String pathPrefix, String username) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String type = 'uscita';
    String category = '🛒 Spesa / Alimentari';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Nuova Transazione", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("Uscita (Spesa)")),
                      selected: type == 'uscita',
                      selectedColor: const Color(0xFFDB2777),
                      onSelected: (val) => setModalState(() => type = 'uscita'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("Entrata")),
                      selected: type == 'entrata',
                      selectedColor: const Color(0xFF10B981),
                      onSelected: (val) => setModalState(() => type = 'entrata'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                dropdownColor: const Color(0xFF0F172A),
                decoration: const InputDecoration(labelText: "Categoria", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: '🛒 Spesa / Alimentari', child: Text('🛒 Spesa / Alimentari')),
                  DropdownMenuItem(value: '🏠 Bollette & Casa', child: Text('🏠 Bollette & Casa')),
                  DropdownMenuItem(value: '🚗 Auto & Trasporti', child: Text('🚗 Auto & Trasporti')),
                  DropdownMenuItem(value: '🐶 Animali / Pet Care', child: Text('🐶 Animali / Pet Care')),
                  DropdownMenuItem(value: '🍕 Svago & Ristoranti', child: Text('🍕 Svago & Ristoranti')),
                  DropdownMenuItem(value: '💼 Stipendio / Entrata', child: Text('💼 Stipendio / Entrata')),
                  DropdownMenuItem(value: '📦 Altro', child: Text('📦 Altro')),
                ],
                onChanged: (val) => setModalState(() => category = val!),
              ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB2777),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount <= 0) return;

                  FirebaseDatabase.instance.ref('${pathPrefix}_transactions').push().set({
                    'type': type,
                    'amount': amount,
                    'category': category,
                    'note': noteController.text,
                    'createdBy': username,
                    'createdAt': DateTime.now().toIso8601String(),
                  });

                  Navigator.pop(context);
                },
                child: const Text("Salva Transazione", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PocketsWidget extends StatelessWidget {
  final String pathPrefix;
  const PocketsWidget({super.key, required this.pathPrefix});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🎯 Salvadanai & Obiettivi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            StreamBuilder(
              stream: FirebaseDatabase.instance.ref('${pathPrefix}_pockets').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return const Text("Nessun salvadanaio attivo.", style: TextStyle(fontSize: 11, color: Colors.grey));
                }
                Map map = snapshot.data!.snapshot.value as Map;
                return Column(
                  children: map.entries.map((e) {
                    var p = e.value;
                    double current = (p['current'] as num).toDouble();
                    double target = (p['target'] as num).toDouble();
                    double perc = (current / target).clamp(0.0, 1.0);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.between,
                            children: [
                              Text(p['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text("€ ${current.toStringAsFixed(0)} / € ${target.toStringAsFixed(0)}", style: const TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: perc, color: const Color(0xFF10B981), backgroundColor: Colors.grey[800]),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RecurringWidget extends StatelessWidget {
  final String pathPrefix;
  const RecurringWidget({super.key, required this.pathPrefix});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🔄 Spese & Entrate Ricorrenti", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            StreamBuilder(
              stream: FirebaseDatabase.instance.ref('${pathPrefix}_recurring').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return const Text("Nessun abbonamento registrato.", style: TextStyle(fontSize: 11, color: Colors.grey));
                }
                Map map = snapshot.data!.snapshot.value as Map;
                return Column(
                  children: map.entries.map((e) {
                    var r = e.value;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(r['title'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      trailing: Text(
                        "€ ${(r['amount'] as num).toDouble().toStringAsFixed(2)}",
                        style: TextStyle(color: r['type'] == 'entrata' ? Colors.blueAccent : Colors.pinkAccent, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SavingsLevelWidget extends StatelessWidget {
  final double patrimonio;
  const SavingsLevelWidget({super.key, required this.patrimonio});

  @override
  Widget build(BuildContext context) {
    double target = 1000;
    String level = "Livello 1: Smeraldo";
    if (patrimonio >= 100000) { target = 100000; level = "Livello 4: Porcellone"; }
    else if (patrimonio >= 50000) { target = 50000; level = "Livello 3: Fortezza"; }
    else if (patrimonio >= 10000) { target = 10000; level = "Livello 2: Cuscino"; }

    double perc = (patrimonio / target).clamp(0.0, 1.0);

    return Card(
      color: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text("🏆 Livelli Risparmio", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(level, style: const TextStyle(fontSize: 10, color: Color(0xFFF472B6), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: perc, color: const Color(0xFFDB2777), backgroundColor: Colors.grey[800]),
          ],
        ),
      ),
    );
  }
}

class SimulatorWidget extends StatefulWidget {
  final double patrimonio;
  const SimulatorWidget({super.key, required this.patrimonio});

  @override
  State<SimulatorWidget> createState() => _SimulatorWidgetState();
}

class _SimulatorWidgetState extends State<SimulatorWidget> {
  final amountController = TextEditingController();
  String resultText = '';

  void _calculate() {
    final val = double.tryParse(amountController.text) ?? 0;
    if (val <= 0) return;

    double residuo = widget.patrimonio - val;
    double rata3 = val / 3;
    double rata6 = val / 6;

    setState(() {
      resultText = residuo >= 0
          ? "✅ Acquisto sostenibile (€ ${residuo.toStringAsFixed(2)} rimanenti).\n💳 Rateizzabile in 3 rate da € ${rata3.toStringAsFixed(2)} o 6 da € ${rata6.toStringAsFixed(2)}"
          : "🚨 Intaccherebbe le riserve per € ${Math.abs(residuo).toStringAsFixed(2)}.\nConsigliate 6 rate da € ${rata6.toStringAsFixed(2)}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🪄 Consulente IA (Simulatore Acquisti)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: "Importo spesa (€)", isDense: true, border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  onPressed: _calculate,
                  child: const Text("Valuta", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
            if (resultText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(resultText, style: const TextStyle(fontSize: 11, color: Colors.amber)),
            ],
          ],
        ),
      ),
    );
  }
}
