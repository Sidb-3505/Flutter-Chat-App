import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:we_chat/helper/dialogs.dart';

/// A service class to handle Google Sign-In
/// and authentication using Firebase.
class GoogleAuthService {
  /// FirebaseAuth instance to handle authentication.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// GoogleSignIn instance to handle Google Sign-In.
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Signs in the user with Google and returns the authenticated Firebase [User].
  /// Returns `null` if the sign-in process is canceled or fails.
  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      ///Trigger the google signIn flow
      final googleUser = await _googleSignIn.signIn();

      ///User cancelled the signIn request
      if (googleUser == null) return null;

      ///grabbing the authentication details from google account
      final googleAuth = await googleUser.authentication;

      ///Create a new credential using the Google authentication details.
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      /// Sign in to Firebase with the Google credential.
      final _userCredential = await _auth.signInWithCredential(credential);

      /// Return the authenticated user
      return _userCredential.user;
    } catch (e) {
      Dialogs.showSnackBar(context, 'Something Went Wrong!!!');
      // Print the error and return null if an exception occurs.
      print("Sign-in error: $e");
      return null;
    }
  }

  ///sign out user from both google and firebase
  Future<void> signOut() async {
    ///sign out user from google
    await _googleSignIn.signOut();

    ///sign out user from firebase
    await _auth.signOut();
  }
}
