import 'package:flutter/material.dart';



class EnergyUsageCalculator extends StatefulWidget {
  const EnergyUsageCalculator({super.key});

  @override
  State<EnergyUsageCalculator> createState() => _EnergyUsageCalculatorState();
}

class _EnergyUsageCalculatorState extends State<EnergyUsageCalculator> {
  String selectedCategory = 'Appliances'; // Default category
  String? selectedSubOption; // For HVAC or Appliances
  double duration = 5.0; // Default duration
  String energyType = 'Electricity'; // Default energy type
  String result = '';

  // Power consumption in kW for appliances (average values)
  final Map<String, double> appliancePower = {
    'Water Heater': 4.0, // 4000W = 4kW
    'Refrigerator': 0.15, // 150W = 0.15kW
    'Washing Machine': 0.5, // 500W = 0.5kW
    'Oven': 2.4, // 2400W = 2.4kW
    'TV': 0.1, // 100W = 0.1kW
    'AC': 1.5, // 1500W = 1.5kW
    'Fan': 0.075, // 75W = 0.075kW
    'Heating': 2.0, // 2000W = 2kW
    'Lighting': 0.06, // 60W = 0.06kW (for a typical LED bulb)
  };

  void calculateEnergy() {
    if (selectedSubOption == null) {
      setState(() {
        result = 'Please select an option.';
      });
      return;
    }

    double power = appliancePower[selectedSubOption] ?? 0.0;
    double energy = power * duration; // Energy in kWh

    setState(() {
      result = 'Energy Usage: ${energy.toStringAsFixed(2)} kWh';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Usage Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = 'HVAC';
                        selectedSubOption = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCategory == 'HVAC'
                          ? Colors.black
                          : Colors.grey[300],
                      foregroundColor: selectedCategory == 'HVAC'
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: const Text('HVAC'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = 'Lighting';
                        selectedSubOption = 'Lighting';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCategory == 'Lighting'
                          ? Colors.black
                          : Colors.grey[300],
                      foregroundColor: selectedCategory == 'Lighting'
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: const Text('Lighting'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = 'Appliances';
                        selectedSubOption = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCategory == 'Appliances'
                          ? Colors.black
                          : Colors.grey[300],
                      foregroundColor: selectedCategory == 'Appliances'
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: const Text('Appliances'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sub-options based on category
              if (selectedCategory == 'HVAC') ...[
                const Text('Select HVAC Option:'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedSubOption = 'AC';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedSubOption == 'AC'
                            ? Colors.black
                            : Colors.grey[300],
                        foregroundColor: selectedSubOption == 'AC'
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: const Text('AC'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedSubOption = 'Fan';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedSubOption == 'Fan'
                            ? Colors.black
                            : Colors.grey[300],
                        foregroundColor: selectedSubOption == 'Fan'
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: const Text('Fan'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedSubOption = 'Heating';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedSubOption == 'Heating'
                            ? Colors.black
                            : Colors.grey[300],
                        foregroundColor: selectedSubOption == 'Heating'
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: const Text('Heating'),
                    ),
                  ],
                ),
              ] else if (selectedCategory == 'Appliances') ...[
                const Text('Select Appliance:'),
                Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedSubOption = 'Water Heater';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedSubOption == 'Water Heater'
                            ? Colors.black
                            : Colors.grey[300],
                        foregroundColor: selectedSubOption == 'Water Heater'
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: const Text('Water Heater'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedSubOption = 'Refrigerator';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedSubOption == 'Refrigerator'
                            ? Colors.black
                            : Colors.grey[300],
                        foregroundColor: selectedSubOption == 'Refrigerator'
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: const Text('Refrigerator'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedSubOption = 'Washing Machine';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedSubOption == 'Washing Machine'
                            ? Colors.black
                            : Colors.grey[300],
                        foregroundColor: selectedSubOption == 'Washing Machine'
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: const Text('Washing Machine'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedSubOption = 'Oven';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedSubOption == 'Oven'
                            ? Colors.black
                            : Colors.grey[300],
                        foregroundColor: selectedSubOption == 'Oven'
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: const Text('Oven'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedSubOption = 'TV';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedSubOption == 'TV'
                            ? Colors.black
                            : Colors.grey[300],
                        foregroundColor: selectedSubOption == 'TV'
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: const Text('TV'),
                    ),
                  ],
                ),
              ] else if (selectedCategory == 'Lighting') ...[
                const Text('Lighting selected.'),
              ],
              const SizedBox(height: 20),

              // Duration Input
              const Text('Duration (hours):'),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter duration in hours',
                ),
                onChanged: (value) {
                  setState(() {
                    duration = double.tryParse(value) ?? 5.0;
                  });
                },
                controller: TextEditingController(text: duration.toString()),
              ),
              const SizedBox(height: 20),

              // Calculate Button
              Center(
                child: ElevatedButton(
                  onPressed: calculateEnergy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Calculate'),
                ),
              ),
              const SizedBox(height: 20),

              // Result
              if (result.isNotEmpty)
                Text(
                  result,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}