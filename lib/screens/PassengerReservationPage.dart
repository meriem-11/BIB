import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_covoiturage/screens/homeP.dart';

class PassengerReservationsPage extends StatefulWidget {
  const PassengerReservationsPage({super.key});

  @override
  _PassengerReservationsPageState createState() =>
      _PassengerReservationsPageState();
}

class _PassengerReservationsPageState extends State<PassengerReservationsPage> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen2()),
      );
    }
  }

  final String? currentPassengerId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (currentPassengerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Mes Réservations"),
          backgroundColor: const Color.fromARGB(255, 12, 17, 51),
        ),
        body: const Center(
          child: Text(
            "Vous devez être connecté pour voir vos réservations.",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Réservations",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 12, 17, 51),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('idpassager', isEqualTo: currentPassengerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Aucune réservation trouvée.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final reservation =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final trajet = reservation['trajet'] ?? {};
              final etat = reservation['etat'] ?? 'Indéfini';
              final timestamp = reservation['date'] as Timestamp?;

              String formattedDate = "Date non spécifiée"; // Valeur par défaut

              if (timestamp != null) {
                final dateTime = timestamp.toDate();
                final utcMinus8 = dateTime.subtract(Duration(hours: 8));
                formattedDate =
                    DateFormat('dd/MM/yyyy à HH:mm').format(utcMinus8);
              }

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    _getIconForState(etat),
                    color: _getColorForState(etat),
                    size: 30,
                  ),
                  title: Text(
                    "${trajet['departureCity']} ➡️ ${trajet['arrivalCity']}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "État : $etat",
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Date : $formattedDate", // Affichage de la date formatée
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    _showReservationDetails(
                        context, reservation, formattedDate);
                  },
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

  IconData _getIconForState(String state) {
    final normalizedState = state.toLowerCase().trim();

    if (normalizedState == 'acceptée') {
      return Icons.check_circle;
    } else if (normalizedState == 'rejetée' || normalizedState == 'annulée') {
      return Icons.remove_circle_outline;
    } else {
      return Icons.pending_actions;
    }
  }

  Color _getColorForState(String state) {
    final normalizedState = state.toLowerCase().trim();

    if (normalizedState == 'acceptée') {
      return Colors.green;
    } else if (normalizedState == 'rejetée' || normalizedState == 'annulée') {
      return Colors.red;
    } else {
      return const Color.fromARGB(255, 255, 169, 64);
    }
  }

  void _showReservationDetails(
      BuildContext context, Map<String, dynamic> reservation, String date) {
    final trajet = reservation['trajet'] ?? {};
    final etat = reservation['etat'] ?? 'Indéfini';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Détails de la réservation",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color.fromARGB(255, 12, 17, 51),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Départ : ${trajet['departureCity'] ?? 'Non spécifié'}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Arrivée : ${trajet['arrivalCity'] ?? 'Non spécifiée'}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Date : $date",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.info, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "État : $etat",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _getColorForState(etat),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }
}
