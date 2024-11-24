import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projet_covoiturage/constants.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> updateUserRole(String role) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        Map<String, dynamic> roleData = {
          'uid': user.uid,
          'email': user.email,
          'typeUtilisateur': role,
        };

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
              roleData,
              SetOptions(merge: true),
            );

        print("Rôle mis à jour avec succès : $role");
      } catch (e) {
        print("Erreur lors de la mise à jour du rôle : $e");
      }
    } else {
      print("Utilisateur non authentifié !");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sélectionner un rôle")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () async {
              await updateUserRole('conducteur');
              Navigator.pushReplacementNamed(context, Constants.homeRoute);
            },
            child: const Text("Conducteur"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await updateUserRole('passager');
              Navigator.pushReplacementNamed(context, Constants.homePRoute);
            },
            child: const Text("Passager"),
          ),
        ],
      ),
    );
  }
}
