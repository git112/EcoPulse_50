import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class EmissionsGraphScreen extends StatefulWidget {
  final List<Map<String, dynamic>> currentDayCalculations;

  const EmissionsGraphScreen({super.key, required this.currentDayCalculations});

  @override
  _EmissionsGraphScreenState createState() => _EmissionsGraphScreenState();
}

class _EmissionsGraphScreenState extends State<EmissionsGraphScreen> {
  List<Map<String, dynamic>> _historicalEmissions = [];
  List<Map<String, dynamic>> _weeklyEmissions = [];
  Map<String, List<Map<String, dynamic>>> _otherUsersWeeklyEmissions = {};
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _loadHistoricalEmissions();
      await _loadWeeklyEmissions();
      await _loadOtherUsersWeeklyEmissions();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHistoricalEmissions() async {
    User? user = _auth.currentUser;
    if (user == null || user.email == null) {
      print("No user logged in or no email available");
      return;
    }

    String userEmail = user.email!.replaceAll('.', '_');
    print("Fetching historical emissions for user: $userEmail");
    QuerySnapshot emissionsSnapshot = await _firestore
        .collection('user_calculations')
        .doc(userEmail)
        .collection('daily_emissions')
        .orderBy('date', descending: true)
        .get();

    print("Found ${emissionsSnapshot.docs.length} historical emission records");
    List<Map<String, dynamic>> historicalEmissions = [];
    for (var doc in emissionsSnapshot.docs) {
      if (doc.exists) {
        print("Historical emission record: ${doc.data()}");
        historicalEmissions.add({
          'date': doc['date'],
          'totalEmissions': doc['totalEmissions']?.toDouble() ?? 0.0,
        });
      }
    }

    setState(() {
      _historicalEmissions = historicalEmissions;
    });
  }

  Future<void> _loadWeeklyEmissions() async {
    User? user = _auth.currentUser;
    if (user == null || user.email == null) {
      print("No user logged in or no email available");
      return;
    }

    String userEmail = user.email!.replaceAll('.', '_');
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: 6)); // Last 7 days
    String startDate = DateFormat('yyyy-MM-dd').format(startOfWeek);

    print("Fetching weekly emissions for user: $userEmail from $startDate");
    QuerySnapshot emissionsSnapshot = await _firestore
        .collection('user_calculations')
        .doc(userEmail)
        .collection('daily_emissions')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .orderBy('date')
        .get();

    print("Found ${emissionsSnapshot.docs.length} weekly emission records");
    List<Map<String, dynamic>> weeklyEmissions = [];
    for (var doc in emissionsSnapshot.docs) {
      if (doc.exists) {
        print("Weekly emission record: ${doc.data()}");
        weeklyEmissions.add({
          'date': doc['date'],
          'totalEmissions': doc['totalEmissions']?.toDouble() ?? 0.0,
        });
      }
    }

    setState(() {
      _weeklyEmissions = weeklyEmissions;
    });
  }

  Future<void> _loadOtherUsersWeeklyEmissions() async {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: 6)); // Last 7 days
    String startDate = DateFormat('yyyy-MM-dd').format(startOfWeek);

    QuerySnapshot usersSnapshot = await _firestore.collection('user_calculations').get();
    Map<String, List<Map<String, dynamic>>> otherUsersData = {};

    String? currentUserEmail = _auth.currentUser?.email?.replaceAll('.', '_');
    for (var userDoc in usersSnapshot.docs) {
      String userEmail = userDoc.id;
      if (userEmail == currentUserEmail) continue; // Skip current user

      QuerySnapshot emissionsSnapshot = await _firestore
          .collection('user_calculations')
          .doc(userEmail)
          .collection('daily_emissions')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .orderBy('date')
          .get();

      List<Map<String, dynamic>> weeklyEmissions = [];
      for (var doc in emissionsSnapshot.docs) {
        if (doc.exists) {
          weeklyEmissions.add({
            'date': doc['date'],
            'totalEmissions': doc['totalEmissions']?.toDouble() ?? 0.0,
          });
        }
      }

      if (weeklyEmissions.isNotEmpty) {
        otherUsersData[userEmail] = weeklyEmissions;
      }
    }

    setState(() {
      _otherUsersWeeklyEmissions = otherUsersData;
    });
  }

  Widget _buildCurrentDayGraph() {
    if (widget.currentDayCalculations.isEmpty) {
      return const Center(child: Text('No calculations for today.'));
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index % 5 == 0 && index < widget.currentDayCalculations.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Trip ${index + 1}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          barGroups: widget.currentDayCalculations.asMap().entries.map((entry) {
            int index = entry.key;
            double emission = entry.value['emissions'];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: emission,
                  color: Colors.blue,
                  width: 10,
                ),
              ],
              barsSpace: 4,
            );
          }).toList(),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }

  Widget _buildWeeklyGraph() {
    if (_weeklyEmissions.isEmpty) {
      return const Center(child: Text('No weekly data available.'));
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < _weeklyEmissions.length) {
                    String date = _weeklyEmissions[index]['date'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        date.substring(5), // Show only MM-DD
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _weeklyEmissions.asMap().entries.map((entry) {
                int index = entry.key;
                double emission = entry.value['totalEmissions'];
                return FlSpot(index.toDouble(), emission);
              }).toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
            ),
          ],
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }

  Widget _buildComparisonGraph() {
    if (_otherUsersWeeklyEmissions.isEmpty) {
      return const Center(child: Text('No data available for comparison.'));
    }

    // Calculate total weekly emissions for each user
    List<Map<String, dynamic>> userTotals = [];
    // Current user's total
    double currentUserTotal = _weeklyEmissions.fold(0.0, (sum, item) => sum + item['totalEmissions']);
    userTotals.add({'userId': 'You', 'totalEmissions': currentUserTotal});

    // Other users' totals
    _otherUsersWeeklyEmissions.forEach((userEmail, emissions) {
      double total = emissions.fold(0.0, (sum, item) => sum + item['totalEmissions']);
      userTotals.add({'userId': 'User ${userEmail.split('_')[0]}', 'totalEmissions': total});
    });

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < userTotals.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        userTotals[index]['userId'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          barGroups: userTotals.asMap().entries.map((entry) {
            int index = entry.key;
            double total = entry.value['totalEmissions'];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: total,
                  color: index == 0 ? Colors.blue : Colors.orange,
                  width: 10,
                ),
              ],
              barsSpace: 4,
            );
          }).toList(),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }

  Widget _buildHistoricalGraph() {
    if (_historicalEmissions.isEmpty) {
      return const Center(child: Text('No historical data available.'));
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < _historicalEmissions.length) {
                    String date = _historicalEmissions[index]['date'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        date.substring(5), // Show only MM-DD
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _historicalEmissions.asMap().entries.map((entry) {
                int index = entry.key;
                double emission = entry.value['totalEmissions'];
                return FlSpot(index.toDouble(), emission);
              }).toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
            ),
          ],
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emissions Graphs'),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Day Emissions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildCurrentDayGraph(),
                  const SizedBox(height: 20),
                  const Text(
                    'Weekly Emissions (Last 7 Days)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildWeeklyGraph(),
                  const SizedBox(height: 20),
                  const Text(
                    'Weekly Comparison with Other Users',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildComparisonGraph(),
                  const SizedBox(height: 20),
                  const Text(
                    'Historical Emissions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildHistoricalGraph(),
                ],
              ),
            ),
    );
  }
}