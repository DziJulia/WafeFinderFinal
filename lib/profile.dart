import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wavefinder/components/bubbles.dart';
import 'package:wavefinder/components/input_field.dart';
import 'package:wavefinder/components/responsive_menu.dart';
import 'package:wavefinder/components/sanitaze.dart';
import 'package:wavefinder/components/buttons/save_button.dart';
import 'package:wavefinder/components/setting_header.dart';
import 'package:wavefinder/config/backround_service_db.dart';
import 'package:wavefinder/config/user_session.dart';
import 'package:wavefinder/config/database_helper.dart';
import 'package:wavefinder/constants/platform.dart';

/// `ProfileScreen` is a `StatefulWidget` that represents the profile screen of the application.
///
/// This widget accepts an optional `Key` as a parameter, which can be used to control the framework's widget
/// replacement and state synchronization behaviors.
///
/// The `createState` method is overridden to create a mutable state for this widget at a given location in the tree.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MailerIsolate mailerIsolate = MailerIsolate();
    var screenSize = MediaQuery.of(context).size;
    final double fontSize = screenSize.width * (isAndroid ? 0.04 : 0.05);
    final userEmail = Provider.of<UserSession>(context).userEmail;
    bool isValid = false;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Stack(
            children: <Widget>[
              PositionedBubble(),

              const Positioned(
                top: 60,
                right: 0,
                child: ResponsiveMenu(),
              ),
              const SettingHeader(headerText: 'Profile'),
              Positioned(
                top: constraints.maxHeight * 0.32,
                bottom: constraints.maxHeight * (isAndroid ? 0.01 : 0.1),
                left: 0,
                right: 0,
                child: Container(
                  width: screenSize.width * 0.8,
                  height: screenSize.height * 0.7,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(9),
                  padding: const EdgeInsets.all(10),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.always,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Update Password',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: fontSize
                          ),
                        ),
                        InputField(
                          hintText: 'Enter Old Password',
                          isPassword: true,
                          onChanged: (value) async {
                            isValid = await DBHelper().validateUserCredentials(userEmail!, value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            } else if (!isValid) {
                              return 'The password is incorrect';
                            }
                            return null;
                          },
                        ),

                        InputField(
                          hintText: 'Enter New Password',
                          controller: _passwordController,
                          isPassword: true,
                          validator: (value) {
                            if (validatePassword(value) != null) {
                              return validatePassword(value);
                            }
                            return null;
                          },
                        ),

                        InputField(
                          hintText: 'Confirm Password',
                          controller: _confirmPasswordController,
                          isPassword: true,
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            SaveButton(
                              onPressed: () async{
                                await DBHelper().updateUserPassword(userEmail!, _passwordController.text);
                                if (mounted) {
                                  showSaveDialog(
                                    context,
                                    'Password has been updated!'
                                  );
                                  mailerIsolate.start('PasswordUpdateMailer', userEmail);
                                  _formKey.currentState!.reset();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                }
                              },
                            ),
                          ],
                        ),
                        if (isiOS) const SizedBox(height: 10),
                        Text(
                          'Delete Account',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: fontSize - 3
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(const Color.fromRGBO(244, 74, 74, 1)),
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0), // Adjust the value for desired roundness
                              ),
                            ),
                          ),
                          onPressed: () async {
                            await DBHelper().deleteUser(userEmail!);
                            await showSaveDialog(
                              context,
                              'Account has been deleted!'
                            );
                            Navigator.pushNamed(context, '/SignInSignUpPage');
                            mailerIsolate.start('AccountRemovalMailer', userEmail);
                          },
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.black
                          ),
                          label: const Text(
                            'Delete Account',
                             style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.black
                             )
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        } 
      ),
    );
  }
}
