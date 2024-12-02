import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PassengerNotificationPage extends StatelessWidget {
  const PassengerNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('idpassager', isEqualTo: user?.uid)
            .where('etat', whereIn: ['acceptée', 'annulée']).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Erreur lors du chargement."));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucune notification."));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              final etat = data['etat'];
              final trajet = data['trajet'];
              final timestamp = data['date'] as Timestamp?;

              String formattedDate = "Date non spécifiée"; // Valeur par défaut

              if (timestamp != null) {
                final dateTime = timestamp.toDate();
                final utcMinus8 = dateTime.subtract(Duration(hours: 8));
                formattedDate =
                    DateFormat('dd/MM/yyyy à HH:mm').format(utcMinus8);
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                child: ListTile(
                  leading: Icon(
                    etat == 'acceptée' ? Icons.check_circle : Icons.cancel,
                    color: etat == 'acceptée' ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    "${trajet['departureCity']} ➡️ ${trajet['arrivalCity']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Statut : $etat"),
                      const SizedBox(height: 4),
                      Text(
                        "Date : $formattedDate", // Affichage de la date formatée
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
