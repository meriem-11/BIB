import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projet_covoiturage/screens/home.dart';
import 'package:projet_covoiturage/screens/vehicule_screen.dart';

class AnnonceListScreen extends StatefulWidget {
  const AnnonceListScreen({super.key});

  @override
  _AnnonceListScreenState createState() => _AnnonceListScreenState();
}

class _AnnonceListScreenState extends State<AnnonceListScreen> {
  int _selectedIndex = -1;

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
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VehicleScreen()),
      );
    }
  }

  Future<void> _deleteAnnonce(String annonceId) async {
    await FirebaseFirestore.instance.collection('annonces').doc(annonceId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Annonce supprimée avec succès")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Annonces'),
        backgroundColor: const Color.fromARGB(255, 242, 236, 244),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('annonces').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Une erreur est survenue.'));
          }

          final annonces = snapshot.data?.docs ?? [];

          if (annonces.isEmpty) {
            return const Center(child: Text('Aucune annonce disponible.'));
          }

          return ListView.builder(
            itemCount: annonces.length,
            itemBuilder: (context, index) {
              final annonce = annonces[index];
              final annonceId = annonce.id;
              final dateDepart = annonce['date_depart']?['selectedDate'] ?? 'Inconnue';
              final prix = annonce['prix'];
              final trajet = annonce['trajet'];
              final vehiculeDetails = annonce['vehicule_details'];
              String formattedDate = 'Inconnue';
              if (dateDepart != null) {
                try {
                  final selectedDate = DateTime.parse(dateDepart);
                  formattedDate = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
                } catch (e) {
                  formattedDate = 'Format de date invalide';
                }
              }

              final prixAmount = prix != null ? "${prix['amount']} ${prix['currency']}" : 'Inconnu';
              final departureCity = trajet['departureCity'] ?? 'Inconnu';
              final arrivalCity = trajet['arrivalCity'] ?? 'Inconnu';

              String vehicleBrand = 'Inconnu';
              if (vehiculeDetails != null && vehiculeDetails is Map) {
                vehicleBrand = vehiculeDetails['brand'] ?? 'Inconnu';
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_car, color: Color.fromARGB(255, 90, 164, 165)),
                          const SizedBox(width: 5),
                          Text(
                            vehicleBrand,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color.fromARGB(255, 90, 164, 165)),
                          const SizedBox(width: 5),
                          Text(
                            '$departureCity → $arrivalCity',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color.fromARGB(255, 90, 164, 165)),
                          const SizedBox(width: 5),
                          Text(
                            'Départ: $formattedDate',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Color.fromARGB(255, 90, 164, 165)),
                          const SizedBox(width: 5),
                          Text(
                            prixAmount,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Color.fromARGB(255, 90, 164, 165)),
                        onPressed: () => _deleteAnnonce(annonceId),
                      ),
                    ],
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
          ),
        ],
      ),
    );
  }
}
