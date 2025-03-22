import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_application_2/LoginScreen.dart';
import 'package:flutter_application_2/individual_home.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/background.jpg", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "DASHBOARD",
                  style: TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                buildOptionCard(
                  icon: Icons.person,
                  title: "Individual",
                  description: "Track your personal carbon footprint",
                  iconColor: const Color.fromARGB(255, 255, 255, 255),
                ),
                const SizedBox(height: 20),
                buildOptionCard(
                  icon: Icons.apartment,
                  title: "Organization",
                  description: "Manage your company's environmental impact",
                  iconColor: const Color.fromARGB(255, 255, 255, 255),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    "Back to Home",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
  }) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.5),
            radius: 30,
            child: Icon(icon, color: iconColor, size: 35),
          ),
          const SizedBox(height: 30),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              color: Color.fromARGB(255, 248, 245, 245),
            ),
          ),
        ],
      ),
    );
  }
}
