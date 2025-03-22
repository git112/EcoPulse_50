import 'package:flutter/material.dart';

class TravelEmissionsCalculator extends StatefulWidget {
  final Function(double) onSave; // Add this line

  const TravelEmissionsCalculator({super.key, required this.onSave});

  @override
  _TravelEmissionsCalculatorState createState() => _TravelEmissionsCalculatorState();
}

class _TravelEmissionsCalculatorState extends State<TravelEmissionsCalculator> {
  final TextEditingController _distanceController = TextEditingController();
  double _calculatedEmissions = 0.0;

  void _calculateEmissions() {
    double distance = double.tryParse(_distanceController.text) ?? 0.0;
    setState(() {
      _calculatedEmissions = distance * 0.2; // Example calculation
    });
  }

  void _saveEmissions() {
    widget.onSave(_calculatedEmissions); // Call the onSave function
    Navigator.pop(context); // Return to the previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Travel Emissions Calculator")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _distanceController,
              decoration: const InputDecoration(labelText: "Enter Distance (km)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _calculateEmissions,
              child: const Text("Calculate"),
            ),
            const SizedBox(height: 10),
            Text("Estimated Emissions: $_calculatedEmissions kg CO₂"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveEmissions, // Call the save function
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
