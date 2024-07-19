import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wavefinder/components/buttons/buttons.dart';
import 'package:wavefinder/components/sanitaze.dart';
import 'package:wavefinder/config/database_helper.dart';
import 'package:wavefinder/config/user_session.dart';
import 'package:wavefinder/constants/platform.dart';
import 'components/bubbles.dart';
import 'components/input_field.dart';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({super.key});

  @override
  UpdatePasswordState createState() => UpdatePasswordState();
}

class UpdatePasswordState extends State<UpdatePassword> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm(String userEmail) async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      try {
        await DBHelper().updateUserPassword(userEmail, _passwordController.text);
      // Navigate to sign in screen after successful update
      // Check if the widget is still in the tree
        if (mounted) {
          Navigator.pushNamed(context, '/SignInScreen');
        }
      }
      catch (e) {
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error on update. Password not updated!'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double widthButton = screenWidth * (isMobile ?  1 : 0.42) ;
    final userEmail = Provider.of<UserSession>(context).userEmail;

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
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SignInSignUpButton(
                   onPressed: () async {
                      if (userEmail != null) {
                        await _submitForm(userEmail);
                      } else {
                        // Handle the case where userEmail is null
                        print('userEmail is null');
                      }
                    },
                    buttonText: 'Save Password',
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
