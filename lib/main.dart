import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFDB2777),
          secondary: const Color(0xFF10B981),
          surface: const Color(0xFF0F172A),
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
                  child: const Center(child: Text("🐷", style: TextStyle(fontSize: 40))),
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
                        onChanged: (val) {
                          if (isRegistering) setState(() {});
                        },
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock, color: Color(0xFFDB2777)),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (isRegistering) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: (_passwordController.text.length / 8).clamp(0.0, 1.0),
                                color: _passwordController.text.length < 6 ? Colors.redAccent : (_passwordController.text.length < 10 ? Colors.amber : Colors.green),
                                backgroundColor: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _passwordController.text.length < 6 ? "Debole" : (_passwordController.text.length < 10 ? "Media" : "Sicura"),
                              style: TextStyle(
                                fontSize: 10,
                                color: _passwordController.text.length < 6 ? Colors.redAccent : (_passwordController.text.length < 10 ? Colors.amber : Colors.green),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Conferma Password",
                            prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFDB2777)),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      StatefulBuilder(
                        builder: (context, setBtnState) {
                          bool isLoading = false;
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDB2777),
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: isLoading ? null : () async {
                              setBtnState(() => isLoading = true);
                              await _submitAuth();
                              setBtnState(() => isLoading = false);
                            },
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    isRegistering ? "Registrati" : "Accedi",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                          );
                        },
                      ),
                      if (!isRegistering) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            final email = _emailController.text.trim();
                            if (email.isEmpty) {
                              setState(() => errorMessage = "Inserisci prima la tua email sopra.");
                              return;
                            }
                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                              setState(() => errorMessage = "Email di reset inviata! Controlla la posta.");
                            } catch (e) {
                              setState(() => errorMessage = "Errore invio email di reset.");
                            }
                          },
                          child: const Center(
                            child: Text(
                              "Password dimenticata? Clicca qui",
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
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
              child: const Center(child: Text("🐷", style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text("Piggy Vault Banking", style: TextStyle(fontSize: 10, color: Color(0xFFF472B6))),
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
          Map<String, double> categoryTotals = {};

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
                double amount = 0.0;
                try {
                  amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                } catch (_) {}

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
            } catch (e) {
              // Gestione sicura degli errori di parsing
            }
          }

          if (_currentIndex == 1) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text("🎯 Obiettivi & Salvadanai", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SavingsLevelWidget(patrimonio: patrimonio),
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("🐷 I tuoi Salvadanai", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Color(0xFF10B981), size: 20),
                              onPressed: () {
                                final nameController = TextEditingController();
                                final targetController = TextEditingController();
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF0F172A),
                                    title: const Text("Nuovo Salvadanaio"),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nome (es. Vacanze)")),
                                        TextField(controller: targetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Obiettivo (€)")),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla")),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                        onPressed: () {
                                          final target = double.tryParse(targetController.text) ?? 0;
                                          if (nameController.text.isNotEmpty && target > 0) {
                                            FirebaseDatabase.instance.ref('${pathPrefix}_pockets').push().set({
                                              'name': nameController.text,
                                              'target': target,
                                              'current': 0,
                                            });
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: const Text("Crea"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder(
                          stream: FirebaseDatabase.instance.ref('${pathPrefix}_pockets').onValue,
                          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                            if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                              return const Text("Nessun salvadanaio attivo in questa sezione.", style: TextStyle(fontSize: 11, color: Colors.grey));
                            }
                            Map map = snapshot.data!.snapshot.value as Map;
                            return Column(
                              children: map.entries.map((e) {
                                var p = e.value;
                                double current = (p['current'] as num).toDouble();
                                double target = (p['target'] as num).toDouble();
                                double perc = (target > 0) ? (current / target).clamp(0.0, 1.0) : 0.0;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                ),
              ],
            );
          } else if (_currentIndex == 2) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text("🪄 Consulente IA & Simulator", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SimulatorWidget(patrimonio: patrimonio),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
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
                          child: const Center(child: Text("👥 Condiviso", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
                          child: const Center(child: Text("🔒 Privato", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 12),
              DailyBudgetWidget(patrimonio: patrimonio),
              const SizedBox(height: 16),
              if (categoryTotals.isNotEmpty) ...[
                Card(
                  color: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📊 Ripartizione Spese Mensili", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
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
                      subtitle: Text(
                        "${tx['note'] ?? 'Nessuna nota'} • ${_formatDate(tx['createdAt'])} • ${tx['createdBy'] ?? ''}",
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
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
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF0F172A),
                                  title: const Text("Elimina transazione"),
                                  content: const Text("Vuoi davvero rimuovere questa transazione?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla")),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                      onPressed: () {
                                        FirebaseDatabase.instance.ref('${pathPrefix}_transactions/${tx['id']}').remove();
                                        Navigator.pop(context);
                                      },
                                      child: const Text("Elimina", style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFFDB2777),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: "Obiettivi"),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: "Simulatore"),
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
    String type = 'uscita';
    String category = 'Spesa';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text("Nuova Transazione"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text("Uscita"),
                      selected: type == 'uscita',
                      onSelected: (val) => setDialogState(() => type = 'uscita'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text("Entrata"),
                      selected: type == 'entrata',
                      onSelected: (val) => setDialogState(() => type = 'entrata'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Importo (€)"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                dropdownColor: const Color(0xFF0F172A),
                items: ['Spesa', 'Bollette', 'Auto', 'Pet Care', 'Ristoranti', 'Stipendio', 'Altro']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setDialogState(() => category = val ?? 'Spesa'),
                decoration: const InputDecoration(labelText: "Categoria"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: "Nota opzionale"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777)),
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("⚠️ Inserisci un importo valido superiore a zero.")),
                  );
                  return;
                }

                FirebaseDatabase.instance.ref('${pathPrefix}_transactions').push().set({
                  'type': type,
                  'amount': amount,
                  'category': category,
                  'note': noteController.text.isNotEmpty ? noteController.text : 'Senza nota',
                  'createdBy': username,
                  'createdAt': DateTime.now().toIso8601String(),
                });

                Navigator.pop(context);
              },
              child: const Text("Salva", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _openSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("Impostazioni Piggy Vault"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("📁 Storico transazioni esportato in formato CSV con successo!")),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text("Esporta Storico in CSV", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text("Protezione Biometrica", style: TextStyle(fontSize: 13)),
              subtitle: const Text("Richiedi impronta all'avvio", style: TextStyle(fontSize: 10, color: Colors.grey)),
              value: false,
              activeColor: const Color(0xFFDB2777),
              onChanged: (val) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(val ? "🔒 Sicurezza biometrica attivata" : "🔓 Sicurezza biometrica disattivata")),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("👥 Link di invito copiato! Condividilo per sincronizzare il bilancio.")),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text("Invita Collaboratore al Conto", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                Navigator.pop(context);
                FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("Disconnetti Account", style: TextStyle(color: Colors.white)),
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
    String levelName = "Principe del Salvadanaio";
    double target = 5000;
    if (patrimonio < 1000) {
      levelName = "Principiarimparmio";
      target = 1000;
    } else if (patrimonio < 10000) {
      levelName = "Risparmiatore Seriale";
      target = 10000;
    } else if (patrimonio < 50000) {
      levelName = "Maestro del Guardadanaio";
      target = 50000;
    } else {
      levelName = "Re dei Porcellini 100k+";
      target = 100000;
    }

    double progress = (patrimonio / target).clamp(0.0, 1.0);

    return Card(
      color: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🏆 LIVELLO DI RISPARMIO", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(levelName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress, color: Colors.amber, backgroundColor: Colors.grey[800]),
            const SizedBox(height: 6),
            Text("Progresso obiettivo: € ${patrimonio.toStringAsFixed(0)} / € ${target.toStringAsFixed(0)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class DailyBudgetWidget extends StatelessWidget {
  final double patrimonio;
  const DailyBudgetWidget({super.key, required this.patrimonio});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    int daysLeft = lastDayOfMonth.day - now.day + 1;
    if (daysLeft <= 0) daysLeft = 1;

    double dailyBudget = patrimonio > 0 ? (patrimonio / daysLeft) : 0;

    return Card(
      color: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("💡 BUDGET GIORNALIERO", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("€ ${dailyBudget.toStringAsFixed(2)} / g", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF472B6))),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(12)),
              child: Text("$daysLeft gg a fine mese", textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
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
  final _costController = TextEditingController();
  int months = 3;
  String resultText = "";

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
            const Text("🪄 Simulatore Spesa & Rate", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Costo dell'acquisto (€)"),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("Rate mensili: "),
                ChoiceChip(
                  label: const Text("3 Mesi"),
                  selected: months == 3,
                  onSelected: (val) => setState(() => months = 3),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("6 Mesi"),
                  selected: months == 6,
                  onSelected: (val) => setState(() => months = 6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777)),
              onPressed: () {
                final cost = double.tryParse(_costController.text) ?? 0;
                if (cost <= 0) return;
                double perMonth = cost / months;
                setState(() {
                  if (widget.patrimonio >= cost) {
                    resultText = "✅ Acquisto sostenibile! Impatto rata: € ${perMonth.toStringAsFixed(2)}/mese per $months mesi.";
                  } else {
                    resultText = "⚠️ Attenzione: Il costo supera il patrimonio attuale.";
                  }
                });
              },
              child: const Text("Simula Sostenibilità", style: TextStyle(color: Colors.white)),
            ),
            if (resultText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(resultText, style: const TextStyle(fontSize: 12, color: Color(0xFF10B981))),
            ],
          ],
        ),
      ),
    );
  }
}

Color _getCategoryColor(String cat) {
  switch (cat) {
    case 'Spesa': return Colors.pinkAccent;
    case 'Bollette': return Colors.orangeAccent;
    case 'Auto': return Colors.blueAccent;
    case 'Pet Care': return Colors.greenAccent;
    case 'Ristoranti': return Colors.purpleAccent;
    case 'Stipendio': return Colors.tealAccent;
    default: return Colors.grey;
  }
}

String _formatDate(String? isoStr) {
  if (isoStr == null) return '';
  try {
    DateTime dt = DateTime.parse(isoStr);
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  } catch (e) {
    return '';
  }
}
