import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Se Firebase non è ancora connesso nativamente, partiamo subito dalla Dashboard stabile
    try {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      );
    } catch (e) {
      return const HomeScreen();
    }
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
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("🐷", style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text("Piggy Vault", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email", filled: true, fillColor: const Color(0xFF0F172A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password", filled: true, fillColor: const Color(0xFF0F172A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777), minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                },
                child: Text(isLogin ? "Accedi" : "Registrati", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? "Non hai un account? Registrati" : "Hai già un account? Accedi", style: const TextStyle(color: Color(0xFFF472B6))),
              )
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
  double patrimonio = 1250.00;
  double entrateMese = 2000.00;
  double usciteMese = 750.00;

  List<Map<String, dynamic>> transazioni = [
    {"category": "Stipendio", "note": "Acconto", "amount": 2000.00, "type": "entrata"},
    {"category": "Spesa", "note": "Supermercato", "amount": 120.00, "type": "uscita"},
    {"category": "Bollette", "note": "Luce e Gas", "amount": 130.00, "type": "uscita"},
  ];

  List<Map<String, dynamic>> salvadanai = [
    {"title": "Vacanza Estiva", "current": 450.00, "target": 1000.00},
    {"title": "Nuova Auto", "current": 800.00, "target": 5000.00},
  ];

  String aiResponse = "Ciao Marco! Sono il tuo assistente AI. I tuoi conti sono stabili e in crescita.";
  bool isAiLoading = false;

  void _askAi(String prompt) {
    setState(() => isAiLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isAiLoading = false;
        if (prompt == "consigli") {
          aiResponse = "💡 Ottimo risparmio questo mese! Ti consiglio di spostare altri 50€ sul salvadanai 'Vacanza Estiva'.";
        } else {
          aiResponse = "📊 La fetta più grande delle tue uscite va in bollette e spesa. Ottimizzando del 10%, acceleri gli obiettivi!";
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Row(
          children: [
            Text("🐷 ", style: TextStyle(fontSize: 20)),
            Text("Piggy Vault", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Card Patrimonio
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
          // Entrate e Uscite
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
          const SizedBox(height: 20),
          // Sezione Grafico a Fetta / Ripartizione Spese
          const Text("🍰 RIPARTIZIONE SPESE (GRAFICO A FETTA)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPieSlice("Spesa", "48%", Color(0xFFDB2777)),
                      _buildPieSlice("Bollette", "52%", Color(0xFF3B82F6)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(
                    value: 0.48,
                    backgroundColor: Color(0xFF3B82F6),
                    color: Color(0xFFDB2777),
                    minHeight: 10,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Assistente AI
          const Text("🤖 ASSISTENTE FINANZIARIO AI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFFF472B6), size: 20),
                      SizedBox(width: 8),
                      Text("Piggy AI Advisor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  isAiLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFDB2777)))
                      : Text(aiResponse, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                        onPressed: () => _askAi("consigli"),
                        child: const Text("💡 Consigli", style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                        onPressed: () => _askAi("spese"),
                        child: const Text("📊 Analisi Spese", style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Salvadanai
          const Text("🏦 SALVADANAI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          ...salvadanai.map((piggy) {
            double progress = (piggy['current'] / piggy['target']).clamp(0.0, 1.0);
            return Card(
              color: const Color(0xFF0F172A),
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(piggy['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("€ ${piggy['current']} / € ${piggy['target']}", style: const TextStyle(fontSize: 12, color: Color(0xFFF472B6))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFF1E293B),
                      color: const Color(0xFFDB2777),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          // Storico Transazioni
          const Text("📜 STORICO TRANSAZIONI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          ...transazioni.map((tx) => Card(
                color: const Color(0xFF0F172A),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  title: Text(tx['category'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(tx['note'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Text(
                    "${tx['type'] == 'entrata' ? '+' : '-'}€ ${tx['amount'].toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: tx['type'] == 'entrata' ? const Color(0xFF10B981) : const Color(0xFFDB2777),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPieSlice(String label, String percent, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text("$label ($percent)", style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}
