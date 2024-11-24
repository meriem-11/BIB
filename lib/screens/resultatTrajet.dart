import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> fetchRides(
    String departure, String destination) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('annonces')
        .where('trajet.departureCity', isEqualTo: departure)
        .where('trajet.arrivalCity', isEqualTo: destination)
        .get();

    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  } catch (e) {
    print("Erreur lors de la récupération des trajets : $e");
    return [];
  }
}

class RideResultsPage extends StatelessWidget {
  final String departure;
  final String destination;

  const RideResultsPage({
    required this.departure,
    required this.destination,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Résultats de la recherche"),
        backgroundColor: const Color.fromARGB(255, 12, 17, 51),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchRides(departure, destination),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Une erreur est survenue."));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucun trajet trouvé."));
          }

          final rides = snapshot.data!;
          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              final trajet = ride['trajet'];
              final prix = ride['prix'];
              final date = ride['date_depart'] ?? "Non spécifié";
              final vehicleDetails = ride['vehicule_details'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5, // Ajout d'une ombre pour un effet de profondeur
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${trajet['departureCity']} ➡️ ${trajet['arrivalCity']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.blueGrey,
                            ),
                          ),
                          Icon(
                            Icons.directions_car,
                            color: Colors.blueGrey[600],
                            size: 30,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: Colors.grey[600], size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "Date de départ : $date",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.attach_money,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "Prix : ${prix['amount']} ${prix['currency']}",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.event_seat,
                              color: Colors.orange[700], size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "Places disponibles : ${ride['places_disponibles'] ?? 'Non spécifié'}",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SeatSelectionPage(ride: ride),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 12, 17, 51),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          child: const Text("Voir Détails"),
                        ),
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

class SeatSelectionPage extends StatefulWidget {
  final Map<String, dynamic> ride;

  const SeatSelectionPage({required this.ride, super.key});

  @override
  _SeatSelectionPageState createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  int selectedSeats = 1;

  // Enregistrer la réservation dans Firestore
  Future<void> saveReservation() async {
    final trajet = widget.ride['trajet'];
    final prix = widget.ride['prix'];
    final availableSeats = widget.ride['places_disponibles'] ?? 0;

    // Récupérer l'ID du passager (utilisateur actuellement connecté)
    final user = FirebaseAuth.instance.currentUser;
    final idPassager = user?.uid;

    if (idPassager == null) {
      print(
          "Utilisateur non authentifié. Impossible d'enregistrer la réservation.");
      return;
    }

    // Récupérer l'ID du conducteur depuis 'userId' dans la collection 'annonces'
    final idConducteur = widget.ride['userId'];

    if (idConducteur == null) {
      print("Erreur : ID du conducteur manquant dans les données du trajet.");
      return;
    }
    print("ID du conducteur : $idConducteur");

    // Récupérer le FCM token du conducteur depuis la collection 'users'
    try {
      final conducteurSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(idConducteur)
          .get();

      if (!conducteurSnapshot.exists) {
        print("Erreur : Aucun utilisateur trouvé avec cet ID : $idConducteur");
        return;
      }

      final fcmToken = conducteurSnapshot.data()?['usertoken'];
      if (fcmToken == null) {
        print("Erreur : Token FCM manquant pour l'utilisateur $idConducteur");
        return;
      }
      print("Token FCM du conducteur : $fcmToken");

      // Enregistrer la réservation dans Firestore avec les nouveaux champs
      await FirebaseFirestore.instance.collection('reservations').add({
        'trajet': trajet,
        'prix': prix,
        'places_reservees': selectedSeats,
        'etat': 'en attente',
        'date': DateTime.now(),
        'idpassager': idPassager, // ID du passager
        'idconducteur': idConducteur, // ID du conducteur
        'fcmtoken': fcmToken, // FCM token du conducteur
      });

      print("Réservation enregistrée avec succès !");
    } catch (e) {
      print("Erreur lors de l'enregistrement de la réservation : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final trajet = widget.ride['trajet'];
    final prix = widget.ride['prix'];
    final availableSeats = widget.ride['places_disponibles'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sélectionnez les places"),
        backgroundColor: const Color.fromARGB(255, 12, 17, 51),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "Trajet : ${trajet['departureCity']} ➡️ ${trajet['arrivalCity']}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Prix par place : ${prix['amount']} ${prix['currency']}",
              style: const TextStyle(fontSize: 16, color: Colors.green),
            ),
            const SizedBox(height: 20),
            Text(
              "Nombre de places : $selectedSeats",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Bouton de diminution
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (selectedSeats > 1) {
                        selectedSeats--;
                      }
                    });
                  },
                  color: selectedSeats > 1
                      ? Colors.black
                      : Colors.grey, // Change la couleur si désactivé
                ),
                // Affiche le nombre de places sélectionnées
                Text(
                  "$selectedSeats",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // Bouton d'augmentation
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      if (selectedSeats < availableSeats) {
                        selectedSeats++;
                      }
                    });
                  },
                  color: selectedSeats < availableSeats
                      ? Colors.black
                      : Colors.grey, // Change la couleur si désactivé
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await saveReservation();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Confirmation"),
                    content: Text(
                        "Vous avez réservé $selectedSeats places pour ce trajet."),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context); // Retour à la page précédente
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 12, 17, 51),
              ),
              child: const Text("Confirmer la réservation"),
            ),
          ],
        ),
      ),
    );
  }
}
