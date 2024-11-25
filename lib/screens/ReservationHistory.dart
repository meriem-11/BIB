import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReservationHistoryPage extends StatelessWidget {
  const ReservationHistoryPage({super.key});

  Future<void> updateReservationStatus(
      String reservationId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .update({'etat': status});
      print("Mise à jour de l'état de la réservation réussie.");
    } catch (e) {
      print("Erreur lors de la mise à jour de l'état de la réservation : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique des réservations"),
        backgroundColor: const Color.fromARGB(255, 12, 17, 51),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Une erreur est survenue."));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucune réservation trouvée."));
          }

          final reservations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              final trajet = reservation['trajet'];
              final prix = reservation['prix'];
              final placesReservees = reservation['places_reservees'];
              final etat = reservation['etat'];
              final reservationId = reservation.id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${trajet['departureCity']} ➡️ ${trajet['arrivalCity']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Places réservées : $placesReservees",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Prix : ${prix['amount']} ${prix['currency']}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "État : $etat",
                        style: TextStyle(
                          fontSize: 14,
                          color: etat == "confirmé"
                              ? Colors.green
                              : etat == "en attente"
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (etat != "accepté")
                            TextButton(
                              onPressed: () {
                                updateReservationStatus(
                                    reservationId, "accepté");
                              },
                              child: const Text(
                                "Accepter",
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          if (etat != "annulé")
                            TextButton(
                              onPressed: () {
                                updateReservationStatus(
                                    reservationId, "annulé");
                              },
                              child: const Text(
                                "Annuler",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
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
