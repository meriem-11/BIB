import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projet_covoiturage/screens/NotificationsListPage.dart';
import 'package:projet_covoiturage/screens/ReservationHistoryPageDriver.dart';
import 'package:projet_covoiturage/screens/gainConducteurdart';
import 'package:projet_covoiturage/screens/map_screen.dart';
import 'package:projet_covoiturage/screens/annoncelist_screen.dart';
import 'package:projet_covoiturage/screens/vehicule_screen.dart';
import 'package:projet_covoiturage/custom_navbar.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int notificationCount = 0;
  StreamSubscription? _notificationSubscription;

  static final List<Widget> _screens = [
    Container(),
    const Placeholder(),
    const Placeholder(),
    const Placeholder(),
    const Placeholder(),
  ];
  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    final currentDriverId = FirebaseAuth.instance.currentUser?.uid;

    if (currentDriverId != null) {
      _notificationSubscription = FirebaseFirestore.instance
          .collection('reservations')
          .where('idconducteur', isEqualTo: currentDriverId)
          .where('etat', isEqualTo: 'en attente')
          .snapshots()
          .listen((snapshot) {
        setState(() {
          notificationCount = snapshot.docs.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
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
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/voiture.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              automaticallyImplyLeading:
                  false, // Désactiver le bouton de retour

              backgroundColor: const Color.fromARGB(255, 12, 17, 51),
              title: const Text(
                'BIP BIP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          notificationCount = 0;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NotificationsListPage()),
                        );
                      },
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$notificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                /*  IconButton(
                  icon: const Icon(
                    Icons.attach_money, // Icône pour les gains (monnaie)
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DriverIncomeScreen(
                                driverId: 'driver_id',
                              )), // Naviguer vers la page des gains
                    );
                  },
                ),*/
              ],
            ),
          ),
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MapScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 12, 17, 51),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Publier annonce'),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      floatingActionButton: ClipOval(
        child: Material(
          color: const Color.fromARGB(255, 12, 17, 51),
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
}
