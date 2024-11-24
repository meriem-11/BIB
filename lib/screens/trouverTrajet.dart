import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_covoiturage/screens/resultatTrajet.dart';

class LocationService {
  static Future<List<dynamic>> fetchSuggestions(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Erreur API Nominatim: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Erreur de connexion: $e");
      return [];
    }
  }
}

class SearchRidePage extends StatelessWidget {
  const SearchRidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un Trajet'),
        backgroundColor:
            const Color(0xFF0C1133), 
      ),
      body: Stack(
        children: [
          // Image de fond
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'lib/assets/background.jpg'), 
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SearchRideForm(),
          ),
        ],
      ),
    );
  }
}

class SearchRideForm extends StatefulWidget {
  const SearchRideForm({super.key});

  @override
  State<SearchRideForm> createState() => _SearchRideFormState();
}

class _SearchRideFormState extends State<SearchRideForm> {
  final TextEditingController departureController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  Timer? _debounce;

  List<dynamic> suggestions = [];
  String activeField = '';

  @override
  void dispose() {
    departureController.dispose();
    destinationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void onSearchChanged(String query, String field) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await LocationService.fetchSuggestions(query);
      setState(() {
        activeField = field;
        suggestions = results;
      });
    });
  }

  void onSuggestionSelected(String suggestion) {
    setState(() {
      if (activeField == 'departure') {
        departureController.text = suggestion;
      } else {
        destinationController.text = suggestion;
      }
      suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Recherchez votre trajet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C1133),
                ),
              ),
              const SizedBox(height: 20),
              buildSearchField(
                label: "Lieu de départ",
                icon: Icons.location_on_outlined,
                controller: departureController,
                onChanged: (value) => onSearchChanged(value, 'departure'),
              ),
              const SizedBox(height: 16),
              buildSearchField(
                label: "Lieu d’arrivée",
                icon: Icons.flag_outlined,
                controller: destinationController,
                onChanged: (value) => onSearchChanged(value, 'destination'),
              ),
              const SizedBox(height: 16),
              if (suggestions.isNotEmpty)
                Container(
                  height: 150,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion =
                          suggestions[index]['display_name'] ?? '';
                      return ListTile(
                        leading: const Icon(Icons.location_on,
                            color: Color(0xFF5AA4A5)),
                        title: Text(suggestion),
                        onTap: () => onSuggestionSelected(suggestion),
                      );
                    },
                  ),
                ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RideResultsPage(
                        departure: departureController.text,
                        destination: destinationController.text,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Rechercher',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF5AA4A5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF5AA4A5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF5AA4A5), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
