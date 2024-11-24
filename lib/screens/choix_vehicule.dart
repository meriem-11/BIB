import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projet_covoiturage/screens/annonce_screen.dart';
import 'package:projet_covoiturage/screens/home.dart';
import 'package:projet_covoiturage/screens/annoncelist_screen.dart';
import 'package:projet_covoiturage/screens/vehicule_screen.dart';

class ChoixVehiculeScreen extends StatefulWidget {
  final String annonceId;
  const ChoixVehiculeScreen({super.key, required this.annonceId});
  @override
  _ChoixVehiculeScreenState createState() => _ChoixVehiculeScreenState();
}
class _ChoixVehiculeScreenState extends State<ChoixVehiculeScreen> {
  String? selectedVehicle;
  int _selectedIndex = -1;
  late Future<List<Map<String, dynamic>>> _vehicles;
  String? _selectedVehicleId;
  List<Map<String, dynamic>> _vehiclesList = [];
  Future<void> _saveVehicleAndShowFinalAnnounce() async {
    if (_selectedVehicleId == null) {
      debugPrint('Veuillez choisir un véhicule.');
      return;
    }
    try {
      final annonceSnapshot = await FirebaseFirestore.instance
          .collection('annonces')
          .doc(widget.annonceId)
          .get();
      if (!annonceSnapshot.exists) {
        debugPrint('Annonce introuvable.');
        return;
      }
      final annonceData = annonceSnapshot.data() as Map<String, dynamic>;
      final dateDepart = annonceSnapshot['date_depart']['selectedDate'];
      final trajet = annonceSnapshot['trajet'];
      final prix = annonceData['prix'];
      final vehicleSnapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(_selectedVehicleId)
        .get();
 if (!vehicleSnapshot.exists) {
      debugPrint('Véhicule introuvable.');
      return;
    }
    final vehicleData = vehicleSnapshot.data() as Map<String, dynamic>;
      await FirebaseFirestore.instance
          .collection('annonces')
          .doc(widget.annonceId)
          .update({
       'vehicule': _selectedVehicleId,
      'vehicule_details': vehicleData,
        'prix': prix,
        'date_depart': {
          'selectedDate': dateDepart,
        },
        'trajet': trajet, 
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FinalAnnounceScreen(annonceId: widget.annonceId),
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement du véhicule: $e');
     
    }
  }

  @override
  void initState() {
    super.initState();
    _vehicles = _getVehicles();
  }

  Future<List<Map<String, dynamic>>> _getVehicles() async {
    final snapshot = await FirebaseFirestore.instance.collection('vehicles').get();
    final vehicles = snapshot.docs.map((doc) {
      final vehicleData = doc.data();
      vehicleData['id'] = doc.id;
      return vehicleData;
    }).toList();

    setState(() {
      _vehiclesList = vehicles;
    });

    return vehicles;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un véhicule'),
        backgroundColor: const Color.fromARGB(255, 242, 236, 244),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>( 
        future: _vehicles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun véhicule trouvé'));
          } else {
            final vehicles = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120.0),
                child: Column(
                  children: [
                    ...vehicles.map((vehicle) {
                      final vehicleId = vehicle['id'] ?? '';
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedVehicleId = vehicleId;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: _selectedVehicleId == vehicleId ? Colors.teal.shade100 : Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: _selectedVehicleId == vehicleId ? Colors.teal.shade400 : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedVehicleId == vehicleId
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: _selectedVehicleId == vehicleId
                                    ? Colors.teal.shade600
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  vehicle['model'] ?? 'Modèle inconnu',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    })
                  ],
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton(
          onPressed: _saveVehicleAndShowFinalAnnounce,
          // ignore: sort_child_properties_last
          child: const Icon(Icons.check),
          backgroundColor: _selectedVehicleId != null
              ? const Color.fromARGB(255, 90, 164, 165)
              : Colors.grey,
          tooltip: 'Confirmer la sélection',
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AnnonceListScreen()),
      );
    }
   if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VehicleScreen()),
      );
    }
  }
}
