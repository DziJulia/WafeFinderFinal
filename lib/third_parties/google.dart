import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInHelper {
  late GoogleSignIn googleSignIn;

  /// Signs in the user with Google.
  ///
  /// @return A [Future] that completes with the [GoogleSignInAccount] when the user has successfully signed in.
  /// Returns `null` if there was an error during sign-in.
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      // Configure sign-in
      googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'https://www.googleapis.com/auth/contacts.readonly',
        ],
      );

      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      return googleSignInAccount;
    } catch (error) {
      print('Error signing in with Google: $error');
      return null;
    }
  }

  /// Builds a Google Sign-In button.
  ///
  /// @param onPressed The [VoidCallback] that is called when the button is pressed.
  /// @return A [Widget] that represents the Google Sign-In button.
  Widget buildGoogleSignInButton({required VoidCallback onPressed}) {
    return IconButton(
      onPressed: onPressed,
      icon: Image.asset('assets/google_logo.png', height: 60.0),
    );
  }
}
