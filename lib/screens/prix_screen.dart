// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet_covoiturage/screens/choix_vehicule.dart';
import 'package:projet_covoiturage/screens/home.dart';
import 'package:projet_covoiturage/screens/annoncelist_screen.dart';
import 'package:projet_covoiturage/screens/vehicule_screen.dart';

class PrixScreen extends StatefulWidget {
 final String annonceId;

  const PrixScreen({super.key, required this.annonceId});
  @override
  _PrixScreenState createState() => _PrixScreenState();
}

class _PrixScreenState extends State<PrixScreen> {
  int _selectedIndex = 0;
  final TextEditingController _priceController = TextEditingController(text: "0");
  String _displayedPrice = "0";
  
Future<void> _savePriceAndMoveToNextStep() async {
    final price = _priceController.text.trim();
    if (price.isEmpty) {
      debugPrint('Veuillez entrer un prix.');
      return;
    }

 try {
    DocumentSnapshot annonceSnapshot = await FirebaseFirestore.instance
        .collection('annonces')
        .doc(widget.annonceId)
        .get();

    if (!annonceSnapshot.exists) {
      debugPrint('Annonce non trouvée.');
      return;
    }

    final dateDepart = annonceSnapshot['date_depart']['selectedDate'];
    final trajet = annonceSnapshot['trajet'];
 await FirebaseFirestore.instance
        .collection('annonces')
        .doc(widget.annonceId)
        .update({
      'prix': {
        'amount': price,
        'currency': 'DNT',  
      },
      'date_depart': {
        'selectedDate': dateDepart,
      },
      'trajet': trajet, 
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChoixVehiculeScreen(annonceId: widget.annonceId),
      ),
    );
  } catch (e) {
    debugPrint('Erreur lors de l\'enregistrement du prix: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erreur lors de l\'enregistrement du prix.')),
    );
  }
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
    } if (index == 1) {
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

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 236, 244),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Prix Par Personne',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _priceController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _displayedPrice = value.isNotEmpty ? value : "0";
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              '$_displayedPrice DNT',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
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
            buildNavBarItem(Icons.directions_car, 3),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _savePriceAndMoveToNextStep, 
        backgroundColor: const Color.fromARGB(255, 143, 193, 194),
        child: const Icon(Icons.arrow_forward),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
