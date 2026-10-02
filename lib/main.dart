import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PiggyVaultApp());
}

class PiggyVaultApp extends StatefulWidget {
  const PiggyVaultApp({super.key});

  @override
  State<PiggyVaultApp> createState() => _PiggyVaultAppState();
}

class _PiggyVaultAppState extends State<PiggyVaultApp> {
  String _currentTheme = 'Porcellino Dark';

  void changeTheme(String themeName) {
    setState(() {
      _currentTheme = themeName;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isLight = _currentTheme == 'Porcellino Light';
    
    Color scaffoldBg = isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0B0F19);
    Color cardBg = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF131B2E);
    Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    Color subtitleColor = isLight ? const Color(0xFF475569) : Colors.grey.shade400;
    Color primaryColor = const Color(0xFFDB2777);

    return MaterialApp(
      title: 'Porcellino',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(
        onThemeChanged: changeTheme,
        currentTheme: _currentTheme,
        scaffoldBg: scaffoldBg,
        cardBg: cardBg,
        textColor: textColor,
        subtitleColor: subtitleColor,
        primaryColor: primaryColor,
        isLight: isLight,
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final Function(String) onThemeChanged;
  final String currentTheme;
  final Color scaffoldBg;
  final Color cardBg;
  final Color textColor;
  final Color subtitleColor;
  final Color primaryColor;
  final bool isLight;

  const LoginScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
    required this.scaffoldBg,
    required this.cardBg,
    required this.textColor,
    required this.subtitleColor,
    required this.primaryColor,
    required this.isLight,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _autentica() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserisci un'email valida")));
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          userEmail: email,
          onThemeChanged: widget.onThemeChanged,
          currentTheme: widget.currentTheme,
          scaffoldBg: widget.scaffoldBg,
          cardBg: widget.cardBg,
          textColor: widget.textColor,
          subtitleColor: widget.subtitleColor,
          primaryColor: widget.primaryColor,
          isLight: widget.isLight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: widget.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.savings, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text("Porcellino", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: widget.textColor)),
              const SizedBox(height: 36),
              TextField(
                controller: _emailController,
                style: TextStyle(color: widget.textColor),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: widget.subtitleColor),
                  filled: true,
                  fillColor: widget.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: widget.textColor),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: widget.subtitleColor),
                  filled: true,
                  fillColor: widget.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
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
