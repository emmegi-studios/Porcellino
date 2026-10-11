import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

fcm_listener = """
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
"""

# Dividiamo il testo per operare unicamente all'interno di _HomeScreenState
parti = content.split("class _HomeScreenState extends State<HomeScreen>", 1)
if len(parti) == 2 and 'FirebaseMessaging.onMessage.listen' not in parti[1]:
    # Troviamo l'initState della Home e aggiungiamo il radar subito dopo super.initState();
    parti[1] = re.sub(
        r'(void\s+initState\(\)\s*\{\s*super\.initState\(\);)',
        r'\1\n' + fcm_listener,
        parti[1],
        count=1
    )
    content = parti[0] + "class _HomeScreenState extends State<HomeScreen>" + parti[1]
    print("✅ Radar Notifiche In-App fluttuanti installato nella Home!")
else:
    print("⚠️ Radar notifiche già presente.")

content += '\n// Fix v2.0-beta.4: Iniezione listener Firebase in Foreground\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
