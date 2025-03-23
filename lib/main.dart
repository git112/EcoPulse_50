import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/DashboardScreen.dart';
import 'package:flutter_application_2/RegisterApp.dart';
import 'package:flutter_application_2/UserDashboardScreen.dart';
import 'package:flutter_application_2/individual_home.dart';
import 'package:flutter_application_2/splash_screen.dart';
import 'LoginScreen.dart';


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
home: SplashScreen()


    );
  }
}



// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_2/DashboardScreen.dart';
// import 'package:flutter_application_2/RegisterApp.dart';
// import 'package:flutter_application_2/UserDashboardScreen.dart';
// import 'package:flutter_application_2/create_event_screen.dart';
// import 'package:flutter_application_2/individual_home.dart';
// import 'package:flutter_application_2/splash_screen.dart';
// import 'package:flutter_application_2/event.dart';
// import 'LoginScreen.dart';
// import 'package:flutter_application_2/individual_home.dart' as home;
// import 'chat_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(); // Initialize Firebase
//   await FirebaseAppCheck.instance.activate(
//     webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
//     androidProvider: AndroidProvider.debug,
//     appleProvider: AppleProvider.appAttest,
//   );
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Ecopluse App',
//       home: HomeScreen(), // Changed to include HomeScreen with chatbot
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   bool showChat = false;

//   void toggleChat() {
//     setState(() {
//       showChat = !showChat;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Center(child: Text("Welcome to Ecopluse App")),

//           // Chatbox Overlay
//           if (showChat)
//             Positioned(
//               bottom: 80,
//               right: 20,
//               left: 20,
//               height: 300,
//               child: Material(
//                 elevation: 5,
//                 borderRadius: BorderRadius.circular(15),
//                 child: ChatScreen(),
//               ),
//             ),

//           // Floating Chat Button
//           Positioned(
//             bottom: 20,
//             right: 20,
//             child: FloatingActionButton(
//               backgroundColor: Colors.green,
//               child: Icon(Icons.chat, color: Colors.white),
//               onPressed: toggleChat,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
