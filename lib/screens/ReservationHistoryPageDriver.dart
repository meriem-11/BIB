import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Importer intl pour formater les dates
import 'package:projet_covoiturage/custom_navbar.dart';
import 'package:projet_covoiturage/screens/annoncelist_screen.dart';
import 'package:projet_covoiturage/screens/home.dart';
import 'package:projet_covoiturage/screens/vehicule_screen.dart';

class ReservationHistoryPageDriver extends StatefulWidget {
  const ReservationHistoryPageDriver({super.key});

  @override
  _ReservationHistoryPageDriverState createState() =>
      _ReservationHistoryPageDriverState();
}

class _ReservationHistoryPageDriverState
    extends State<ReservationHistoryPageDriver> {
  int _selectedIndex = 2; // L'index sélectionné pour la barre de navigation

  // Fonction de gestion de la navigation
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AnnonceListScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ReservationHistoryPageDriver()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VehicleScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    // Assurez-vous que l'utilisateur est bien authentifié
    if (user == null) {
      return const Center(child: Text("Utilisateur non authentifié"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Historique des réservations",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 12, 17, 51),
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('idconducteur',
                isEqualTo: user?.uid) // Filtrer par ID du conducteur
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Erreur lors du chargement."));
          }

          // Vérifier si les données existent
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucun historique disponible."));
          }

          final reservations = snapshot.data!.docs;

          // Afficher les données récupérées dans la console pour déboguer
          print('Réservations récupérées: ${reservations.length}');

          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final data = reservations[index].data() as Map<String, dynamic>;
              final etat = data['etat']; // Statut de la réservation
              final trajet = data['trajet'];

              // Convertir le Timestamp en DateTime et le formater
              Timestamp timestamp = data['date'];
              DateTime dateTime = timestamp.toDate();
              String formattedDate = "Date non spécifiée"; // Valeur par défaut

              if (timestamp != null) {
                final dateTime = timestamp.toDate();
                final utcMinus8 = dateTime.subtract(Duration(hours: 8));
                formattedDate =
                    DateFormat('dd/MM/yyyy à HH:mm').format(utcMinus8);
              }

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    etat == 'acceptée' ? Icons.check_circle : Icons.cancel,
                    color: etat == 'acceptée' ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  title: Text(
                    "${trajet['departureCity']} ➡️ ${trajet['arrivalCity']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Statut : $etat",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: Text(
                    formattedDate, // Afficher la date formatée
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildNavBarItem(Icons.home, 0),
            buildNavBarItem(Icons.assignment, 1),
            buildNavBarItem(Icons.history, 2),
            buildNavBarItem(Icons.directions_car, 3),
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
