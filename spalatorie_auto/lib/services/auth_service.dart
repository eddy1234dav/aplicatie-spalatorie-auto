import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {

  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance.collection('utilizatori').doc(user.uid);
        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          await userDoc.set({
            'uid': user.uid,
            'nume': user.displayName ?? '',
            'email': user.email ?? '',
            'data_inregistrare': Timestamp.now(),
            'jetoane': 0,
          });
        }
      }

      return user;
    } catch (e) {
      print("Eroare Google Sign-In: $e");
      return null;
    }
  }


  static Future<User?> registerWithEmail(String email, String password, String name) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();

        await FirebaseFirestore.instance.collection('utilizatori').doc(user.uid).set({
          'uid': user.uid,
          'nume': name,
          'email': email,
          'data_inregistrare': Timestamp.now(),
          'jetoane': 0,
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Eroare la înregistrare: ${e.code}');
      return null;
    }
  }



  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}


  }
}
