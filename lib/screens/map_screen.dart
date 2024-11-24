import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet_covoiturage/screens/date_depart.dart';
import 'package:projet_covoiturage/screens/home.dart';
import 'package:projet_covoiturage/screens/annoncelist_screen.dart';
import 'package:projet_covoiturage/screens/vehicule_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  LatLng? departureLocation;
  LatLng? arrivalLocation;
  List<LatLng> routePoints = [];
  List<Marker> markers = [];

  final String orsApiKey =
      '5b3ce3597851110001cf6248706aec7fc0164552bc691a86843fbed0';

  final TextEditingController _departureCityController = TextEditingController();
  final TextEditingController _arrivalCityController = TextEditingController();

  final LatLngBounds tunisiaBounds = LatLngBounds(
    const LatLng(30.0, 7.0),
    const LatLng(37.5, 11.5),
  );

  Future<LatLng?> _getCoordinatesFromCity(String cityName) async {
    final response = await http.get(
      Uri.parse(
        'https://nominatim.openstreetmap.org/search?city=$cityName&countrycodes=TN&format=json&addressdetails=1',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        return LatLng(lat, lon);
      }
    }
    debugPrint('Erreur lors du géocodage de $cityName');
    return null;
  }

 Future<void> _fetchRouteCoordinates() async {
  final departureCity = _departureCityController.text.trim();
  final arrivalCity = _arrivalCityController.text.trim();

  if (departureCity.isEmpty || arrivalCity.isEmpty) {
    debugPrint('Veuillez entrer des noms de villes valides.');
    return;
  }

  final departureCoords = await _getCoordinatesFromCity(departureCity);
  final arrivalCoords = await _getCoordinatesFromCity(arrivalCity);

  if (departureCoords == null || arrivalCoords == null) {
    debugPrint('Coordonnées non trouvées pour l\'un des lieux');
    return;
  }

  setState(() {
    departureLocation = departureCoords;
    arrivalLocation = arrivalCoords;
  });

  final response = await http.get(
    Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey'
      '&start=${departureLocation!.longitude},${departureLocation!.latitude}'
      '&end=${arrivalLocation!.longitude},${arrivalLocation!.latitude}',
    ),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final List<dynamic> coords = data['features'][0]['geometry']['coordinates'];
    setState(() {
      routePoints = coords.map((coord) => LatLng(coord[1], coord[0])).toList();
      markers = [
        Marker(
          width: 80.0,
          height: 80.0,
          point: departureLocation!,
          builder: (ctx) => const Icon(
            Icons.location_on,
            color: Colors.green,
            size: 40.0,
          ),
        ),
        Marker(
          width: 80.0,
          height: 80.0,
          point: arrivalLocation!,
          builder: (ctx) => const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40.0,
          ),
        ),
      ];
    });
  } else {
    debugPrint('Erreur de calcul d\'itinéraire');
  }
}

Future<void> _saveTripAndNavigate() async {
  final departureCity = _departureCityController.text.trim();
  final arrivalCity = _arrivalCityController.text.trim();

  final tripData = {
    'departureCity': departureCity,
    'arrivalCity': arrivalCity,
    'departureLat': departureLocation!.latitude,
    'departureLon': departureLocation!.longitude,
    'arrivalLat': arrivalLocation!.latitude,
    'arrivalLon': arrivalLocation!.longitude,
  };

  try {
    var annonceRef = await FirebaseFirestore.instance.collection('annonces').add({
      'trajet': tripData,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DateDepartScreen(annonceId: annonceRef.id),
      ),
    );
  } catch (e) {
    debugPrint('Erreur lors de l\'enregistrement dans Firestore: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erreur lors de l\'enregistrement du trajet.')),
    );
  }
}


  int _selectedIndex = -1;
  static final List<Widget> _screens = [
    Container(),
    const Placeholder(),
    const Placeholder(),
    const Placeholder(),
  ];

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
        backgroundColor: const Color.fromARGB(255, 143, 193, 194),
        title: const Text('Ajouter trajet'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _departureCityController,
                  decoration: const InputDecoration(
                    labelText: 'Lieu de départ',
                  ),
                ),
                TextField(
                  controller: _arrivalCityController,
                  decoration: const InputDecoration(
                    labelText: 'Lieu d\'arrivée',
                  ),
                ),
                ElevatedButton(
                  onPressed: _fetchRouteCoordinates,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 12, 17, 51),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Ajouter Trajet'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center: const LatLng(33.8869, 9.5375),
                zoom: 7.0,
                minZoom: 6.0,
                maxZoom: 10.0,
                bounds: tunisiaBounds,
                boundsOptions: const FitBoundsOptions(
                  padding: EdgeInsets.all(8.0),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ],
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
        onPressed: _saveTripAndNavigate,
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
            color: _selectedIndex == index ? const  Color(0xFF757575) : const Color.fromARGB(255, 12, 17, 51),
            size: 30,
          ),
        ],
      ),
    );
  }

}
