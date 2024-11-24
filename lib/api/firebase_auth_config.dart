import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class FirebaseAuthConfig {
  static void configureProviders() {
    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);
  }
}
