import 'package:flutter/material.dart';
import 'package:flutter_application_2/EmissionsGraphScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class TravelEmissions_Calculator extends StatefulWidget {
  const TravelEmissions_Calculator({super.key});

  @override
  _TravelEmissions_CalculatorState createState() =>
      _TravelEmissions_CalculatorState();
}

class _TravelEmissions_CalculatorState extends State<TravelEmissions_Calculator> {
  String? _travelType;
  String? _vehicleType;
  String? _fuelType;
  String? _unit = 'Kilometers (km)';
  String _distance = '';
  double? _calculatedEmissions;
  String? _errorMessage;

  List<Map<String, dynamic>> _calculations = [];
  double _totalEmissions = 0.0;
  double _totalHistoricalEmissions = 0.0;

  String _target = '';
  int _points = 0;
  String _rewardMessage = '';
  bool _isTargetAchieved = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> travelTypes = ['Private Transport', 'Public Transport'];
  final Map<String, List<String>> vehicleTypes = {
    'Private Transport': ['Car', 'Bike', 'Bicycle'],
    'Public Transport': ['Taxi', 'Train', 'Bus', 'Thane'],
  };
  final Map<String, List<Map<String, dynamic>>> fuelTypes = {
    'Car': [
      {'name': 'Petrol (Factor: 2.31 kg CO2e)', 'factor': 2.31},
      {'name': 'Diesel (Factor: 2.68 kg CO2e)', 'factor': 2.68},
      {'name': 'CNG (Factor: 2.8 kg CO2e)', 'factor': 2.8},
      {'name': 'Electric (Factor: 0.5 kg CO2e/kWh)', 'factor': 0.5},
    ],
    'Bike': [
      {'name': 'Petrol (Factor: 2.31 kg CO2e)', 'factor': 2.31},
      {'name': 'Electric (Factor: 0.5 kg CO2e/kWh)', 'factor': 0.5},
    ],
    'Bicycle': [
      {'name': 'None (Factor: 0 kg CO2e)', 'factor': 0.0},
    ],
    'Taxi': [
      {'name': 'Petrol (Factor: 2.31 kg CO2e)', 'factor': 2.31},
      {'name': 'Diesel (Factor: 2.68 kg CO2e)', 'factor': 2.68},
      {'name': 'CNG (Factor: 2.8 kg CO2e)', 'factor': 2.8},
    ],
    'Train': [
      {'name': 'Electric (Factor: 0.5 kg CO2e/kWh)', 'factor': 0.5},
      {'name': 'Diesel (Factor: 2.68 kg CO2e)', 'factor': 2.68},
    ],
    'Bus': [
      {'name': 'Petrol (Factor: 2.31 kg CO2e)', 'factor': 2.31},
      {'name': 'Diesel (Factor: 2.68 kg CO2e)', 'factor': 2.68},
      {'name': 'CNG (Factor: 2.8 kg CO2e)', 'factor': 2.8},
    ],
    'Thane': [
      {'name': 'Petrol (Factor: 2.31 kg CO2e)', 'factor': 2.31},
      {'name': 'Diesel (Factor: 2.68 kg CO2e)', 'factor': 2.68},
    ],
  };

  final Map<String, Map<String, double>> emissionsPerKm = {
    'Car': {
      'Petrol (Factor: 2.31 kg CO2e)': 0.162,
      'Diesel (Factor: 2.68 kg CO2e)': 0.188,
      'CNG (Factor: 2.8 kg CO2e)': 0.140,
      'Electric (Factor: 0.5 kg CO2e/kWh)': 0.100,
    },
    'Bike': {
      'Petrol (Factor: 2.31 kg CO2e)': 0.069,
      'Electric (Factor: 0.5 kg CO2e/kWh)': 0.050,
    },
    'Bicycle': {'None (Factor: 0 kg CO2e)': 0.0},
    'Taxi': {
      'Petrol (Factor: 2.31 kg CO2e)': 0.092,
      'Diesel (Factor: 2.68 kg CO2e)': 0.107,
      'CNG (Factor: 2.8 kg CO2e)': 0.112,
    },
    'Train': {
      'Electric (Factor: 0.5 kg CO2e/kWh)': 0.025,
      'Diesel (Factor: 2.68 kg CO2e)': 0.013,
    },
    'Bus': {
      'Petrol (Factor: 2.31 kg CO2e)': 0.012,
      'Diesel (Factor: 2.68 kg CO2e)': 0.013,
      'CNG (Factor: 2.8 kg CO2e)': 0.011,
    },
    'Thane': {
      'Petrol (Factor: 2.31 kg CO2e)': 0.039,
      'Diesel (Factor: 2.68 kg CO2e)': 0.045,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadCalculations();
    _loadTarget();
    _loadPoints();
    _scheduleFirebaseUpload();
    _updateRewardStatus();
    _loadTotalHistoricalEmissions(); // Load total historical emissions from Firebase
  }

  Future<void> _loadCalculations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? calculationsJson = prefs.getString('calculations');
    if (calculationsJson != null) {
      List<dynamic> decoded = jsonDecode(calculationsJson);
      setState(() {
        _calculations = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        _totalEmissions = _calculations.fold(0.0, (sum, item) => sum + (item['emissions'] as double));
      });
      _updateRewardStatus();
    }
  }

  Future<void> _loadTotalHistoricalEmissions() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc['totalHistoricalEmissions'] != null) {
      setState(() {
        _totalHistoricalEmissions = userDoc['totalHistoricalEmissions'].toDouble();
      });
    }
  }

  Future<void> _loadTarget() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _target = prefs.getString('target') ?? '100';
    });
    _updateRewardStatus();
  }

  Future<void> _saveTarget() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('target', _target);
    _updateRewardStatus();
  }

  Future<void> _loadPoints() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _points = prefs.getInt('points') ?? 0;
    });
  }

  Future<void> _savePoints() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('points', _points);
  }

  Future<void> _saveCalculations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String calculationsJson = jsonEncode(_calculations);
    await prefs.setString('calculations', calculationsJson);
  }

  void _updateRewardStatus() {
    double target = double.tryParse(_target) ?? 0.0;
    if (target <= 0) {
      setState(() {
        _isTargetAchieved = false;
        _rewardMessage = 'Please set a valid target.';
      });
      return;
    }

    setState(() {
      _isTargetAchieved = _totalHistoricalEmissions <= target;
      if (_isTargetAchieved) {
        _rewardMessage =
            '🎉 Great job! Your total historical emissions ($_totalHistoricalEmissions kg CO2e) are under your target of $target kg CO2e!';
      } else {
        _rewardMessage =
            '⚠️ Your total historical emissions ($_totalHistoricalEmissions kg CO2e) exceed your target of $target kg CO2e. Try using more eco-friendly transport options!';
      }
    });
  }

  void _scheduleFirebaseUpload() {
    DateTime now = DateTime.now();
    DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0);
    Duration timeUntilMidnight = nextMidnight.difference(now);

    Future.delayed(timeUntilMidnight, () async {
      if (_totalEmissions > 0) {
        await _uploadToFirebase();
        setState(() {
          _calculations.clear();
          _totalEmissions = 0.0;
        });
        await _saveCalculations();
      }
      _scheduleFirebaseUpload();
    });
  }

  Future<void> _uploadToFirebase() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      // Upload daily emissions
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emissions')
          .doc(date)
          .set({
        'totalEmissions': _totalEmissions,
        'date': date,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update total historical emissions
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      double currentTotal = userDoc.exists && userDoc['totalHistoricalEmissions'] != null
          ? userDoc['totalHistoricalEmissions'].toDouble()
          : 0.0;
      double newTotal = currentTotal + _totalEmissions;
      await _firestore.collection('users').doc(user.uid).set({
        'totalHistoricalEmissions': newTotal,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _totalHistoricalEmissions = newTotal;
      });
    } catch (e) {
      print("Error uploading to Firebase: $e");
    }
  }

  double calculateEmissions() {
    if (_travelType == null ||
        _vehicleType == null ||
        _fuelType == null ||
        _distance.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill all fields.';
      });
      return 0.0;
    }

    double distance = double.tryParse(_distance) ?? 0.0;
    if (distance <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid distance.';
      });
      return 0.0;
    }

    double target = double.tryParse(_target) ?? 0.0;
    if (target <= 0) {
      setState(() {
        _errorMessage = 'Please set a valid target.';
      });
      return 0.0;
    }

    if (_unit == 'Miles') {
      distance = distance * 1.60934;
    }

    double emissionFactorPerKm =
        emissionsPerKm[_vehicleType!]![_fuelType!] ?? 0.0;
    double directEmissions = distance * emissionFactorPerKm;
    double totalEmissions = directEmissions * 1.25;

    totalEmissions = double.parse(totalEmissions.toStringAsFixed(2));

    setState(() {
      _errorMessage = null;
      _calculatedEmissions = totalEmissions;
      _calculations.add({
        'travelType': _travelType,
        'vehicleType': _vehicleType,
        'fuelType': _fuelType,
        'distance': distance,
        'unit': _unit,
        'emissions': totalEmissions,
        'timestamp': DateTime.now().toString(),
      });
      _totalEmissions += totalEmissions;
      _totalHistoricalEmissions += totalEmissions;

      _isTargetAchieved = _totalHistoricalEmissions <= target;

      if (_isTargetAchieved) {
        _points += 1;
        _rewardMessage =
            '🎉 Great job! Your total historical emissions ($_totalHistoricalEmissions kg CO2e) are under your target of $target kg CO2e! You earned 1 point.';
      } else {
        _points -= 1;
        if (_points < 0) _points = 0;
        _rewardMessage =
            '⚠️ Your total historical emissions ($_totalHistoricalEmissions kg CO2e) exceed your target of $target kg CO2e. 1 point was deducted.';
      }

      _savePoints();
      _saveCalculations();
      _saveTarget();
    });

    return totalEmissions;
  }

  Widget _buildStars(int points) {
    int starsToShow = points > 5 ? 5 : points;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < starsToShow) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.grey, size: 20);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    double target = double.tryParse(_target) ?? 0.0;
    double progress = target > 0 ? (_totalHistoricalEmissions / target).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Emissions Calculator'),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Your Total Historical CO2 Target (kg CO2e)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _target = value;
                    _errorMessage = null;
                    _saveTarget();
                    _updateRewardStatus();
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter target (default: 100 kg CO2e)',
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: _target),
              ),
              const SizedBox(height: 16),

              const Text(
                'Total Historical Emissions Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress < 1.0 ? Colors.green : Colors.red,
                ),
                minHeight: 10,
              ),
              const SizedBox(height: 8),
              Text(
                'Total Historical Emissions: ${_totalHistoricalEmissions.toStringAsFixed(2)} kg CO2e / Target: ${target.toStringAsFixed(2)} kg CO2e',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Reward Points: $_points ',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  _buildStars(_points),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Travel Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _travelType,
                hint: const Text('Select Travel Type'),
                onChanged: (value) {
                  setState(() {
                    _travelType = value;
                    _vehicleType = null;
                    _fuelType = null;
                    _calculatedEmissions = null;
                    _errorMessage = null;
                  });
                },
                items: travelTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              const Text(
                'Vehicle Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _vehicleType,
                hint: const Text('Select Vehicle'),
                onChanged: (_travelType != null)
                    ? (value) {
                        setState(() {
                          _vehicleType = value;
                          _fuelType = null;
                          _calculatedEmissions = null;
                          _errorMessage = null;
                        });
                      }
                    : null,
                items: (_travelType != null)
                    ? vehicleTypes[_travelType!]!.map((vehicle) {
                        return DropdownMenuItem<String>(
                          value: vehicle,
                          child: Text(vehicle),
                        );
                      }).toList()
                    : [],
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              const Text(
                'Fuel Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _fuelType,
                hint: const Text('Select Fuel Type'),
                onChanged: (_vehicleType != null)
                    ? (value) {
                        setState(() {
                          _fuelType = value;
                          _calculatedEmissions = null;
                          _errorMessage = null;
                        });
                      }
                    : null,
                items: (_vehicleType != null)
                    ? fuelTypes[_vehicleType!]!.map((fuel) {
                        return DropdownMenuItem<String>(
                          value: fuel['name'],
                          child: Text(fuel['name']),
                        );
                      }).toList()
                    : [],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Fuel Type',
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _unit,
                onChanged: (value) {
                  setState(() {
                    _unit = value;
                    _calculatedEmissions = null;
                    _errorMessage = null;
                  });
                },
                items: ['Kilometers (km)', 'Miles'].map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Unit',
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                onChanged: (value) {
                  setState(() {
                    _distance = value;
                    _calculatedEmissions = null;
                    _errorMessage = null;
                  });
                },
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Distance (${_unit == 'Miles' ? 'mi' : 'km'})',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _calculatedEmissions = calculateEmissions();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Calculate Emissions',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_calculatedEmissions != null)
                Text(
                  'Latest CO2 Emissions: ${_calculatedEmissions} kg CO2e',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),

              const SizedBox(height: 16),
              Text(
                'Total CO2 Emissions Today: ${_totalEmissions.toStringAsFixed(2)} kg CO2e',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    double target = double.tryParse(_target) ?? 0.0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RewardScreen(
                          isTargetAchieved: _isTargetAchieved,
                          totalHistoricalEmissions: _totalHistoricalEmissions,
                          target: target,
                          points: _points,
                          message: _rewardMessage,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  child: const Text(
                    'View Rewards',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmissionsGraphScreen(
                          currentDayCalculations: _calculations,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  child: const Text(
                    'View Emissions Graphs',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Calculation History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _calculations.isEmpty
                  ? const Text('No calculations yet.')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _calculations.length,
                      itemBuilder: (context, index) {
                        final calc = _calculations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            title: Text(
                              '${calc['travelType']} - ${calc['vehicleType']} (${calc['fuelType']})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Distance: ${calc['distance'].toStringAsFixed(2)} ${calc['unit'] == 'Miles' ? 'mi' : 'km'}\n'
                              'Emissions: ${calc['emissions']} kg CO2e\n'
                              'Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(calc['timestamp']))}',
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class RewardScreen extends StatelessWidget {
  final bool isTargetAchieved;
  final double totalHistoricalEmissions;
  final double target;
  final int points;
  final String message;

  const RewardScreen({
    super.key,
    required this.isTargetAchieved,
    required this.totalHistoricalEmissions,
    required this.target,
    required this.points,
    required this.message,
  });

  Widget _buildStars(int points) {
    int starsToShow = points > 5 ? 5 : points;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < starsToShow) {
          return const Icon(Icons.star, color: Colors.amber, size: 30);
        } else {
          return const Icon(Icons.star_border, color: Colors.grey, size: 30);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isTargetAchieved ? 'Reward Achieved!' : 'Target Not Achieved'),
        backgroundColor: isTargetAchieved ? Colors.green : Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isTargetAchieved ? Icons.star : Icons.warning,
                size: 100,
                color: isTargetAchieved ? Colors.amber : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                isTargetAchieved ? '🎉 Congratulations! 🎉' : '⚠️ Target Exceeded ⚠️',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isTargetAchieved ? Colors.green[800] : Colors.red[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 18,
                  color: isTargetAchieved ? Colors.green[800] : Colors.red[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total Points: $points ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isTargetAchieved ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                  _buildStars(points),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTargetAchieved ? Colors.green : Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                child: const Text(
                  'Back to Calculator',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}