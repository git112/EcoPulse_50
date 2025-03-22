import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _topUsers = [];
  Map<String, File?> _userGraphs = {};
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchTopUsers();
  }

  Future<void> _fetchTopUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .orderBy('totalHistoricalEmissions', descending: false)
          .limit(5)
          .get();

      List<Map<String, dynamic>> topUsers = [];
      for (var doc in querySnapshot.docs) {
        if (doc.exists && doc.data() != null) {
          var data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('totalHistoricalEmissions')) {
            topUsers.add({
              'userId': doc.id,
              'name': data['name'] ?? 'Unknown',
              'totalEmissions': data['totalHistoricalEmissions']?.toDouble() ?? 0.0,
            });
          }
        }
      }

      Map<String, File?> userGraphs = {};
      for (var user in topUsers) {
        String userId = user['userId'];
        File? graphFile = await _getMostRecentWeeklyGraph(userId);
        userGraphs[userId] = graphFile;
      }

      setState(() {
        _topUsers = topUsers;
        _userGraphs = userGraphs;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching top users: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<File?> _getMostRecentWeeklyGraph(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = Directory(directory.path).listSync();

      List<File> weeklyGraphs = files
          .where((file) =>
              file is File &&
              file.path.endsWith('.png') &&
              file.path.contains('weekly_individual_${userId}_'))
          .map((file) => File(file.path))
          .toList();

      weeklyGraphs.sort((a, b) => b.path.compareTo(a.path));

      return weeklyGraphs.isNotEmpty ? weeklyGraphs.first : null;
    } catch (e) {
      print("Error loading weekly graph for user $userId: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard - Top 5 Users'),
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
          : _topUsers.isEmpty
              ? const Center(child: Text('No users found in the leaderboard.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _topUsers.length,
                  itemBuilder: (context, index) {
                    final user = _topUsers[index];
                    final userId = user['userId'];
                    final graphFile = _userGraphs[userId];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '#${index + 1} ',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    user['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${user['totalEmissions'].toStringAsFixed(2)} kg CO2e',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            graphFile != null
                                ? Image.file(
                                    graphFile,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Text('Error loading graph');
                                    },
                                  )
                                : const Text('No recent weekly graph available.'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}