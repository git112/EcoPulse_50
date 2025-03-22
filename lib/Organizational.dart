import 'package:flutter/material.dart';



class OrganizationalEmissionsCalculator extends StatefulWidget {
  @override
  _OrganizationalEmissionsCalculatorState createState() =>
      _OrganizationalEmissionsCalculatorState();
}

class _OrganizationalEmissionsCalculatorState
    extends State<OrganizationalEmissionsCalculator> {
  // State variables for inputs (number of items)
  String _numLights = '';
  String _numACs = '';
  String _numPCs = '';
  String _numFans = ''; // Added for fans
  Map<String, double> _calculatedEmissions = {};
  String? _errorMessage;

  // Energy consumption per item per month
  final Map<String, double> energyPerItem = {
    'Lighting':
        1.5, // kWh per light (e.g., LED, 0.01 kWh/hour, 5 hours/day, 30 days)
    'HVAC Systems': 1000.0, // kWh per AC (typical for a large unit)
    'Lab Equipment': 48.0, // kWh per PC (0.2 kWh/hour, 8 hours/day, 30 days)
    'Fans': 15.0, // kWh per fan (0.05 kWh/hour, 10 hours/day, 30 days)
  };

  // Emission factors (kg CO2e per unit)
  final Map<String, double> emissionFactors = {
    'Lighting': 0.5, // kg CO2e/kWh (electricity)
    'HVAC Systems': 0.5, // kg CO2e/kWh (electricity)
    'Lab Equipment': 0.5, // kg CO2e/kWh (electricity)
    'Fans': 0.5, // kg CO2e/kWh (electricity)
  };

  // Grey emissions factor (25% for production and distribution)
  final double greyEmissionsFactor = 0.25;

  // Formula to calculate CO2 emissions for a category
  double calculateCategoryEmissions(String category, String numItemsStr) {
    double numItems = double.tryParse(numItemsStr) ?? 0.0;
    if (numItems <= 0) return 0.0;

    // Step 1: Calculate total energy consumption
    double totalEnergy = numItems * energyPerItem[category]!;

    // Step 2: Calculate direct emissions
    double directEmissions = totalEnergy * emissionFactors[category]!;

    // Step 3: Add grey emissions (25% of direct emissions)
    double totalEmissions = directEmissions * (1 + greyEmissionsFactor);

    return double.parse(totalEmissions.toStringAsFixed(2));
  }

  // Calculate emissions for all categories
  void calculateAllEmissions() {
    // Validate inputs
    if (_numLights.isEmpty ||
        _numACs.isEmpty ||
        _numPCs.isEmpty ||
        _numFans.isEmpty) {
      // Updated to include fans
      setState(() {
        _errorMessage = 'Please fill all fields.';
      });
      return;
    }

    double lights = double.tryParse(_numLights) ?? 0.0;
    double acs = double.tryParse(_numACs) ?? 0.0;
    double pcs = double.tryParse(_numPCs) ?? 0.0;
    double fans = double.tryParse(_numFans) ?? 0.0; // Added for fans

    if (lights <= 0 || acs <= 0 || pcs <= 0 || fans <= 0) {
      // Updated to include fans
      setState(() {
        _errorMessage = 'Please enter valid numbers of items.';
      });
      return;
    }

    setState(() {
      _calculatedEmissions = {
        'Lighting': calculateCategoryEmissions('Lighting', _numLights),
        'HVAC Systems': calculateCategoryEmissions('HVAC Systems', _numACs),
        'Lab Equipment': calculateCategoryEmissions('Lab Equipment', _numPCs),
        'Fans': calculateCategoryEmissions('Fans', _numFans), // Added for fans
      };
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Organizational Emissions Calculator',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Building Energy Consumption',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900]),
              ),
              SizedBox(height: 16),

              // Lighting Input (Number of Lights)
              Text('Number of Lights',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _numLights = value;
                    _calculatedEmissions = {};
                    _errorMessage = null;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter number of lights',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),

              Text('Number of Fans',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _numFans = value;
                    _calculatedEmissions = {};
                    _errorMessage = null;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter number of fans',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),

              // HVAC Systems Input (Number of ACs)
              Text('Number of ACs (HVAC)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _numACs = value;
                    _calculatedEmissions = {};
                    _errorMessage = null;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter number of ACs',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),

              // Lab Equipment Input (Number of PCs)
              Text('Number of PCs (Lab Equipment)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _numPCs = value;
                    _calculatedEmissions = {};
                    _errorMessage = null;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter number of PCs',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),

              // Fans Input (Number of Fans)

              // Error Message (if any)
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              // Calculate Emissions Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: calculateAllEmissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Calculate Emissions',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Display Calculated Emissions
              if (_calculatedEmissions.isNotEmpty) ...[
                Text(
                  'CO2 Emissions',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900]),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Lighting
                    Column(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.green, size: 40),
                        Text(
                          '${_calculatedEmissions['Lighting']} kg',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text('Lighting'),
                      ],
                    ),
                    // HVAC Systems
                    Column(
                      children: [
                        Icon(Icons.ac_unit, color: Colors.green, size: 40),
                        Text(
                          '${_calculatedEmissions['HVAC Systems']} kg',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text('HVAC Systems'),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Lab Equipment
                    Column(
                      children: [
                        Icon(Icons.computer, color: Colors.green, size: 40),
                        Text(
                          '${_calculatedEmissions['Lab Equipment']} kg',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text('Lab Equipment'),
                      ],
                    ),
                    // Fans
                    Column(
                      children: [
                        Icon(Icons.air,
                            color: Colors.green, size: 40), // Icon for fans
                        Text(
                          '${_calculatedEmissions['Fans']} kg',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text('Fans'),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Total Emissions
                Text(
                  'Total CO2 Emissions: ${_calculatedEmissions.values.reduce((a, b) => a + b)} kg',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}