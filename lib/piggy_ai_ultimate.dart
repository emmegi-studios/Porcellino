import 'package:flutter/material.dart';

class PiggyAIUltimateWidget extends StatefulWidget {
  const PiggyAIUltimateWidget({Key? key}) : super(key: key);

  @override
  State<PiggyAIUltimateWidget> createState() => _PiggyAIUltimateWidgetState();
}

class _PiggyAIUltimateWidgetState extends State<PiggyAIUltimateWidget> {
  final TextEditingController _controller = TextEditingController();
  double _customAlertThreshold = 150.0;
  String _aiResponse = "Sono Piggy AI. Imposta la tua soglia di pericolo, anche se so già che la ignorerai.";
  bool _isAlertActive = false;
  String _detectedCategory = "Non categorizzato";
  double _vaultImpact = 0.0;

  void _updateThresholdAdvice(double newThreshold) {
    setState(() {
      _customAlertThreshold = newThreshold;
      if (newThreshold > 300) {
        _aiResponse = "300€ come limite d'allerta? Ottimo piano per sponsorizzare la tua bancarotta personale. Geniale.";
      } else if (newThreshold > 100) {
        _aiResponse = "Hai impostato ${newThreshold.toStringAsFixed(0)}€ come limite. Speriamo che il tuo conto corrente abbia la stessa fiducia in te.";
      } else {
        _aiResponse = "Soglia severa a ${newThreshold.toStringAsFixed(0)}€. Finalmente un briciolo di lucidità in questo disastro finanziario.";
      }
    });
  }

  void _processExpense(String input) {
    final regex = RegExp(r'(\d+([.,]\d+)?)');
    final match = regex.firstMatch(input);
    double amount = 0.0;
    if (match != null) {
      amount = double.parse(match.group(1)!.replaceAll(',', '.'));
    }

    setState(() {
      if (amount >= _customAlertThreshold) {
        _isAlertActive = true;
        _aiResponse = "🚨 ATTENZIONE! €${amount.toStringAsFixed(2)} supera la tua stessa soglia di ${_customAlertThreshold.toStringAsFixed(0)}€! Ti sei autonomamente tirato la zappa sui piedi.";
      } else if (amount > (_customAlertThreshold * 0.5)) {
        _isAlertActive = false;
        _aiResponse = "Spesa pesante. Ti stai avvicinando pericolosamente al limite che ti sei prefissato (${_customAlertThreshold.toStringAsFixed(0)}€). Sveglia!";
      } else if (amount > 0) {
        _isAlertActive = false;
        _aiResponse = "Spesa registrata. Per ora sei sotto la soglia di guardia, non montarci la testa.";
      } else {
        _aiResponse = "Non ho riconosciuto l'importo. Scrivi una cifra sensata!";
      }

      final lowerInput = input.toLowerCase();
      if (lowerInput.contains('ristorante') || lowerInput.contains('pizza') || lowerInput.contains('cibo') || lowerInput.contains('bar')) {
        _detectedCategory = 'Cibo & Svago 🍔';
      } else if (lowerInput.contains('bolletta') || lowerInput.contains('affitto') || lowerInput.contains('spesa')) {
        _detectedCategory = 'Spese Obbligatorie 📄';
      } else {
        _detectedCategory = 'Capricci Inutili 💸';
      }

      _vaultImpact = amount * 1.25; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _isAlertActive ? Colors.red.shade900 : const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.pinkAccent, size: 28),
                const SizedBox(width: 8),
                const Text(
                  "Piggy AI Ultimate",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.mic, color: Colors.pinkAccent),
                  onPressed: () {
                    _processExpense("180");
                  },
                  tooltip: "Registra a voce",
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Text(
              _aiResponse,
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              initiallyExpanded: false,
              collapsedTextColor: Colors.white54,
              textColor: Colors.pinkAccent,
              iconColor: Colors.pinkAccent,
              collapsedIconColor: Colors.white54,
              title: Text(
                "Soglia di allerta attuale: € ${_customAlertThreshold.toStringAsFixed(0)} (Tocca per modificare)",
                style: const TextStyle(fontSize: 13),
              ),
              children: [
                Slider(
                  value: _customAlertThreshold,
                  min: 50.0,
                  max: 500.0,
                  divisions: 9,
                  activeColor: Colors.pinkAccent,
                  inactiveColor: Colors.white24,
                  label: "€ ${_customAlertThreshold.toStringAsFixed(0)}",
                  onChanged: (val) {
                    _updateThresholdAdvice(val);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Text(
                    "Consiglio dell'IA: Scegli un limite saggio... ammesso che tu sappia cosa significa.",
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Inserisci spesa (es. 'Ho speso 120€ per...')",
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black38,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.pinkAccent),
                  onPressed: () {
                    _processExpense(_controller.text);
                    _controller.clear();
                  },
                ),
              ),
              onSubmitted: (val) {
                _processExpense(val);
                _controller.clear();
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Categoria: $_detectedCategory",
                  style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  "Impatto Salvadanaio: -€${_vaultImpact.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
