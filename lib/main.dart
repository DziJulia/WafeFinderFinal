import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:wavefinder/about_us.dart';
import 'package:wavefinder/blocks/payment/payment_bloc.dart';
import 'package:wavefinder/components/functions.dart';
import 'package:wavefinder/config/database_helper.dart';
import 'package:wavefinder/config/user_session.dart';
import 'package:wavefinder/constants/credentials.dart';
import 'package:wavefinder/contact_us.dart';
import 'package:wavefinder/credit_card_screen.dart';
import 'package:wavefinder/dasboard_screen.dart';
import 'package:wavefinder/forgot_password_screen.dart';
import 'package:wavefinder/profile.dart';
import 'package:wavefinder/settings_screen.dart';
import 'package:wavefinder/update_password.dart';
import 'constants/platform.dart';
import '/components/bubbles.dart';
import 'components/buttons/buttons.dart';
import 'sign_in_screen.dart';
import 'registration.dart';
import '/theme/colors.dart';
import '/video_splash_screen.dart';

/// Entry point of the application.
void main() async {
  /// Initializes Facebook login for web and macOS platforms.
  ///
  /// This method should be called during app initialization, and it's necessary for Facebook login to function correctly on web and macOS platforms.
  ///
  /// The `appId` parameter is the unique identifier for your Facebook app. You can find this ID on your Facebook app's dashboard.
  ///
  /// The `cookie` parameter, when set to true, enables Facebook to store a cookie on the client to facilitate access to the Facebook SDK.
  ///
  /// The `xfbml` parameter, when set to true, parses XFBML tags in your HTML to render social plugins such as like and share buttons.
  ///
  /// The `version` parameter specifies the version of the Facebook Graph API to use. It's recommended to use the latest stable version.
  if (kIsWeb || isMacOS) {
    await FacebookAuth.i.webAndDesktopInitialize(
      appId: "",
      cookie: true,
      xfbml: true,
      version: "v19.0",
    );
  }
  final userSession = UserSession();
  final paymentBloc = PaymentBloc();
  // Set your Stripe publishable key here
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = publishableTestKey;
  //Stripe.publishableKey = publishableKey;
  await Stripe.instance.applySettings();
  await DBHelper().autoDestroyUsers();
  await DBHelper().insertLocations();
  await initializeService();

  //run the main app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserSession>.value(value: userSession),
        BlocProvider<PaymentBloc>.value(value: paymentBloc),
      ],
      child: MyApp(),
    ),
  );
}

/// This is the main application widget.a
class MyApp extends StatelessWidget {
  final UserSession userSession = UserSession();
  /// Creates the MyApp widget.
  ///
  /// [Key] is an optional parameter.
  MyApp({super.key});

  /// Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserSession>.value(
      value: userSession,
      child:  MaterialApp(
        theme: ThemeData(
          // Define the default background color.
          scaffoldBackgroundColor: ThemeColors.background,
          primarySwatch: Colors.blue,
        ),
        home: const VideoSplashScreen(),
        //define the routes
        routes: {
          '/AboutUs': (context) => const AboutUsScreen(),
          '/ContactUs': (context) => const ContactUsScreen(),
          '/DashboardScreen': (context) => const DashboardScreen(),
          '/ForgotPassword': (context) => const ForgotPassword(),
          '/NewPassword': (context) => const UpdatePassword(),
          '/PaymentDetails': (context) => const CreditCardScreen(),
          '/Profile': (context) => const ProfileScreen(),
          '/Settings': (context) => const SettingsScreen(),
          '/SignInScreen': (context) => const SignInScreen(),
          '/SignInSignUpPage': (context) => const SignInSignUpPage(),
          '/SignUpScreen': (context) => const SignUpScreen(),
        },
      )
    );
  }
}

/// A stateless widget for a page with sign-in and sign-up buttons.
class SignInSignUpPage extends StatelessWidget {
  /// Creates a const instance of [SignInSignUpPage].
  ///
  /// [Key] is an optional parameter.
  const SignInSignUpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PositionedBubble(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/logo.jpg',
                  width: 100,
                ),
                const SizedBox(height: 20),
                SignInSignUpButton(
                  onPressed: () {
                    // To switch to a new route, use the Navigator.push() method. The push()
                    // method adds a Route to the stack of routes managed by the Navigator.
                    Navigator.pushNamed(context, '/SignUpScreen');
                  },
                  buttonText: 'SIGN UP',
                ),
                const SizedBox(height: 20),
                SignInSignUpButton(
                  onPressed: () {
                    // To switch to a new route, use the Navigator.push() method. The push()
                    // method adds a Route to the stack of routes managed by the Navigator.
                     Navigator.pushNamed(context, '/SignInScreen');
                  },
                  buttonText: 'SIGN IN',
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/images/surfer.png',
                    //making it repsonsive for Mac
                  width: isAndroid? 330 : (isMacOS ? 360 : 500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
