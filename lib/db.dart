import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> registerUser({
    required String userName,
    required String userEmail,
    required String password,
  }) async {
    try {
      // Create a new user in Firebase Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: userEmail, password: password);

      // Store user details in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': userName,
        'email': userEmail,
        'uid': userCredential.user!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return "Success";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }
}
