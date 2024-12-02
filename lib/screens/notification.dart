import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DriverNotificationListener extends StatefulWidget {
  @override
  _DriverNotificationListenerState createState() =>
      _DriverNotificationListenerState();
}

class _DriverNotificationListenerState
    extends State<DriverNotificationListener> {
  late Stream<QuerySnapshot> reservationStream;
  final String? currentDriverId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();

    // Vérifier si l'utilisateur est authentifié
    if (currentDriverId == null) {
      print("Erreur : L'utilisateur n'est pas authentifié.");
      return;
    }

    // Configurer le stream pour écouter les réservations liées au conducteur
    reservationStream = FirebaseFirestore.instance
        .collection('reservations')
        .where('idconducteur', isEqualTo: currentDriverId)
        .snapshots();

    // Ajouter un listener à ce stream
    reservationStream.listen((QuerySnapshot snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          // Une nouvelle réservation a été ajoutée
          final reservation = change.doc.data();
          _showNotificationForReservation(reservation as Map<String, dynamic>?);
        }
      }
    });
  }

  // Fonction pour afficher une notification
  void _showNotificationForReservation(Map<String, dynamic>? reservation) {
    if (reservation == null) return;

    final trajet = reservation['trajet'] ?? {};
    final places = reservation['places_reservees'] ?? 0;
    final passagerId = reservation['idpassager'] ?? 'Inconnu';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nouvelle Réservation"),
        content: Text(
          "Un passager ($passagerId) a réservé $places place(s) pour le trajet : "
          "${trajet['departureCity']} ➡️ ${trajet['arrivalCity']}.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications Conducteur"),
        backgroundColor: const Color.fromARGB(255, 12, 17, 51),
      ),
      body: Center(
        child: const Text(
          "En attente de nouvelles réservations...",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
