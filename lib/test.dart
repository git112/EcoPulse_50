import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CarbonEmissionCalculatorPage extends StatefulWidget {
  @override
  _CarbonEmissionCalculatorPageState createState() =>
      _CarbonEmissionCalculatorPageState();
}

class _CarbonEmissionCalculatorPageState
    extends State<CarbonEmissionCalculatorPage> {
  final _distanceController = TextEditingController();
  final _ageController = TextEditingController();
  String _fuelType = 'Petrol';
  double _carbonEmissions = 0.0;
  String _aiSuggestion = 'Awaiting AI response...';

  // CO2 emission factors (kg CO2 per liter of fuel)
  Map<String, double> emissionFactors = {
    'Petrol': 2.31,
    'Diesel': 2.68,
    'CNG': 1.89,
  };

  // Calculate Carbon Emissions
  double calculateCarbonEmissions({
    required double distanceTraveled,
    required double fuelEfficiency,
    required String fuelType,
    required int carAge,
  }) {
    double carbonEmissionFactor = emissionFactors[fuelType] ?? 2.31;

    // Adjust efficiency based on car age (older cars = lower efficiency)
    double ageAdjustmentFactor = carAge > 10
        ? 0.85 // 15% less efficient if >10 years old
        : carAge > 5
            ? 0.9 // 10% less efficient if >5 years old
            : 1.0;

    double adjustedFuelEfficiency = fuelEfficiency * ageAdjustmentFactor;
    double fuelConsumed = distanceTraveled / adjustedFuelEfficiency;

    return fuelConsumed * carbonEmissionFactor;
  }

  // AI-based suggestion generation
  Future<void> fetchAISuggestion(double emissions, double distance, String fuelType) async {
    final String apiKey = 'your_openai_api_key';

    String prompt = '''
      A user traveled $distance km using a $fuelType car and emitted $emissions kg CO2.
      Suggest the best alternative transport options (bike, bus, train, EV, walking) 
      based on distance and emissions. Prioritize lowest emissions first.
      Provide 3 suggestions with estimated CO2 savings.
    ''';

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4",
          "prompt": prompt,
          "max_tokens": 150,
        }),
      );

      if (response.statusCode == 200) {
        String aiResponse = jsonDecode(response.body)['choices'][0]['text'].trim();
        if (aiResponse.isEmpty) {
          throw Exception("Empty AI response");
        }
        setState(() {
          _aiSuggestion = aiResponse;
        });
      } else {
        throw Exception("AI request failed");
      }
    } catch (e) {
      setState(() {
        _aiSuggestion = emissions > 50
            ? "Switch to public transport or carpooling.\nUse an electric or hybrid car for long trips.\nConsider biking for distances under 5 km."
            : "Use biking or walking if under 5 km.\nTake public transport if available.\nCombine multiple trips to reduce car usage.";
      });
    }
  }

  void _calculateEmissions() {
    final double distance = double.tryParse(_distanceController.text) ?? 0;
    final int carAge = int.tryParse(_ageController.text) ?? 0;
    double fuelEfficiency = _fuelType == 'Diesel'
        ? 15.0
        : _fuelType == 'CNG'
            ? 18.0
            : 12.0; // Default Petrol Efficiency

    double emissions = calculateCarbonEmissions(
      distanceTraveled: distance,
      fuelEfficiency: fuelEfficiency,
      fuelType: _fuelType,
      carAge: carAge,
    );

    setState(() {
      _carbonEmissions = emissions;
      _aiSuggestion = "Fetching AI suggestion...";
    });

    fetchAISuggestion(emissions, distance, _fuelType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carbon Emission Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ageController,
              decoration: InputDecoration(
                labelText: 'Car Age (in years)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _distanceController,
              decoration: InputDecoration(
                labelText: 'Distance Traveled (in km)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            DropdownButton<String>(
              value: _fuelType,
              onChanged: (String? newValue) {
                setState(() {
                  _fuelType = newValue!;
                });
              },
              items: <String>['Petrol', 'Diesel', 'CNG']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _calculateEmissions,
              child: Text('Calculate Emissions'),
            ),
            SizedBox(height: 32),
            if (_carbonEmissions > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Carbon Emissions: ${_carbonEmissions.toStringAsFixed(2)} kg CO₂',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'AI Suggestion:\n$_aiSuggestion',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
