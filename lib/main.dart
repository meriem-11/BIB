import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:projet_covoiturage/api/firebase_auth_config.dart';
import 'package:projet_covoiturage/constants.dart';
import 'package:projet_covoiturage/firebase_options.dart';
import 'package:projet_covoiturage/screens/home.dart';
import 'package:projet_covoiturage/screens/auth_screens.dart';
import 'package:projet_covoiturage/screens/homeP.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseAuthConfig.configureProviders();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projet Covoiturage',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: Constants.signInRoute,
      routes: {
        Constants.signInRoute: (context) => AuthScreens.buildSignInScreen(context),
        Constants.homePRoute: (context) => const HomeScreen2(),
        Constants.homeRoute: (context) => const HomeScreen(),

        Constants.verifyEmailRoute: (context) => AuthScreens.buildEmailVerificationScreen(context),
      },
    );
  }
}
