import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'annoncelist_screen.dart';
import 'home.dart';
import 'vehicule_screen.dart';

class FinalAnnounceScreen extends StatelessWidget {
  final String annonceId;

  const FinalAnnounceScreen({super.key, required this.annonceId});

  Future<Map<String, dynamic>> _getVehicleDetails(String vehicleId) async {
    try {
      final vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();
      if (vehicleSnapshot.exists) {
        return vehicleSnapshot.data() as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des détails du véhicule: $e');
      return {};
    }
  }

  Future<void> _saveAnnonceWithUser(String annonceId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('annonces')
            .doc(annonceId)
            .update({
          'userId': user.uid,
        });
      } catch (e) {
        debugPrint("Erreur lors de l'enregistrement de l'ID utilisateur : $e");
      }
    } else {
      debugPrint("Aucun utilisateur connecté.");
    }
  }

  @override
  Widget build(BuildContext context) {
    _saveAnnonceWithUser(annonceId);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('annonces')
          .doc(annonceId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Aucune annonce trouvée.'));
        }

        var annonceData = snapshot.data!;
        var trajet = annonceData['trajet'];
        var date = annonceData['date_depart'];
        var prix = annonceData['prix'];
        var vehicule = annonceData['vehicule'];

        var departureCity = trajet['departureCity'] ?? 'Inconnu';
        var arrivalCity = trajet['arrivalCity'] ?? 'Inconnu';

        String formattedDate = 'Inconnu';
        if (date != null && date['selectedDate'] != null) {
          var dateString = date['selectedDate'];
          try {
            var selectedDate = DateTime.parse(dateString);
            formattedDate =
                "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
          } catch (e) {
            formattedDate = 'Format de date invalide';
          }
        }

        var priceValue =
            prix != null ? "${prix['amount']} ${prix['currency']}" : 'Inconnu';

        return FutureBuilder<Map<String, dynamic>>(
          future: _getVehicleDetails(vehicule),
          builder: (context, vehicleSnapshot) {
            if (vehicleSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var vehicleChoice = vehicleSnapshot.data ?? {};
            var vehicleModel = vehicleChoice['model'] ?? 'Inconnu';
            var vehicleBrand = vehicleChoice['brand'] ?? 'Inconnu';

            return Scaffold(
              appBar: AppBar(
                title: const Text('Annonce Finalisée'),
                backgroundColor: const Color.fromARGB(255, 143, 193, 194),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Détails de l\'annonce',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 90, 164, 165),
                              ),
                            ),
                          ),
                          const Divider(
                            height: 30,
                            thickness: 1.5,
                            color: Color.fromARGB(255, 90, 164, 165),
                            indent: 20,
                            endIndent: 20,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            icon: Icons.location_on,
                            color: const Color.fromARGB(255, 90, 164, 165),
                            label: 'Trajet:',
                            value: '$departureCity → $arrivalCity',
                          ),
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            color: const Color.fromARGB(255, 90, 164, 165),
                            label: 'Date de départ:',
                            value: formattedDate,
                          ),
                          _buildDetailRow(
                            icon: Icons.attach_money,
                            color: const Color.fromARGB(255, 90, 164, 165),
                            label: 'Prix:',
                            value: priceValue,
                          ),
                          _buildDetailRow(
                            icon: FontAwesomeIcons.car,
                            color: const Color.fromARGB(255, 90, 164, 165),
                            label: 'Véhicule:',
                            value: '$vehicleModel ($vehicleBrand)',
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: BottomAppBar(
                shape: const CircularNotchedRectangle(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    buildNavBarItem(context, Icons.home, 0),
                    buildNavBarItem(context, Icons.assignment, 1),
                    buildNavBarItem(context, Icons.history, 2),
                    buildNavBarItem(context, Icons.directions_car, 3),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Text(
            '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNavBarItem(BuildContext context, IconData icon, int index) {
    return InkWell(
      onTap: () => _onItemTapped(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
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
}
