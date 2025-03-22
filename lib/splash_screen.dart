import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/DashboardScreen.dart';
import 'package:flutter_application_2/LoginScreen.dart';
import 'package:flutter_application_2/UserDashboardScreen.dart'; // Make sure you have this screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Check authentication status
    Future.delayed(const Duration(seconds: 3), _checkUserLogin);
  }

  void _checkUserLogin() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UserDashboardScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20), // Dark Green
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            
            // Fade-in Welcome Text
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                "WELCOME",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Scale animation for the icon
            ScaleTransition(
              scale: _fadeAnimation,
              child: const Icon(
                Icons.eco,
                color: Color(0xFFB0E57C), // Bright Yellow-Green
                size: 60,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Fade-in ECOPULSE text
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                "ECOPULSE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Animated Slogan
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  "Cut the carbon and save Tomorrow",
                  style: TextStyle(
                    color: Color(0xFFA5D6A7), // Softer Green
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            
            const Spacer(flex: 2),
            
            // Animated dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder(
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  tween: Tween<double>(begin: 0.5, end: 1.0),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.8), // Bright Green
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
