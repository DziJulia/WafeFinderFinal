import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:wavefinder/config/user_session.dart';
import 'package:wavefinder/constants/platform.dart';
import 'package:wavefinder/theme/colors.dart';

enum MenuItems { logOut, settings, contactUs, dasboard }

/// A responsive menu widget that adapts to different screen sizes.
///
/// This widget displays a different layout depending on whether the screen
/// width is less than 600 pixels. For screens with width less than 600 pixels,
/// a mobile menu layout is displayed. For screens with width greater than or
/// equal to 600 pixels, a desktop menu layout is displayed.
class ResponsiveMenu extends StatefulWidget {
  const ResponsiveMenu({super.key});

  @override
  ResponsiveMenuState createState() => ResponsiveMenuState();
}

/// The state for [ResponsiveMenu] widget.
///
/// This class defines the widget build function which adapts the layout based on the screen size
class ResponsiveMenuState extends State<ResponsiveMenu> {
  MenuItems? selectedItem;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isMobile) {
          return buildMobileMenu();
        } else {
          return buildDesktopMenu();
        }
      },
    );
  }

  /// Logs out the user from all third-party services.
  ///
  /// This method is used to log out the user from all third-party services that the user has signed in with.
  /// It includes Google Sign-In, Facebook Sign-In, and other third-party services that you might be using.
  /// Each third-party service has its own way of logging out a user. For Google Sign-In, we use `GoogleSignIn().signOut()`.
  /// For Facebook Sign-In, we use `FacebookAuth.instance.logOut()`. Similar logic should be added for other third-party services.
  ///
  /// Usage:
  ///
  /// ```dart
  /// logoutFromThirdPartyServices();
  /// ```
  void logoutFromThirdPartyServices() {
    // For Google Sign-In, the GoogleSignIn class to log out
    GoogleSignIn().signOut();
    Provider.of<UserSession>(context, listen: false).updateUserEmail('');
    // For Facebook Sign-In,the Facebook SDK to log out
    FacebookAuth.instance.logOut();
  }


  /// Builds the mobile menu layout.
  ///
  /// This layout is used when the screen width is less than 600 pixels.
  Widget buildMobileMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        PopupMenuButton<MenuItems>(
          icon: const Icon(Icons.menu, color: Colors.black),
          color: ThemeColors.themeBlue,
          onSelected: (MenuItems item) {
            setState(() {
              selectedItem = item;
            });
            if (item == MenuItems.logOut) {
              logoutFromThirdPartyServices();
              Navigator.pushNamed(context, '/SignInSignUpPage');
            } else if(item == MenuItems.dasboard) {
              Navigator.pushNamed(context, '/DashboardScreen');
            } else if(item == MenuItems.settings) {
              Navigator.pushNamed(context, '/Settings');
            } else if(item == MenuItems.contactUs) {
              Navigator.pushNamed(context, '/AboutUs');
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuItems>>[
            const PopupMenuItem<MenuItems>(
              value: MenuItems.logOut,
              child: Column(
                children: [
                  Text('Log Out', style: TextStyle(fontFamily: 'Poppins')),
                  Divider(color: Colors.black),
                ],
              ),
            ),
            const PopupMenuItem<MenuItems>(
              value: MenuItems.dasboard,
              child: Column(
                children: [
                  Text('Dashboard', style: TextStyle(fontFamily: 'Poppins')),
                  Divider(color: Colors.black),
                ],
              ),
            ),
            const PopupMenuItem<MenuItems>(
              value: MenuItems.settings,
              child: Column(
                children: [
                  Text('Settings', style: TextStyle(fontFamily: 'Poppins')),
                  Divider(color: Colors.black),
                ],
              ),
            ),
            const PopupMenuItem<MenuItems>(
              value: MenuItems.contactUs,
              child: Column(
                children: [
                  Text('About Us', style: TextStyle(fontFamily: 'Poppins')),
                   Divider(color: ThemeColors.themeBlue),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the desktop menu layout.
  ///
  /// This layout is used when the screen width is greater than or equal to 600 pixels.
  Widget buildDesktopMenu() {
    return Container(
      color: ThemeColors.themeBlue,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          TextButton(
            child: const Text('Menu', style: TextStyle(color: Colors.black, fontFamily: 'Poppins')),
            onPressed: () {},
          ),
          PopupMenuButton<MenuItems>(
            onSelected: (MenuItems item) {
              setState(() {
                selectedItem = item;
              });

              if (item == MenuItems.logOut) {
                Navigator.pushNamed(context, '/SignInSignUpPage');
              } else if(item == MenuItems.dasboard) {
                Navigator.pushNamed(context, '/DashboardScreen');
              } else if(item == MenuItems.settings) {
                Navigator.pushNamed(context, '/Settings');
              } else if(item == MenuItems.contactUs) {
                Navigator.pushNamed(context, '/AboutUs');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuItems>>[
              const PopupMenuItem<MenuItems>(
                value: MenuItems.logOut,
                child: Column(
                  children: [
                    Text('Log Out', style: TextStyle(fontFamily: 'Poppins')),
                    Divider(color: Colors.black),
                  ],
                ),
              ),
              const PopupMenuItem<MenuItems>(
                value: MenuItems.dasboard,
                child: Column(
                  children: [
                    Text('Dashboard', style: TextStyle(fontFamily: 'Poppins')),
                    Divider(color: Colors.black),
                  ],
                ),
              ),
              const PopupMenuItem<MenuItems>(
                value: MenuItems.settings,
                child: Column(
                  children: [
                    Text('Settings', style: TextStyle(fontFamily: 'Poppins')),
                    Divider(color: Colors.black),
                  ],
                ),
              ),
              const PopupMenuItem<MenuItems>(
                value: MenuItems.contactUs,
                child: Column(
                  children: [
                    Text('Contact Us', style: TextStyle(fontFamily: 'Poppins')),
                    Divider(color: ThemeColors.themeBlue),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
