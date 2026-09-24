import 'package:firebase_core/firebase_core.dart';

bool isFirebaseInitialized = false;

Future<void> initFirebase() async {
  if (!isFirebaseInitialized) {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAVXSR75QEzZ6mjzacYNtXagZZlvhbN9IM",
          authDomain: "intechsf365-607a9.firebaseapp.com",
          databaseURL: "https://intechsf365-607a9-default-rtdb.asia-southeast1.firebasedatabase.app/",
          projectId: "intechsf365-607a9",
          storageBucket: "intechsf365-607a9.firebasestorage.app",
          messagingSenderId: "540540488758",
          appId: "1:540540488758:web:72b26465b9326ef3cd9c97",
        ),
      );
      isFirebaseInitialized = true;
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }
}
