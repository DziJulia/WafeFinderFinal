import 'package:flutter/material.dart';

/// [UserSession] is a [ChangeNotifier] that holds the state of the user session.
/// 
/// It stores the email of the logged-in user and notifies its listeners when the user email is updated.
class UserSession extends ChangeNotifier {
  String? _userEmail;

  /// Returns the email of the logged-in user.
  /// 
  /// Returns `null` if no user is logged in.
  String? get userEmail => _userEmail;

  /// Updates the email of the logged-in user and notifies all the listeners.
  /// 
  /// [email] is the new email of the logged-in user.
  void updateUserEmail(String email) {
    _userEmail = email;
    notifyListeners();
  }
}
