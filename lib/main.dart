import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/DashboardScreen.dart';
import 'package:flutter_application_2/RegisterApp.dart';
import 'package:flutter_application_2/UserDashboardScreen.dart';
import 'package:flutter_application_2/create_event_screen.dart';
import 'package:flutter_application_2/individual_home.dart';
import 'package:flutter_application_2/splash_screen.dart';
import 'package:flutter_application_2/event.dart';
import 'LoginScreen.dart';
import 'package:flutter_application_2/individual_home.dart' as home;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
   await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ecopluse App',
home: UserDashboardScreen()


    );
  }
}
