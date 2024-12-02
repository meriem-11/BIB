import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projet_covoiturage/screens/ListAnnoncePassager.dart';
import 'package:projet_covoiturage/screens/PassengerReservationPage.dart';
import 'package:projet_covoiturage/screens/homeP.dart';

Future<List<Map<String, dynamic>>> fetchRides(
    String departure, String destination) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('annonces')
        .where('trajet.departureCity', isEqualTo: departure)
        .where('trajet.arrivalCity', isEqualTo: destination)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
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

  Future<List<Map<String, dynamic>>> fetchRides(
      String departure, String destination) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('annonces')
          .where('trajet.departureCity', isEqualTo: departure)
          .where('trajet.arrivalCity', isEqualTo: destination)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Erreur lors de la récupération des trajets : $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Résultats de la recherche",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
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
              final vehicleDetails = ride['vehicule_details'];
              final dateDepartField = ride['date_depart'];

              // Vérification si `date_depart` est un Map (ex: Map avec une clé 'selectedDate')
              String formattedDate = "Non spécifiée";
              if (dateDepartField is Timestamp) {
                // Si `date_depart` est un Timestamp, on le convertit en DateTime
                final dateDepart = dateDepartField.toDate();
                formattedDate = DateFormat('dd MMM yyyy').format(dateDepart);
              } else if (dateDepartField is Map &&
                  dateDepartField.containsKey('selectedDate')) {
                // Si `date_depart` est un Map, et contient une clé 'selectedDate'
                final dateDepartString =
                    dateDepartField['selectedDate'] as String;
                final dateDepart =
                    DateFormat("yyyy-MM-dd").parse(dateDepartString);
                formattedDate = DateFormat('dd MMM yyyy').format(dateDepart);
              } else {
                final currentDate = DateTime.now();
                formattedDate = DateFormat('dd MMM yyyy').format(currentDate);
              }

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
                      // Trajet info
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
                      // Date info
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: Colors.grey[600], size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "Date de départ : $formattedDate",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Prix info
                      Row(
                        children: [
                          const Icon(Icons.attach_money,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "Prix : ${prix['amount']} ${prix['currency'].toString()}",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Détails du véhicule
                      Row(
                        children: [
                          const Icon(Icons.car_repair,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${vehicleDetails['brand']} ${vehicleDetails['model']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "Couleur : ${vehicleDetails['color']}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "Type : ${vehicleDetails['type']}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "Capacité : ${vehicleDetails['seats']} places",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
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
                                builder: (context) => SeatSelectionPage(
                                  ride: ride,
                                  annonceId: '',
                                ),
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
                          child: const Text("Réserver"),
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
  final String annonceId;
  const SeatSelectionPage(
      {required this.ride, super.key, required this.annonceId});

  @override
  _SeatSelectionPageState createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  int selectedSeats = 1;
  late int availableSeats;
  int _selectedIndex = 2; // L'index sélectionné pour la barre de navigation

  // Fonction de gestion de la navigation
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen2()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const PassengerReservationsPage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AnnonceListScreenP()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    availableSeats = widget.ride['vehicule_details']?['seats'] ?? 0;
    print("Places disponibles (seats) : $availableSeats");
  }

  Future<void> saveReservation() async {
    final trajet = widget.ride['trajet'];
    final prix = widget.ride['prix'];
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print(
          "Utilisateur non authentifié. Impossible d'enregistrer la réservation.");
      return;
    }

    final idPassager = user.uid;
    final idConducteur = widget.ride['userId'];

    if (selectedSeats > availableSeats) {
      // Affiche un message d'erreur si les places sélectionnées dépassent la disponibilité
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Erreur"),
          content: const Text(
              "Vous ne pouvez pas réserver plus de places que celles disponibles."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    try {
      // Ajouter la réservation dans Firestore
      final passengerToken = await FirebaseMessaging.instance.getToken();

      if (idConducteur == null || passengerToken == null) {
        print("Erreur : Informations manquantes pour l'enregistrement.");
        return;
      }

      // Obtenir le token FCM du conducteur
      final conducteurSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(idConducteur)
          .get();

      final driverToken = conducteurSnapshot.data()?['usertoken'];

      if (driverToken == null) {
        print("Erreur : Aucun token trouvé pour l'utilisateur $idConducteur.");
        return;
      }

      await FirebaseFirestore.instance.collection('reservations').add({
        'trajet': trajet,
        'prix': prix,
        'places_reservees': selectedSeats,
        'etat': 'en attente',
        'date': DateTime.now(),
        'idpassager': idPassager,
        'idconducteur': idConducteur,
        'fcmtoken': driverToken,
        'passengerToken': passengerToken,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("reservation envoyée avec succès!")),
      );
      // Mise à jour des places disponibles dans l'annonce
      final newAvailableSeats = availableSeats - selectedSeats;
      await FirebaseFirestore.instance
          .collection('annonces')
          .doc(widget.ride['id'])
          .update({'vehicule_details.seats': newAvailableSeats});

      print("Réservation confirmée : $selectedSeats places.");

      // Notification au conducteur
      await sendNotificationToDriver(driverToken, trajet, idPassager);

      // Mise à jour locale de l'état
      setState(() {
        availableSeats = newAvailableSeats;
      });

      // Rediriger vers PassengerReservationPage
      print("Redirection vers PassengerReservationsPage...");
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const HomeScreen2(),
        ),
      );
    } catch (e) {
      print("Erreur lors de l'enregistrement : $e");
    }
  }

  Future<void> sendNotificationToDriver(String driverToken,
      Map<String, dynamic> trajet, String idPassager) async {
    final message = {
      "to": driverToken,
      "notification": {
        "title": "Nouvelle réservation",
        "body":
            "Un passager a réservé votre trajet de ${trajet['departureCity']} à ${trajet['arrivalCity']}.",
      },
      "data": {
        "idPassager": idPassager,
        "trajet": trajet,
      }
    };

    try {
      print("Notification envoyée au conducteur : $message");
    } catch (e) {
      print("Erreur lors de l'envoi de la notification : $e");
    }
  }

  Widget _buildSeatsSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nombre de places',
              style: TextStyle(fontSize: 16),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: selectedSeats > 1
                      ? () {
                          setState(() {
                            selectedSeats--;
                          });
                        }
                      : null,
                ),
                Text(
                  '$selectedSeats',
                  style: const TextStyle(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: selectedSeats < availableSeats
                      ? () {
                          setState(() {
                            selectedSeats++;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trajet = widget.ride['trajet'];
    final prix = widget.ride['prix'];

    if (availableSeats <= 0) {
      return Scaffold(
        appBar: AppBar(title: const Text("Sélectionnez les places")),
        body: const Center(
          child: Text("Aucune place disponible pour ce trajet."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sélectionnez les places",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 12, 17, 51),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            _buildSeatsSelector(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: saveReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 12, 17, 51),
              ),
              child: const Text("Confirmer la réservation"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildNavBarItem(Icons.home, 0),
            buildNavBarItem(Icons.assignment, 1),
            buildNavBarItem(Icons.history, 2),
          ],
        ),
      ),
    );
  }

  Widget buildNavBarItem(IconData icon, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index
                ? const Color.fromARGB(255, 90, 164, 165)
                : const Color.fromARGB(255, 13, 17, 50),
            size: 30,
          ),
        ],
      ),
    );
  }
}
