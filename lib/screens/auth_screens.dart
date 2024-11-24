import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:projet_covoiturage/constants.dart';
import 'package:projet_covoiturage/utilities/global_widgets.dart';

class AuthScreens {
  /// Sauvegarde ou met à jour les données de l'utilisateur dans Firestore
  static Future<void> saveUserToFirestore(User user) async {
    try {
      // Obtenez le token FCM
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Référence du document utilisateur
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Vérifiez si l'utilisateur existe déjà
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Créez un nouveau document utilisateur
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'typeUtilisateur': '', // Ajoutez d'autres champs si nécessaire
          'usertoken': fcmToken,
        });
      } else {
        // Mettez à jour le token si l'utilisateur existe
        await userDoc.update({
          'usertoken': fcmToken,
        });
      }
    } catch (e) {
      print('Erreur lors de l\'enregistrement dans Firestore : $e');
    }
  }

  /// Écran de connexion
  static Widget buildSignInScreen(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: screenHeight / 2.5,
              child: Image.asset(
                "lib/assets/ls.png",
                fit: BoxFit.contain,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SignInScreen(
                  providers:
                      FirebaseUIAuth.providersFor(FirebaseAuth.instance.app),
                  actions: [
                    _handleUserCreation(),
                    _handleSignIn(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Écran de vérification d'email
  static Widget buildEmailVerificationScreen(BuildContext context) {
    Timer? emailCheckTimer;

    void checkEmailVerified() async {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      if (user != null && user.emailVerified) {
        emailCheckTimer?.cancel();
        Navigator.pushReplacementNamed(context, Constants.homeRoute);
      }
    }

    emailCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      checkEmailVerified();
    });

    return WillPopScope(
      onWillPop: () async {
        emailCheckTimer?.cancel();
        return true;
      },
      child: EmailVerificationScreen(
        actions: [
          AuthCancelledAction((context) {
            FirebaseUIAuth.signOut(context: context);
            Navigator.pushReplacementNamed(context, Constants.signInRoute);
          }),
        ],
      ),
    );
  }

  /// Action lors de la création d'un utilisateur
  static AuthStateChangeAction<UserCreated> _handleUserCreation() {
    return AuthStateChangeAction<UserCreated>((context, state) async {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Choix du rôle de l'utilisateur
        String? typeUtilisateur = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRoleOption(
                    context,
                    title: 'Conducteur',
                    description: '',
                    icon: Icons.directions_car,
                    color: const Color.fromARGB(255, 90, 164, 165),
                    onSelected: () {
                      Navigator.of(context).pop('conducteur');
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildRoleOption(
                    context,
                    title: 'Passager',
                    description: '',
                    icon: Icons.person,
                    color: const Color.fromARGB(255, 12, 17, 51),
                    onSelected: () {
                      Navigator.of(context).pop('passager');
                    },
                  ),
                ],
              ),
            );
          },
        );

        // Enregistrez l'utilisateur dans Firestore avec le rôle choisi
        await saveUserToFirestore(user);
        await FirebaseFirestore.instance
            .collection(Constants.usersCollection)
            .doc(user.uid)
            .update({'typeUtilisateur': typeUtilisateur ?? ''});

        Navigator.pushReplacementNamed(context, Constants.signInRoute);
        GlobalWidgets(context).showSnackBar(
          content: 'Compte créé. Veuillez vous connecter.',
          backgroundColor: Colors.green,
        );
      }
    });
  }

  /// Action lors de la connexion d'un utilisateur
  static AuthStateChangeAction<SignedIn> _handleSignIn(BuildContext context) {
    return AuthStateChangeAction<SignedIn>((context, state) async {
      User? user = state.user;

      if (user != null && !user.emailVerified) {
        Navigator.pushReplacementNamed(context, Constants.verifyEmailRoute);
      } else if (user != null) {
        // Mise à jour du token et récupération du rôle
        await saveUserToFirestore(user);

        final userDoc = await FirebaseFirestore.instance
            .collection(Constants.usersCollection)
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String userType = userDoc['typeUtilisateur'];

          if (userType == 'conducteur') {
            Navigator.pushReplacementNamed(context, Constants.homeRoute);
          } else {
            Navigator.pushReplacementNamed(context, Constants.homePRoute);
          }
        }
      }
    });
  }

  /// Widget pour choisir un rôle
  static Widget _buildRoleOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
