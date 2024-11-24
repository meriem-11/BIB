import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(Icons.home, 0),
          _buildNavBarItem(Icons.assignment, 1),
          const SizedBox(width: 10),
          _buildNavBarItem(Icons.history, 2),
          _buildNavBarItem(Icons.directions_car, 3),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, int index) {
    return InkWell(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selectedIndex == index
                ? const Color.fromARGB(255, 12, 17, 51)
                : const Color(0xFF757575),
            size: 30,
          ),
        ],
      ),
    );
  }
}
