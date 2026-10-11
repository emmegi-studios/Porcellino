import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Aggiungiamo gli import necessari in cima al file se non ci sono già
imports = """
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
"""
if 'package_info_plus' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';" + imports)

# 2. Metodi OTA e Info all'interno di _SettingsScreenState
settings_methods = """
  Future<void> _mostraInfoApp(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('Info & Crediti 🐷', style: TextStyle(color: Colors.white)),
        content: Text(
          'Piggy Vault v' + packageInfo.version + '\\n\\nIdeato e progettato da Marco.\\nUn caveau di coppia sicuro, privato e intelligente.',
          style: const TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi', style: TextStyle(color: Colors.pinkAccent)),
          )
        ],
      ),
    );
  }

  Future<void> _verificaAggiornamentiOTA(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Controllo aggiornamenti in corso...')));
    try {
      final response = await Dio().get('https://api.github.com/repos/EmmeGi13/Porcellino/releases/latest');
      if (response.statusCode == 200) {
        String latest = response.data['tag_name'].toString().replaceAll('v', '');
        PackageInfo pi = await PackageInfo.fromPlatform();
        if (latest != pi.version) {
          String url = response.data['assets'][0]['browser_download_url'];
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E2235),
              title: const Text('Aggiornamento Disponibile! 🚀', style: TextStyle(color: Colors.white)),
              content: Text('È disponibile la versione v' + latest + '. Vuoi installarla ora?', style: const TextStyle(color: Colors.white70)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla', style: TextStyle(color: Colors.grey))),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    var dir = await getExternalStorageDirectory();
                    String path = dir!.path + "/update.apk";
                    await Dio().download(url, path);
                    await OpenFilex.open(path);
                  },
                  child: const Text('Aggiorna', style: TextStyle(color: Colors.greenAccent))
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('L\\'app è già aggiornata all\\'ultima versione!')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore OTA: ' + e.toString())));
    }
  }
"""

if '_mostraInfoApp' not in content:
    content = re.sub(r'(class _SettingsScreenState extends State<SettingsScreen> \{)', r'\1' + settings_methods, content)

# 3. Inseriamo i pulsanti nella UI delle impostazioni
menu_tiles = """
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white70),
              title: const Text('Info & Crediti', style: TextStyle(color: Colors.white)),
              onTap: () => _mostraInfoApp(context),
            ),
            ListTile(
              leading: const Icon(Icons.system_update, color: Colors.greenAccent),
              title: const Text('Cerca Aggiornamenti', style: TextStyle(color: Colors.white)),
              onTap: () => _verificaAggiornamentiOTA(context),
            ),
"""

if 'Info & Crediti' not in content:
    # Cerchiamo il blocco ListView/Column all'interno di SettingsScreen per accodare i Tile
    content = re.sub(r'(class SettingsScreen.*?Widget build\(BuildContext context\).*?children:\s*\[)', r'\1' + menu_tiles, content, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Funzioni OTA e Info integrate con successo!")
