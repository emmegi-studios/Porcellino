import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

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

  print("Pulizia database in corso...");
  await FirebaseDatabase.instance.ref('shared_transactions').remove();
  await FirebaseDatabase.instance.ref('shared_pockets').remove();
  await FirebaseDatabase.instance.ref('shared_recurring').remove();
  print("Database ripulito con successo!");
}
