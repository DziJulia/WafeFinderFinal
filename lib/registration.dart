import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wavefinder/components/buttons/buttons.dart';
import 'package:wavefinder/components/sanitaze.dart';
import 'package:wavefinder/config/backround_service_db.dart';
import 'package:wavefinder/config/user_session.dart';
import 'package:wavefinder/constants/platform.dart';
import 'components/bubbles.dart';
import 'components/buttons/flat_button.dart';
import 'components/input_field.dart';
import 'config/user.dart';
import 'config/database_helper.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      //print('PASS VALIDATION');
      // Create a new User object
      User newUser = User(
        userEmail: _emailController.text,
        password: _passwordController.text,
        userPreferences: '',
        createdAt: DateTime.now(),
      );

      try {
        // Insert the user into the database
        await DBHelper().insertUser(newUser);
        MailerIsolate mailerIsolate = MailerIsolate();
        mailerIsolate.start('WelcomeMailer', _emailController.text);
      // Navigate to dashboard screen after successful registration
      // Check if the widget is still in the tree
        if (mounted) {
          Provider.of<UserSession>(context, listen: false).updateUserEmail(newUser.userEmail);
          // Navigate to dashboard screen after successful registration
          Navigator.pushNamed(context, '/DashboardScreen');
        }
      }
      catch (e) {
        // Show an error message
       print('User exists');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double widthButton = screenWidth * (isMobile ?  1 : 0.42) ;
    bool userExists = false;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
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
                        hintText: 'Enter email',
                        controller: _emailController,
                        onChanged: (value) async {
                          userExists = await DBHelper().userExists(value);
                        },
                        validator: (value) {
                          String cleanValue = sanitizeInput(value!);
                          if (cleanValue == 'Invalid email format') {
                            return 'Please enter a valid email';
                          } else if (cleanValue.isEmpty) {
                            return 'Please enter a valid email';
                          } else if (userExists) {
                            return 'A user with this email already exists.';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  // Validating if password was entered
                  InputField(
                    hintText: 'Enter password',
                    controller: _passwordController,
                    isPassword: true,
                    validator: (value) {
                      if (validatePassword(value) != null) {
                        return validatePassword(value);
                      }
                      return null;
                    },
                  ),
                  // Validating if password match
                  InputField(
                      controller: _confirmPasswordController,
                      isPassword: true,
                      hintText: 'Confirm password',
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: widthButton,
                      child: Padding(
                      padding: EdgeInsets.only(
                          left: isMobile ? screenWidth * 0.6 :  0.0,
                          right: isMobile ? 0.0 : screenWidth * 0.22,
                        ),
                        child: FlatButton(
                          onPressed: () { 
                            // To switch to a new route, use the Navigator.push() method. The push()
                            // method adds a Route to the stack of routes managed by the Navigator.
                            Navigator.pushNamed(context, '/SignInScreen');
                          },
                          buttonText: 'Already Registered?',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SignInSignUpButton(
                    onPressed: _submitForm,
                    buttonText: 'REGISTER',
                  ),
                  SizedBox(height: isiOS ? 50: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      'assets/images/surf.jpeg',
                      width: screenWidth * 0.4,
                      height: screenHeight * 0.25,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
