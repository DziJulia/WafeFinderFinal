import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wavefinder/components/dialogs/dialog.dart';
import 'package:wavefinder/config/backround_service_db.dart';
import 'package:wavefinder/config/user_session.dart';
import 'package:wavefinder/theme/colors.dart';

/// This class is responsible for generating and validating tokens.
class TokenService {
  static final _tokens = <String, String>{};

  /// Generates a random token of 6 alphanumeric characters and associates it with the user's email.
  ///
  /// This method generates a random token by creating a string of 6 random alphanumeric characters.
  /// The generated token is associated with the user's email in a map, so that it can be retrieved later for validation.
  ///
  /// @param userEmail The email of the user for whom the token is generated. This email is used as a key to associate the token with the user.
  /// @return The generated token as a string. This token is a sequence of 6 random alphanumeric characters.
  static String generateToken(String userEmail) {
    const allowedChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final token = List.generate(6, (index) => allowedChars[random.nextInt(allowedChars.length)]).join();
    _tokens[userEmail] = token;
    return token;
  }

  /// Validates the token and navigates to a new screen if the token is valid.
  ///
  /// @param context The build context.
  /// @param userEmail The email of the user whose token is to be validated.
  /// @param userInputToken The token entered by the user.
  /// @return A Future that completes when the navigation is done.
  static Future<void> validateAndNavigate(BuildContext context, String userEmail, String userInputToken) async {
    if (_tokens[userEmail] == userInputToken) {
      Provider.of<UserSession>(context, listen: false).updateUserEmail(userEmail);
      Navigator.pushNamed(context, '/NewPassword');
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
        return const DialogPop(
            errorMessage: 'The token you entered is not correct. Please check your email and try again.',
            title: 'Invalid Token',
          );
        }
      );
    }
  }


  /// Starts a countdown timer that ticks every second and emits the remaining time as a string.
  ///
  /// This method creates a periodic timer that ticks every second. Each tick, it decreases the remaining
  /// time by one second and emits the remaining time as a string in the format "mm:ss". When the remaining
  /// time reaches zero, it cancels the timer, invalidates the token associated with the user's email, and
  /// closes the stream.
  ///
  /// @param setState A function that is called every second with the remaining time. This function should be
  /// defined in the widget that calls `startTimer` and it should call `setState` of that widget. This is
  /// necessary to update the UI of the widget when the remaining time changes.
  /// 
  /// @param userEmail The email of the user for whom the token is invalidated when the time is up.
  /// @return A stream that emits the remaining time as a string every second. The stream is closed when the remaining time reaches zero.
  Stream<String> startTimer(Function setState, String userEmail) { 
    int remainingTime = 120;
    StreamController<String> streamController = StreamController<String>();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime == 0) {
        timer.cancel();
        // Invalidate user token when timer runs out
        _tokens.remove(userEmail);
        streamController.close();
      } else {
        setState(() {
          remainingTime--;
        });
        int minutes = remainingTime ~/ 60;
        int seconds = remainingTime % 60;
        streamController.add('${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}');
      }
    });

    return streamController.stream;
  }

  /// Generates a token, sends it to the user's email, and starts a timer.
  ///
  /// @param userEmail The email of the user to whom the token is sent.
  /// @param setState A function that is called when the state changes.
  void sendToken(String userEmail, Function setState) async {
    try {
      var token = TokenService.generateToken(userEmail);
      
      MailerIsolate mailerIsolate = MailerIsolate();
      mailerIsolate.start('ResetPasswordMailer', userEmail, userToken: token);
      startTimer(setState, userEmail);
    } catch (e) {
      print('Failed to send token: $e');
    }
  }


  /// Displays a dialog for the user to enter a token.
  ///
  /// This method shows a dialog with a text field for the user to enter a token.
  /// The dialog also includes three buttons: "OK", "Cancel", and "Resend Token".
  ///
  /// The "OK" button validates the entered token by calling the `validateAndNavigate` method of the `TokenService` class.
  /// If the entered token is valid, the user is navigated to a new screen. If the token is not valid, an error message is displayed.
  ///
  /// The "Resend Token" button generates a new token for the user by calling the `sendToken` method of the `TokenService` class.
  /// The new token is then sent to the user's email.
  ///
  /// Only one token is associated with a user at any given time. If a new token is generated, it replaces the previous token.
  ///
  /// @param context The build context in which the dialog is to be shown.
  /// @param userEmail The email of the user for whom the token is to be validated or generated.
  /// @param setState A function that is called to update the state of the widget. This function is called when the entered token changes.
  void showTokenDialog(BuildContext context, String userEmail, Function setState) {
    String userInputToken = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(218, 138, 197, 253),
          contentTextStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: Colors.black,
          ),
            title: StreamBuilder<String>(
              stream: startTimer(setState, userEmail),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.hasData) {
                  return Text('Enter Token  ${snapshot.data}');
                } else {
                  return const Text('Enter Token');
                }
              },
            ),
          content: TextField(
            onChanged: (value) {
              setState(() {
                userInputToken = value;
              });
            },
            decoration: const InputDecoration(hintText: "Enter your token"),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () async {
                await validateAndNavigate(context, userEmail, userInputToken);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(ThemeColors.themeBlue),
                elevation: MaterialStateProperty.all<double>(4),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: const BorderSide(color: Color.fromARGB(75, 6, 110, 195)),
                  ),
                ),
              ),
              child: const Text(
                'Ok',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.black
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                sendToken(userEmail, setState);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(ThemeColors.themeBlue),
                elevation: MaterialStateProperty.all<double>(4),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: const BorderSide(color: Color.fromARGB(75, 6, 110, 195)),
                  ),
                ),
              ),
              child: const Text(
                'Resend Token',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.black
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}