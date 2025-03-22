import 'package:flutter/material.dart';
import 'package:flutter_application_2/DashboardScreen.dart';
import 'package:flutter_application_2/UserDashboardScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_application_2/db.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please fill in all fields"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Passwords do not match"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "userId": user.uid,
          "userName": name,
          "userEmail": email,
          "createdAt": FieldValue.serverTimestamp(),
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserDashboardScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: ${e.toString()}"),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Google Sign-In Cancelled"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await _auth.signInWithCredential(credential);
    User? user = userCredential.user;

    if (user != null) {
      // Check if user exists in Firestore
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(user.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection("users").doc(user.uid).set({
          "userId": user.uid,
          "userName": user.displayName,
          "userEmail": user.email,
          "photoUrl": user.photoURL,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
      
      // Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Google Sign-In Failed: ${e.toString()}"),
      backgroundColor: Colors.red,
    ));
  }
}


  Widget buildRegistrationForm() {
    return Column(
      children: [
        buildInputField("Full Name", Icons.person, _nameController),
        buildInputField("Email", Icons.email, _emailController),
        buildInputField("Password", Icons.lock, _passwordController, isPassword: true),
        buildInputField("Confirm Password", Icons.lock, _confirmPasswordController, isPassword: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _registerUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text("REGISTER", style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ],
    );
  }

  Widget buildInputField(String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/background.jpg", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "ECOPLUSE",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildRegistrationForm(),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white),
                      label: const Text("Continue with Google", style: TextStyle(fontSize: 18, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
