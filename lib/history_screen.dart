import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _dailyEmissions = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyEmissions();
  }

  Future<void> _loadDailyEmissions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      User? user = _auth.currentUser;
      if (user == null) {
        print("No user logged in, cannot load emissions");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      QuerySnapshot emissionsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emissions')
          .orderBy('date', descending: true)
          .get();

      List<Map<String, dynamic>> dailyEmissions = [];
      for (var doc in emissionsSnapshot.docs) {
        if (doc.exists) {
          dailyEmissions.add({
            'date': doc['date'],
            'totalEmissions': doc['totalEmissions']?.toDouble() ?? 0.0,
          });
        }
      }

      setState(() {
        _dailyEmissions = dailyEmissions;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading daily emissions: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color.fromARGB(255, 5, 90, 21),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Total Emissions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _dailyEmissions.isEmpty
                      ? const Text('No daily emissions data available.')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _dailyEmissions.length,
                          itemBuilder: (context, index) {
                            final emission = _dailyEmissions[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(
                                  'Date: ${emission['date']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Total Emissions: ${emission['totalEmissions'].toStringAsFixed(2)} kg CO2e',
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}