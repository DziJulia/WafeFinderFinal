import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// A helper class for handling Facebook authentication.
class FacebookAuthHelper {
  static final FacebookAuth _facebookAuth = FacebookAuth.instance;

  static Future<AccessToken?> signInWithFacebook() async {
    final LoginResult result = await _facebookAuth.login();
    print(result);
    if (result.status == LoginStatus.success) {
      // The user is logged in
      final AccessToken accessToken = result.accessToken!;
      return accessToken;
    } else {
      // There was an error during the sign in process
      return null;
    }
  }

  /// Sign out from Facebook
  static Future<void> signOut() async {
    await _facebookAuth.logOut();
  }

  /// Fetches the email associated with the given Facebook access token.
  ///
  /// Sends a GET request to the Facebook Graph API, which returns the email of the user associated with the access token.
  ///
  /// @param accessToken The access token obtained from Facebook during user authentication.
  ///
  /// @return A Future that completes with the email as a string if the HTTP request is successful, or null if it fails.
  static Future<String?> getEmailFromAccessToken(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://graph.facebook.com/v13.0/me?fields=email&access_token=$accessToken'),
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      String email = jsonResponse['email'];
      print('Email: $email');
      return email;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }
  }
}
