import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    print("AUTH 1");

    try {
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn().signIn();

      print("AUTH 2");

      if (googleUser == null) {
        print("AUTH CANCEL");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print("AUTH 3");

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);

      print("AUTH 4");

      await FirestoreService().createUserIfNotExists();

      print("AUTH 5");

      return result;
    } catch (e, s) {
      print("AUTH ERROR: $e");
      print(s);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}