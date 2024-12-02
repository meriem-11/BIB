import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:projet_covoiturage/screens/annoncelist_screen.dart';

class NotificationsListPage extends StatefulWidget {
  @override
  _NotificationsListPageState createState() => _NotificationsListPageState();
}

class _NotificationsListPageState extends State<NotificationsListPage> {
  final String? currentDriverId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> updateDriverIncome(String driverId, double amount) async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';

      final driverIncomeRef = FirebaseFirestore.instance
          .collection('drivers_income')
          .doc(driverId)
          .collection('daily_gains')
          .doc(dateKey);

      final driverIncomeSnapshot = await driverIncomeRef.get();

      if (driverIncomeSnapshot.exists) {
        final currentIncome = driverIncomeSnapshot['gain'] ?? 0.0;
        await driverIncomeRef.update({
          'gain': currentIncome + amount,
        });
      } else {
        await driverIncomeRef.set({
          'gain': amount,
        });
      }
    } catch (e) {
      print('Erreur lors de la mise à jour des gains : $e');
    }
  }

  void onRideCompleted(String driverId, double amount) async {
    await updateDriverIncome(driverId, amount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Gains mis à jour pour ce trajet")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentDriverId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Notifications"),
          backgroundColor: const Color.fromARGB(255, 32, 30, 96),
        ),
        body: const Center(
          child: Text("Vous devez être connecté pour voir vos notifications."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Color.fromARGB(255, 254, 254, 255),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 12, 17, 51),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('idconducteur', isEqualTo: currentDriverId)
            .where('etat', isEqualTo: 'en attente')
            .orderBy('date') // Trier par date et heure
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Aucune notification pour le moment."),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final reservation =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final reservationId = snapshot.data!.docs[index].id;
              final trajet = reservation['trajet'] ?? {};
              final places = reservation['places_reservees'] ?? 0;
              final passagerId = reservation['idpassager'] ?? 'Inconnu';
              final timestamp = reservation['date'] as Timestamp?;

              String formattedDate = "Date non spécifiée";

              if (timestamp != null) {
                final dateTime = timestamp.toDate();
                final utcMinus8 = dateTime.subtract(Duration(hours: 8));
                formattedDate =
                    DateFormat('dd/MM/yyyy à HH:mm').format(utcMinus8);
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(
                    "${trajet['departureCity']} ➡️ ${trajet['arrivalCity']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Places réservées : $places"),
                      Text("Date de réservation : $formattedDate"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          // Mettre à jour le statut de la réservation et enregistrer la date d'acceptation
                          await _updateReservationStatus(
                              reservationId, 'acceptée');
                          double amount = 20.0; // Exemple de montant
                          onRideCompleted(currentDriverId!, amount);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          await _updateReservationStatus(
                              reservationId, 'annulée');
                        },
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

  Future<void> _updateReservationStatus(
      String reservationId, String newStatus) async {
    try {
      // Calculer la date et l'heure avec un décalage UTC-8
      final now = DateTime.now();
      final utcMinus8 = now.subtract(Duration(hours: 8));

      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .update({
        'etat': newStatus,
        // Si l'état est "acceptée", ajouter le champ dateAcceptation avec l'heure UTC-8
        if (newStatus == 'acceptée') 'dateAcceptation': utcMinus8,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Statut mis à jour : $newStatus")),
      );
    } catch (e) {
      print("Erreur lors de la mise à jour du statut : $e");
    }
  }
}
