import 'package:flutter/material.dart';
import 'package:wavefinder/components/dialogs/dialog.dart';
import 'package:wavefinder/components/token_generator.dart';
import 'package:wavefinder/config/database_helper.dart';
import 'package:wavefinder/config/user.dart';
import 'components/bubbles.dart';
import 'components/buttons/buttons.dart';
import 'components/buttons/flat_button.dart';
import 'constants/platform.dart';
import 'components/input_field.dart';

/// A stateless widget representing the Forgot Password screen.
///
/// This screen contains an input field for the user's email,
/// a 'Back to Login' button, and a 'SEND' button.
/// The layout of these elements is managed by a Stack widget.
///
/// When the 'SEND' button is pressed, a password reset email is supposed to be sent to the user.
/// This functionality needs to be implemented.
///
/// When the 'Back to Login' button is pressed, the user is navigated back to the Sign In screen.
class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  ForgotPasswordState createState() => ForgotPasswordState();
}

class ForgotPasswordState extends State<ForgotPassword> {
  final emailController = TextEditingController();

  Future<void> showSaveDialog(BuildContext context) async {
   await showDialog(
      context: context,
      builder: (BuildContext context) {
        return const DialogPop(
          errorMessage: 'Please enter the email address associated with your WaveFinder account.',
          title: 'User Not Found',
        );
      },
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          PositionedBubble(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                InputField(
                  controller: emailController,
                  hintText: 'Enter email',
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: screenWidth * 0.38,
                    // Set the maximum width of the FlatButtonx
                    child: Padding(
                      padding: EdgeInsets.only(right: isMobile ? 22 : 190),
                      child: FlatButton(
                        onPressed: () { 
                          // To switch to a new route, use the Navigator.push() method. The push()
                          // method adds a Route to the stack of routes managed by the Navigator.
                          Navigator.pushNamed(context, '/SignInScreen');
                        },
                        buttonText: 'Back to Login'
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SignInSignUpButton(
                  onPressed: () async {
                    String userEmail = emailController.text;
                    User? user = await DBHelper().getValidUser(userEmail);
                    if(user != null && user.isThirdParty == false) {
                        TokenService().sendToken(userEmail, setState);
                        TokenService().showTokenDialog(context, userEmail, setState);
                    } else {
                      return showSaveDialog(context);
                    }
                  },
                  buttonText: 'SEND',
                ),
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/forgot.png',
                  width: isMobile ? 380 : 400,
                ),
                const SizedBox(height: 30)
              ],
            ),
          ),
        ],
      ),
    );
  }
}
