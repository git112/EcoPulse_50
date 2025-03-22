import 'package:flutter/material.dart';
import 'package:flutter_application_2/DashboardScreen.dart';
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
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  String _verificationId = "";
  bool _isPhoneVerified = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactNumberController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Register Screen"), // Placeholder UI
      ),
    );
  }

  Future<void> _verifyPhoneNumber() async {
    String contactNumber = _contactNumberController.text.trim();
    if (contactNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please enter your contact number"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: contactNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        setState(() => _isPhoneVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Phone number verified automatically"),
          backgroundColor: Colors.green,
        ));
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Verification Failed: ${e.message}"),
          backgroundColor: Colors.red,
        ));
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("OTP sent to your phone number"),
          backgroundColor: Colors.green,
        ));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOTP() async {
    try {
      String otp = _otpController.text.trim();
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      setState(() => _isPhoneVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Phone number verified successfully"),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("OTP Verification Failed: ${e.toString()}"),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _registerUser() async {
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please verify your phone number first"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String contactNumber = _contactNumberController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || contactNumber.isEmpty) {
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
          "contactNumber": contactNumber,
          "createdAt": FieldValue.serverTimestamp(),
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: ${e.toString()}"),
        backgroundColor: Colors.red,
      ));
    }
  }
}
