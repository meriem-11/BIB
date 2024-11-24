import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet_covoiturage/screens/home.dart';
import 'package:projet_covoiturage/screens/annoncelist_screen.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  _VehicleScreenState createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _customModelController = TextEditingController(); 
  int _seats = 1;
  bool _isLoading = false;
  bool _isCustomModel = false; 

  List<String> vehicleModels = [
    'Toyota Corolla', 'Honda Civic', 'Ford Focus', 'BMW X5', 'Audi A4', 'Autre' 
  ];

  List<String> vehicleBrands = [
    'Alfa Romeo', 'Audi', 'BMW', 'Citroën', 'DACIA', 'Fiat', 'Ford', 'Mercedes-Benz', 
    'Nissan', 'Opel', 'Peugeot', 'Renault', 'SEAT', 'Toyota', 'Volkswagen',
    'Abarth', 'Aiways', 'Alpine', 'Aston Martin', 'Bentley', 'BYD', 'Cadillac', 'Caterham', 
    'Chevrolet', 'Chrysler', 'Corvette', 'Cupra', 'Daewoo', 'Daihatsu', 'Daimler', 'Dodge', 
    'DS', 'Ferrari', 'Fisker', 'Honda', 'Hummer', 'Hyundai', 'Infiniti', 'Jaguar', 
    'Jeep', 'KIA', 'Lada', 'Lamborghini', 'Lancia', 'Land Rover', 'Lexus', 'Lotus', 
    'Lynk & Co', 'Mahindra', 'Maserati', 'Mazda', 'McLaren', 'MG', 'Mini', 'Mitsubishi', 
    'Porsche', 'Proton', 'Rolls-Royce', 'Saab', 'Skoda', 'Smart MCC', 'Subaru', 
    'Suzuki', 'Tesla', 'TVR', 'Venturi', 'Vinfast', 'Volvo'
  ];

  List<String> vehicleTypes = [
    'Petite voiture', 'Voiture familiale', 'Grosse voiture', 'Voiture de luxe'
  ];

  Future<void> _addVehicleToFirestore() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final model = _isCustomModel ? _customModelController.text.trim() : _modelController.text.trim();
      final type = _typeController.text.trim();
      final color = _colorController.text.trim();
      final brand = _brandController.text.trim();

      final vehiculeData = {
        'model': model,
        'type': type,
        'color': color,
        'brand': brand,
        'seats': _seats,
        'timestamp': FieldValue.serverTimestamp(),
      };

      try {
        await FirebaseFirestore.instance.collection('vehicles').add(vehiculeData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Véhicule ajouté avec succès!")),
        );
        _modelController.clear();
        _customModelController.clear();
        _typeController.clear();
        _colorController.clear();
        _brandController.clear();
        setState(() {
          _seats = 1;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'ajout du véhicule: $e")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un véhicule'),
        backgroundColor: const Color.fromARGB(255, 242, 236, 244),
        elevation: 5,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/v1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildModelSelector(),
                  const SizedBox(height: 16),
                  _buildTextField(_colorController, 'Couleur du véhicule', Icons.color_lens),
                  const SizedBox(height: 12),
                  _buildBrandSelector(),
                  const SizedBox(height: 12),
                  _buildTypeSelector(),
                  const SizedBox(height: 20),
                  _buildSeatsSelector(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addVehicleToFirestore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 90, 164, 165),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Ajouter le véhicule"),
                  ),
                ],
              ),
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

  Widget _buildModelSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _modelController.text.isEmpty ? null : _modelController.text,
              onChanged: (value) {
                setState(() {
                  _modelController.text = value ?? '';
                  _isCustomModel = value == 'Autre'; 
                });
              },
              items: vehicleModels
                  .map((String model) => DropdownMenuItem(value: model, child: Text(model)))
                  .toList(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.directions_car),
                labelText: 'Sélectionner un modèle',
                labelStyle: const TextStyle(fontSize: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Sélectionner un modèle est requis';
                }
                return null;
              },
            ),
            if (_isCustomModel) 
              TextFormField(
                controller: _customModelController,
                decoration: const InputDecoration(
                  labelText: 'Entrez votre modèle personnalisé',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_isCustomModel && (value == null || value.isEmpty)) {
                    return 'Veuillez entrer un modèle personnalisé';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: DropdownButtonFormField<String>(
          value: _brandController.text.isEmpty ? null : _brandController.text,
          onChanged: (value) {
            setState(() {
              _brandController.text = value ?? '';
            });
          },
          items: vehicleBrands
              .map((String brand) => DropdownMenuItem(value: brand, child: Text(brand)))
              .toList(),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.car_repair),
            labelText: 'Sélectionner une marque',
            labelStyle: const TextStyle(fontSize: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Sélectionner une marque est requis';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: DropdownButtonFormField<String>(
          value: _typeController.text.isEmpty ? null : _typeController.text,
          onChanged: (value) {
            setState(() {
              _typeController.text = value ?? '';
            });
          },
          items: vehicleTypes
              .map((String type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.car_rental),
            labelText: 'Sélectionner un type',
            labelStyle: const TextStyle(fontSize: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Sélectionner un type est requis';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildSeatsSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nombre de places',
              style: TextStyle(fontSize: 16),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _seats > 1
                      ? () {
                          setState(() {
                            _seats--;
                          });
                        }
                      : null,
                ),
                Text(
                  '$_seats',
                  style: const TextStyle(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _seats < 7
                      ? () {
                          setState(() {
                            _seats++;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ est requis';
        }
        return null;
      },
    );
  }
}
