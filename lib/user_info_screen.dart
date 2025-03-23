import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/LoginScreen.dart';
import 'package:flutter_application_2/history_screen.dart';
import 'package:flutter_application_2/leaderboard_screen.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _name = 'Guest';
  String _email = 'Not available';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });

      User? user = _auth.currentUser;
      if (user != null) {
        // Get email directly from Firebase Authentication
        _email = user.email ?? 'Not available';

        // Fetch additional user info (e.g., name) from Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('user_calculations') // Updated to user_calculations
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _name = userDoc.get('name') ?? 'Guest';
            _isLoading = false;
          });
        } else {
          print("User document does not exist in Firestore for UID: ${user.uid}");
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print("No user is currently logged in.");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user info: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add logout method
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // Navigate to LoginScreen after logout
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'User Information',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 5, 90, 21),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Profile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 5, 90, 21),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name: $_name',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Email: $_email',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HistoryScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 5, 90, 21),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text(
                            'History',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 5, 90, 21),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text(
                            'Leaderboard',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Add Logout Button
                        ElevatedButton(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, // Red color to indicate logout
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}