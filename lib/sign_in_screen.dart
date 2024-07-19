import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:wavefinder/components/dialogs/boolean_dialog.dart';
import 'package:wavefinder/components/sanitaze.dart';
import 'package:wavefinder/config/backround_service_db.dart';
import 'package:wavefinder/config/user_session.dart';
import 'package:wavefinder/config/database_helper.dart';
import 'package:wavefinder/config/user.dart';
import 'package:wavefinder/third_parties/facebook.dart';
import 'package:wavefinder/third_parties/google.dart';
import 'package:wavefinder/third_parties/sign_in_account.dart';
import 'components/bubbles.dart';
import 'constants/platform.dart';
import 'components/buttons/buttons.dart';
import 'components/buttons/flat_button.dart';
import 'components/input_field.dart';

/// A stateless widget representing the sign-in screen.
///
/// This screen contains two input fields for user email and password,
/// a 'Forgot Password?' button, and a 'LOG IN' button.
/// The layout of these elements is managed by a Stack widget.
class SignInScreen extends StatefulWidget {
  /// Creates a SignInScreen widget.
  ///
  /// The [Key] argument is optional and not required for the widget to function.
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
    // Creating TextEditingController for email and password
    final _formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool userExists = false;
    User? existingUser;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Asynchronously handles the user sign-in process.
  ///
  /// This function validates the form state and then checks the user credentials
  /// against the database using the `DBHelper().validateUserCredentials` method.
  ///
  /// If the user is found and their account has been soft-deleted, it prompts them
  /// with an option to recover their account. If the user chooses to recover their
  /// account, the `DBHelper().recoverUser` method is called.
  ///
  /// If the user is found and their account is active, their email is updated in the
  /// `UserSession` and they are navigated to the Dashboard screen.
  ///
  /// If the user is not found or the credentials do not match, a SnackBar is shown
  /// with an error message.
  ///
  /// Returns a `Future<void>`.
  Future<void> _handleSignIn() async {
       print('SIGNING');
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      String email = emailController.text;
      String password = passwordController.text;
      print(email);
      bool isValid = await DBHelper().validateUserCredentials(email, password);
      if (isValid) {
        //User? user = dbUpdateIsolate.start('getUser', email);
        User? user =  await DBHelper().getUser(email);
        print(user);
        if(user?.deletedAt == null) {
          if(mounted) {
            Provider.of<UserSession>(context, listen: false).updateUserEmail(email);
            Navigator.pushNamed(context, '/DashboardScreen');
          }
        } else {
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
            if(mounted) {
              Provider.of<UserSession>(context, listen: false).updateUserEmail(email);
              Navigator.pushNamed(context, '/DashboardScreen');
              MailerIsolate mailerIsolate = MailerIsolate();
              mailerIsolate.start('AccountRecoveryMailer', email);
            }
          }
          else{
            // Display error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account has not been recovered.'))
            );
          }
        }
      } else {
      // Display error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username or password does not match. Please try again.'))
      );
    }
    }
  }

  /// Safely shows an error dialog when a sign-in attempt fails.
  ///
  /// This method takes a [String] as a parameter, which represents the name of the provider that failed to sign in.
  /// It checks if the widget is still mounted before showing the dialog.
  ///
  /// The dialog shows a message indicating that the sign-in attempt with the specified provider has failed and suggests the user to try again.
  ///
  /// Usage:
  ///
  /// ```dart
  /// safeShowErrorDialog('Google');
  /// ```
  ///
  /// @param provider The name of the provider that failed to sign in.
  void safeShowErrorDialog(String provider) {
    if (mounted) {
      SignInAccount().showErrorDialog(context, provider);
    }
  }

  /// Builds the widget tree for the SignInScreen.
  ///
  /// The widget tree includes an AppBar, a Stack for layout management,
  /// two InputField widgets for user email and password input,
  /// a FlatButton for password recovery, and a SignInSignUpButton for user login.
  @override
  Widget build(BuildContext context) {
    GoogleSignInHelper googleSignInHelper = GoogleSignInHelper();
    // Get the screen width
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width * (isMobile ? (isAndroid ? 0.85 : 1) : 0.47);

    return Scaffold(
      //for IOS to avoid puttin keyboard and let the fields scroll up
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          // Bottom background image
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/wave.png',
              // Set fit to cover the entire bottom area
              fit: BoxFit.cover,
              // Set width to match the screen width
              width: screenWidth,
            ),
          ),
          PositionedBubble(),
          Center(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.always,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                //addin this to check if user is alreay in database
                StreamBuilder<String?>(
                  stream: null,
                  builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                    return InputField(
                      controller: emailController,
                      hintText: 'Enter email',
                      onChanged: (value) async {
                        userExists = await DBHelper().userExists(value);
                        existingUser = await DBHelper().getUser(value);
                      },
                     validator: (value) {
                        String cleanValue = sanitizeInput(value!);
                        if (cleanValue == 'Invalid email format') {
                            return 'Please enter a valid email';
                          } else if (cleanValue.isEmpty) {
                            return 'Please enter a valid email';
                          } else if (!userExists) {
                          return 'A user with this email does not exists.';
                        } else if (existingUser != null && existingUser!.isThirdParty) {
                          return 'Alredy signed up with Google or Facebook.';
                        }
                        return null;
                      },
                    );
                  },
                ),
                InputField(
                  controller: passwordController,
                  hintText: 'Enter password',
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  }
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: screenWidth * (isMobile ?  0.41 : 0.85),
                    // Set the maximum width of the FlatButtonx
                    child: Padding(
                      padding: EdgeInsets.only(right: isMobile ? 20 : screenWidth * 0.45),
                      child: FlatButton(
                        onPressed: () { 
                          Navigator.pushNamed(context, '/ForgotPassword');
                        },
                        buttonText: 'Forgot Password?'
                      ),
                    ),
                  ),
                ),
                SizedBox(height: (isAndroid ? 10 : 30)),
                SignInSignUpButton(
                  onPressed: _handleSignIn,
                  buttonText: 'LOG IN',
                ),
                const SizedBox(height: 5),
                FlatButton(
                  onPressed: () { 
                    // To switch to a new route, use the Navigator.push() method. The push()
                      // method adds a Route to the stack of routes managed by the Navigator.
                      Navigator.pushNamed(context, '/SignUpScreen');
                    },
                    buttonText: "Don't have an account?"
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       // Use the helper class to build Facebook Sign-In button
                      IconButton(
                        onPressed: () async {
                          print('click on button');
                          // Handle Facebook Sign-In button press
                          AccessToken? accessToken = await FacebookAuthHelper.signInWithFacebook();
                          print(accessToken);
                          if (accessToken != null) {
                            // Successfully signed in with Facebook
                            String? email = await FacebookAuthHelper.getEmailFromAccessToken(accessToken.token);
                             if (email != null) {
                              bool canSignIn = await SignInAccount().handleSignIn(existingUser, email, context);
                              if(canSignIn){
                                SignInAccount().insertThirdPartyUserAndNavigate((existingUser == null), email, context, this);
                              }
                            }
                          }
                          else {
                            safeShowErrorDialog('Facebook'); 
                          }
                        },
                        icon: Image.asset('assets/icons/facebook.png', height: 60.0), 
                      ),
                      const SizedBox(width: 20),
                      // Use the helper class to build Google Sign-In button
                      googleSignInHelper.buildGoogleSignInButton(
                        onPressed: () async {
                          // Handle Google Sign-In button press
                           GoogleSignInAccount? googleSignInAccount = await googleSignInHelper.signInWithGoogle();
                          if (googleSignInAccount != null) {
                            // Successfully signed in with Google
                            String? email = googleSignInAccount.email;
                            User? existingUser = await DBHelper().getUser(email);
                            // Successfully signed in with Google
                            bool canSignIn = await SignInAccount().handleSignIn(existingUser, email, context);
                                   print(canSignIn);
                            if(canSignIn){
                              SignInAccount().insertThirdPartyUserAndNavigate((existingUser == null), email, context, this);
                            }
                        } else {
                          // Optionally, show a dialog or a snackbar to inform the user
                          safeShowErrorDialog('Google');                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * (isAndroid ? 0.14 : 0.2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
