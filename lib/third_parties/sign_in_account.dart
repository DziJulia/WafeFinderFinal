import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wavefinder/components/dialogs/boolean_dialog.dart';
import 'package:wavefinder/components/dialogs/dialog.dart';
import 'package:wavefinder/config/backround_service_db.dart';
import 'package:wavefinder/config/database_helper.dart';
import 'package:wavefinder/config/user.dart';
import 'package:wavefinder/config/user_session.dart';

/// Represents a user account from a third-party sign-in method.
///
/// This class is used to abstract the details of a user account
/// from a third-party sign-in method such as Google or Facebook.
/// It contains the email of the user.
///a
/// The [email] field represents the email of the user account.
/// It can be null if the sign-in method does not provide an email.
class SignInAccount {
  final String? email;

  SignInAccount({this.email});


  /// Shows an error dialog when a sign-in attempt fails.
  ///
  /// This method takes a [BuildContext] and a [String] as parameters. The [BuildContext] is used to show the dialog.
  /// The [String] parameter represents the name of the provider that failed to sign in.
  ///
  /// The dialog shows a message indicating that the sign-in attempt with the specified provider has failed and suggests the user to try again.
  ///
  /// The dialog has an 'OK' button that, when pressed, pops the dialog off the navigation stack.
  ///
  /// Usage:
  ///
  /// ```dart
  /// showErrorDialog(context, 'Google');
  /// ```
  void showErrorDialog(BuildContext context, String provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DialogPop(
          errorMessage: '$provider Sign-In failed. Please try again.',
          title: 'Sign-In Error',
        );
      },
    );
  }

  /// Inserts a new third-party user into the database and navigates to the dashboard screen.
  ///
  /// This method creates a new [User] instance with the provided email and inserts it into the database using [DBHelper]. 
  /// After the user is inserted, it completes a [Completer] and navigates to the dashboard screen if the widget is still mounted.
  ///
  /// @param email The email of the new user.
  /// @param context The build context from where the method is called.
  /// @param state The state object of the widget from where the method is called.
  /// @return A [Future] that completes when the user insertion and navigation process is finished.
  Future<void> insertThirdPartyUserAndNavigate(bool insert, String email, BuildContext context, State state) async {
    if(insert){
    User newUser = User(
        userEmail: email,
        password: '',
        userPreferences: '',
        createdAt: DateTime.now(),
        isThirdParty: true,
      );

      await DBHelper().insertUser(newUser);
      MailerIsolate mailerIsolate = MailerIsolate();
      mailerIsolate.start('WelcomeMailer', email);
    }

    Provider.of<UserSession>(context, listen: false).updateUserEmail(email);
    Completer<void> completer = Completer();
    completer.future.then((_) {
      if (state.mounted) {
        Navigator.pushNamed(context, '/DashboardScreen');
      }
    });
    completer.complete();
  }


  /// Handles the sign-in process for a user account from a third-party sign-in method.
  ///
  /// This method takes in a [SignInAccount] object.
  /// It checks if the user already exists in the database. If the user does not exist, it creates a new user.
  /// If the user does exist but was not created through a third-party sign-in, it shows an error dialog.
  /// After the user is successfully signed in, it navigates to the DashboardScreen.
  ///
  /// The [account] parameter is the user's account information from the third-party sign-in.
  ///
  /// This method returns a [Future] that completes when the sign-in process is finished.
  ///
  /// ```dart
  /// Future<void> handleSignIn(SignInAccount account, BuildContext context, State state) async {
  ///   // ... rest of your code ...
  /// }
  /// ```
  ///
  /// Remember to replace `signInAccount` and `account` with your actual instances.
  Future<bool> handleSignIn(User? existingUser, String email, BuildContext context) async {
    if (existingUser != null){
      if(existingUser.deletedAt != null) {
        // The user is soft-deleted. Ask if they want to recover their account.
        bool recoverAccount = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return const BooleanDialogPop(
              errorMessage:'This account has been deleted. Would you like to recover it?',
              title: 'Account Recovery'
            );
          },
        );
        if (recoverAccount) {
          await DBHelper().recoverUser(email);
          return true;
        } else{
            // Display error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account has not been recovered.'))
          );
          return false;
        }
      } else if (!existingUser.isThirdParty) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return const DialogPop(
              errorMessage: 'This account was created with an email and password. Please sign in with your email and password.',
              title: 'Sign-In Error',
            );
          }
        );
        return false;
      }
    }
    return true;
  }
}