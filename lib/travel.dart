import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

// Main screen
class TravelEmissions_Calculator extends StatefulWidget {
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
  double _totalHistoricalEmissions = 0.0; // Total emissions across all history

  // Reward system variables
  String _target = ''; // User's target for total historical emissions (kg CO2e)
  int _points = 0; // Reward points
  String _rewardMessage = ''; // Message to display reward status
  bool _isTargetAchieved = false; // Track if target is achieved

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScreenshotController _screenshotController = ScreenshotController();

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
    _scheduleWeeklyGraphGeneration();
    _updateRewardStatus();
  }

  Future<void> _loadCalculations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? calculationsJson = prefs.getString('calculations');
    if (calculationsJson != null) {
      List<dynamic> decoded = jsonDecode(calculationsJson);
      setState(() {
        _calculations = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        _totalEmissions = _calculations.fold(0.0, (sum, item) => sum + (item['emissions'] as double));
        _totalHistoricalEmissions = _totalEmissions;
      });
      print("Loaded calculations: $_calculations");
      _updateRewardStatus();
    } else {
      print("No calculations found in SharedPreferences");
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
        await _generateDailyGraphForUsers();
        setState(() {
          _calculations.clear();
          _totalEmissions = 0.0;
        });
        await _saveCalculations();
      }
      _scheduleFirebaseUpload();
    });
  }

  void _scheduleWeeklyGraphGeneration() {
    DateTime now = DateTime.now();
    int daysUntilSunday = (7 - now.weekday) % 7;
    if (daysUntilSunday == 0) daysUntilSunday = 7;
    DateTime nextSundayMidnight = DateTime(now.year, now.month, now.day + daysUntilSunday, 0, 0);
    Duration timeUntilSunday = nextSundayMidnight.difference(now);

    Future.delayed(timeUntilSunday, () async {
      await _generateWeeklyGraphForAllUsers();
      _scheduleWeeklyGraphGeneration();
    });
  }

  Future<void> _uploadToFirebase() async {
    User? user = _auth.currentUser;
    if (user == null) {
      print("No user logged in, cannot upload to Firebase");
      return;
    }

    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
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
      print("Successfully uploaded total emissions to Firebase: $_totalEmissions kg CO2e");
    } catch (e) {
      print("Error uploading to Firebase: $e");
    }
  }

  Future<void> _generateDailyGraphForUsers() async {
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
    List<Map<String, dynamic>> userEmissions = [];

    for (var userDoc in usersSnapshot.docs) {
      DocumentSnapshot emissionDoc = await _firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('emissions')
          .doc(date)
          .get();
      if (emissionDoc.exists) {
        userEmissions.add({
          'userId': userDoc.id,
          'totalEmissions': emissionDoc['totalEmissions'] ?? 0.0,
        });
      }
    }

    print("Generating daily graphs for ${userEmissions.length} users on $date");
    for (int i = 0; i < userEmissions.length; i += 5) {
      List<Map<String, dynamic>> group = userEmissions.skip(i).take(5).toList();
      if (group.isNotEmpty) {
        await generateGraphForGroup(group, date, 'daily_group${i ~/ 5 + 1}');
      }
    }
  }

  Future<void> _generateWeeklyGraphForAllUsers() async {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    List<DateTime> weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
    String weekLabel = DateFormat('yyyy-MM-dd').format(startOfWeek);

    QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
    Map<String, List<double>> weeklyData = {};
    Map<String, double> totalWeeklyEmissions = {};

    for (var userDoc in usersSnapshot.docs) {
      weeklyData[userDoc.id] = List.filled(7, 0.0);
      totalWeeklyEmissions[userDoc.id] = 0.0;
    }

    for (int i = 0; i < 7; i++) {
      String date = DateFormat('yyyy-MM-dd').format(weekDays[i]);
      for (var userDoc in usersSnapshot.docs) {
        DocumentSnapshot emissionDoc = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('emissions')
            .doc(date)
            .get();
        if (emissionDoc.exists) {
          double emission = (emissionDoc['totalEmissions'] ?? 0.0).toDouble();
          weeklyData[userDoc.id]![i] = emission;
          totalWeeklyEmissions[userDoc.id] = totalWeeklyEmissions[userDoc.id]! + emission;
        }
      }
    }

    print("Generating weekly graphs for week starting $weekLabel");
    await _generateOverallWeeklyGraph(weeklyData, weekLabel);
    for (var userId in weeklyData.keys) {
      await _generateIndividualWeeklyGraph(userId, weeklyData[userId]!, weekLabel);
    }
  }

  Future<void> generateGraphForGroup(List<Map<String, dynamic>> group, String date, String groupId) async {
    Widget graph = MediaQuery(
      data: const MediaQueryData(size: Size(400, 300)),
      child: Container(
        height: 300,
        width: 400,
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: BarChart(
          BarChartData(
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index < group.length) {
                      return Text('User ${index + 1}');
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            barGroups: group.asMap().entries.map((entry) {
              int index = entry.key;
              double emission = entry.value['totalEmissions'];
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: emission,
                    color: Colors.blue,
                    width: 16,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );

    await saveGraphAsImage(graph, 'daily${date}_$groupId.png');
  }

  Future<void> _generateOverallWeeklyGraph(Map<String, List<double>> weeklyData, String weekLabel) async {
    List<String> userIds = weeklyData.keys.toList();
    Widget graph = MediaQuery(
      data: const MediaQueryData(size: Size(400, 300)),
      child: Container(
        height: 300,
        width: 400,
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int day = value.toInt();
                    return Text('Day ${day + 1}');
                  },
                ),
              ),
            ),
            lineBarsData: userIds.asMap().entries.map((entry) {
              int index = entry.key;
              String userId = entry.value;
              return LineChartBarData(
                spots: weeklyData[userId]!.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value);
                }).toList(),
                isCurved: true,
                color: Colors.primaries[index % Colors.primaries.length],
                barWidth: 2,
              );
            }).toList(),
          ),
        ),
      ),
    );

    await saveGraphAsImage(graph, 'weekly_overall$weekLabel.png');
  }

  Future<void> _generateIndividualWeeklyGraph(String userId, List<double> emissions, String weekLabel) async {
    Widget graph = MediaQuery(
      data: const MediaQueryData(size: Size(400, 300)),
      child: Container(
        height: 300,
        width: 400,
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int day = value.toInt();
                    return Text('Day ${day + 1}');
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: emissions.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value);
                }).toList(),
                isCurved: true,
                color: Colors.blue,
                barWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );

    await saveGraphAsImage(graph, 'weekly_individual${userId}_$weekLabel.png');
  }

  Future<void> saveGraphAsImage(Widget graph, String fileName) async {
    try {
      print("Attempting to save graph: $fileName");
      final image = await _screenshotController.captureFromWidget(graph);
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(image);
      print('Graph successfully saved to $filePath');
    } catch (e) {
      print('Error saving graph: $e');
    }
  }

  Future<void> _generateGraphsForPastData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = Directory(directory.path).listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.png')) {
          await file.delete();
          print("Deleted old graph file: ${file.path}");
        }
      }
    } catch (e) {
      print("Error deleting old graph files: $e");
    }

    Map<String, List<Map<String, dynamic>>> groupedByDate = {};
    for (var calc in _calculations) {
      String date = calc['timestamp'].toString().split(' ')[0];
      if (!groupedByDate.containsKey(date)) {
        groupedByDate[date] = [];
      }
      groupedByDate[date]!.add(calc);
    }

    for (var date in groupedByDate.keys) {
      List<Map<String, dynamic>> userEmissions = [];
      double totalForDate = groupedByDate[date]!.fold(0.0, (sum, item) => sum + (item['emissions'] as double));
      userEmissions.add({
        'userId': 'local_user',
        'totalEmissions': totalForDate,
      });

      print("Generating past daily graph for $date with total emissions: $totalForDate");
      await generateGraphForGroup(userEmissions, date, 'daily_group_1');
    }

    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    String weekLabel = DateFormat('yyyy-MM-dd').format(startOfWeek);
    Map<String, List<double>> weeklyData = {'local_user': List.filled(7, 0.0)};
    Map<String, double> totalWeeklyEmissions = {'local_user': 0.0};

    for (int i = 0; i < 7; i++) {
      String date = DateFormat('yyyy-MM-dd').format(startOfWeek.add(Duration(days: i)));
      if (groupedByDate.containsKey(date)) {
        double dailyTotal = groupedByDate[date]!.fold(0.0, (sum, item) => sum + (item['emissions'] as double));
        weeklyData['local_user']![i] = dailyTotal;
        totalWeeklyEmissions['local_user'] = totalWeeklyEmissions['local_user']! + dailyTotal;
      }
    }

    print("Generating past weekly graph for week starting $weekLabel");
    await _generateOverallWeeklyGraph(weeklyData, weekLabel);
    await _generateIndividualWeeklyGraph('local_user', weeklyData['local_user']!, weekLabel);
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

      // Update target achievement status
      _isTargetAchieved = _totalHistoricalEmissions <= target;

      // Update points based on target achievement
      if (_isTargetAchieved) {
        _points += 1; // Increment points by 1 if target is achieved
        _rewardMessage =
            '🎉 Great job! Your total historical emissions ($_totalHistoricalEmissions kg CO2e) are under your target of $target kg CO2e! You earned 1 point.';
      } else {
        _points -= 1; // Decrement points by 1 if target is not achieved
        if (_points < 0) _points = 0; // Prevent negative points
        _rewardMessage =
            '⚠️ Your total historical emissions ($_totalHistoricalEmissions kg CO2e) exceed your target of $target kg CO2e. 1 point was deducted. Try using more eco-friendly transport options!';
      }

      _savePoints();
      _saveCalculations();
      _saveTarget();
    });

    return totalEmissions;
  }

  // Widget to display stars based on points
  Widget _buildStars(int points) {
    int starsToShow = points > 5 ? 5 : points; // Cap the display at 5 stars
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < starsToShow) {
          return Icon(Icons.star, color: Colors.amber, size: 20);
        } else {
          return Icon(Icons.star_border, color: Colors.grey, size: 20);
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
        title: Text('Travel Emissions Calculator'),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target Input for Total Historical Emissions
              Text(
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
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter target (default: 100 kg CO2e)',
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: _target),
              ),
              SizedBox(height: 16),

              // Progress Display for Total Historical Emissions
              Text(
                'Total Historical Emissions Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress < 1.0 ? Colors.green : Colors.red,
                ),
                minHeight: 10,
              ),
              SizedBox(height: 8),
              Text(
                'Total Historical Emissions: ${_totalHistoricalEmissions.toStringAsFixed(2)} kg CO2e / Target: ${target.toStringAsFixed(2)} kg CO2e',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Reward Points: $_points ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  _buildStars(_points),
                ],
              ),
              SizedBox(height: 16),

              Text(
                'Travel Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _travelType,
                hint: Text('Select Travel Type'),
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
                decoration: InputDecoration(border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),

              Text(
                'Vehicle Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _vehicleType,
                hint: Text('Select Vehicle'),
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
                decoration: InputDecoration(border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),

              Text(
                'Fuel Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _fuelType,
                hint: Text('Select Fuel Type'),
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
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Fuel Type',
                ),
              ),
              SizedBox(height: 16),

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
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Unit',
                ),
              ),
              SizedBox(height: 16),

              TextField(
                onChanged: (value) {
                  setState(() {
                    _distance = value;
                    _calculatedEmissions = null;
                    _errorMessage = null;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Distance (${_unit == 'Miles' ? 'mi' : 'km'})',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
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
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Calculate Emissions',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 16),

              if (_calculatedEmissions != null)
                Text(
                  'Latest CO2 Emissions: ${_calculatedEmissions} kg CO2e',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),

              SizedBox(height: 16),
              Text(
                'Total CO2 Emissions Today: ${_totalEmissions.toStringAsFixed(2)} kg CO2e',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),

              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GraphDisplayScreen(graphType: 'daily'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    ),
                    child: Text(
                      'View Daily Graphs',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GraphDisplayScreen(graphType: 'weekly'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    ),
                    child: Text(
                      'View Weekly Graphs',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await _generateGraphsForPastData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Graphs generated for past data')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    ),
                    child: Text(
                      'Generate Graphs for Past Data',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
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
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    ),
                    child: Text(
                      'View Rewards',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),
              Text(
                'Calculation History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _calculations.isEmpty
                  ? Text('No calculations yet.')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _calculations.length,
                      itemBuilder: (context, index) {
                        final calc = _calculations[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            title: Text(
                              '${calc['travelType']} - ${calc['vehicleType']} (${calc['fuelType']})',
                              style: TextStyle(fontWeight: FontWeight.bold),
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

// Reward Screen to display when target is achieved or not
class RewardScreen extends StatelessWidget {
  final bool isTargetAchieved;
  final double totalHistoricalEmissions;
  final double target;
  final int points;
  final String message;

  RewardScreen({
    required this.isTargetAchieved,
    required this.totalHistoricalEmissions,
    required this.target,
    required this.points,
    required this.message,
  });

  // Widget to display stars based on points
  Widget _buildStars(int points) {
    int starsToShow = points > 5 ? 5 : points; // Cap the display at 5 stars
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < starsToShow) {
          return Icon(Icons.star, color: Colors.amber, size: 30);
        } else {
          return Icon(Icons.star_border, color: Colors.grey, size: 30);
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
              SizedBox(height: 16),
              Text(
                isTargetAchieved ? '🎉 Congratulations! 🎉' : '⚠️ Target Exceeded ⚠️',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isTargetAchieved ? Colors.green[800] : Colors.red[800],
                ),
              ),
              SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 18,
                  color: isTargetAchieved ? Colors.green[800] : Colors.red[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
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
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTargetAchieved ? Colors.green : Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                child: Text(
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

class GraphDisplayScreen extends StatefulWidget {
  final String graphType;

  GraphDisplayScreen({required this.graphType});

  @override
  _GraphDisplayScreenState createState() => _GraphDisplayScreenState();
}

class _GraphDisplayScreenState extends State<GraphDisplayScreen> {
  List<File> _graphFiles = [];

  @override
  void initState() {
    super.initState();
    _loadGraphFiles();
  }

  Future<void> _loadGraphFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      print("Looking for graphs in directory: ${directory.path}");
      final files = Directory(directory.path).listSync();
      setState(() {
        _graphFiles = files
            .where((file) => file is File && file.path.endsWith('.png'))
            .where((file) => file.path.contains(widget.graphType))
            .map((file) {
              print("Found graph file: ${file.path}");
              return File(file.path);
            })
            .toList();
        _graphFiles.sort((a, b) => b.path.compareTo(a.path));
        print("Total ${widget.graphType} graphs found: ${_graphFiles.length}");
      });
    } catch (e) {
      print("Error loading graph files: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.graphType == 'daily' ? 'Daily' : 'Weekly'} Graphs'),
        backgroundColor: Colors.blue[900],
      ),
      body: _graphFiles.isEmpty
          ? Center(child: Text('No ${widget.graphType} graphs available. Try generating graphs for past data.'))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _graphFiles.length,
              itemBuilder: (context, index) {
                final file = _graphFiles[index];
                print("Loading image: ${file.path}, exists: ${file.existsSync()}");
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          file.path.split('/').last,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Image.file(
                        file,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print("Error loading image ${file.path}: $error");
                          return Text('Error loading graph: $error');
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}