import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:wavefinder/components/bubbles.dart';
import 'package:wavefinder/components/buttons/custom_button.dart';
import 'package:wavefinder/components/responsive_menu.dart';
import 'package:wavefinder/components/setting_header.dart';
import 'package:wavefinder/config/user_session.dart';
import 'package:wavefinder/constants/platform.dart';

/// A screen that provides various user settings options such as editing profile,
/// viewing payment details, contacting support, and logging out.
///
/// This screen is stateful and uses a [LayoutBuilder] to adjust its layout
/// based on the screen size. The settings options are displayed using custom
/// buttons inside a styled container.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final double fontSize = screenSize.width * 0.05;

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
              const SettingHeader(headerText: 'Settings'),
              Positioned(
                top: constraints.maxHeight * 0.35,
                bottom: constraints.maxHeight * (isAndroid ? 0.01 : 0.1),
                left: 20,
                right: 20,
                child: Container(
                  width: screenSize.width * 0.8,
                  height: screenSize.height * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CustomButton(
                        icon: Icons.edit,
                        text: 'Edit Profile',
                        fontSize: fontSize,
                        onPressed: () {
                          Navigator.pushNamed(context, '/Profile');
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Divider(color: Colors.black),
                      ),
                      CustomButton(
                        icon: Icons.payment,
                        text: 'Payment Details',
                        fontSize: fontSize,
                        onPressed: () {
                          Navigator.pushNamed(context, '/PaymentDetails');
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Divider(color: Colors.black),
                      ),
                      CustomButton(
                        icon: Icons.contact_support,
                        text: 'Contact Us',
                        fontSize: fontSize,
                        onPressed: () {
                          Navigator.pushNamed(context, '/ContactUs');
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Divider(color: Colors.black),
                      ),
                      CustomButton(
                        icon: Icons.logout,
                        text: 'Log Out',
                        fontSize: fontSize,
                        onPressed: () {
                          // For Google Sign-In, the GoogleSignIn class to log out
                          GoogleSignIn().signOut();
                          // For Facebook Sign-In, the Facebook SDK to log out
                          FacebookAuth.instance.logOut();
                          Provider.of<UserSession>(context, listen: false).updateUserEmail('');
                          Navigator.pushNamed(context, '/SignInSignUpPage');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
