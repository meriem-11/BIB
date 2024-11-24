import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet_covoiturage/screens/home.dart';
import 'package:projet_covoiturage/screens/map_screen.dart';
import 'package:projet_covoiturage/screens/prix_screen.dart';
import 'package:projet_covoiturage/screens/annoncelist_screen.dart';

class DateDepartScreen extends StatefulWidget {
  final String annonceId;

  const DateDepartScreen({super.key, required this.annonceId});

  @override
  _DateDepartScreenState createState() => _DateDepartScreenState();
}

class _DateDepartScreenState extends State<DateDepartScreen> {
  DateTime? selectedDate;
  DateTime _selectedDate = DateTime.now();
  int _selectedIndex = -1;

  Future<void> _saveDateAndMoveToNextStep() async {
    if (_selectedDate == null) {
      debugPrint('Veuillez sélectionner une date.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('annonces')
          .doc(widget.annonceId)
          .update({
        'date_depart': {
          'selectedDate': _selectedDate.toIso8601String(),
        },
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PrixScreen(annonceId: widget.annonceId),
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement dans Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'enregistrement du trajet.')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
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
    }
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AnnonceListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Date de départ',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('lib/assets/v2.jpg'), 
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken), 
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(36.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Quand souhaitez-vous partir ?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 30.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(width: 2, color: const Color.fromARGB(255, 12, 17, 51)),
                    color: Colors.white.withOpacity(0.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 8.0,
                      ),
                    ],
                  ),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveDateAndMoveToNextStep,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: const Color.fromARGB(255, 12, 17, 51),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Suivant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 70,
        child: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildNavBarItem(Icons.home, 0),
              buildNavBarItem(Icons.assignment, 1),
              const SizedBox(width: 10),
              buildNavBarItem(Icons.history, 2),
              buildNavBarItem(Icons.directions_car, 3),
            ],
          ),
        ),
      ),
      floatingActionButton: ClipOval(
        child: Material(
          color: const Color.fromARGB(255, 90, 164, 165),
          elevation: 10,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
            child: const SizedBox(
              width: 60,
              height: 60,
              child: Icon(
                CupertinoIcons.add_circled,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
            color: _selectedIndex == index ? const Color.fromARGB(255, 12, 17, 51) : const Color(0xFF757575),
            size: 30,
          ),
        ],
      ),
    );
  }
}
