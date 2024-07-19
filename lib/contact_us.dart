import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wavefinder/components/bubbles.dart';
import 'package:wavefinder/components/responsive_menu.dart';
import 'package:wavefinder/components/setting_header.dart';
import 'package:wavefinder/config/backround_service_db.dart';
import 'package:wavefinder/config/user_session.dart';
import 'package:wavefinder/constants/platform.dart';
import 'package:wavefinder/theme/colors.dart';

/// [ContactUsScreen] is a [StatefulWidget] that presents a form to the user.
/// 
/// The form collects the user's name, email, and message. The user's name is optional.
/// The user's email is obtained from the user session.
/// When the form is submitted, an email is sent to 'wavefinderapp@gmail.com'.
class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ContactUsScreenState createState() => ContactUsScreenState();
}

/// [ContactUsScreenState] is the [State] for [ContactUsScreen].
/// 
/// It holds the [TextEditingController]s for the form fields and the form key.
/// It also defines the method to send an email when the form is submitted.
/// The user's email is obtained from the [UserSession] and the email is
/// sent to 'wavefinderapp@gmail.com'.
class ContactUsScreenState extends State<ContactUsScreen> {
  /// Keys to identify and validate the form.
  final _formKey = GlobalKey<FormState>();

  /// Controller for the name field.
  final _nameController = TextEditingController();

  /// Controller for the message field.
  final _messageController = TextEditingController();

  /// Dispose the controllers when they are no longer needed.
  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Builds the UI for the contact us screen.
  @override
  Widget build(BuildContext context) {
    /// Get the user's email from the [UserSession].
    final userEmail = Provider.of<UserSession>(context).userEmail;
    var screenSize = MediaQuery.of(context).size;

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
          const SettingHeader(headerText: 'Contact Us'),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 7,
                        decoration: InputDecoration(
                          labelText: 'Your Message',
                          prefixIcon: const Icon(Icons.message),
                          labelStyle: const TextStyle(
                            fontFamily: 'Poppins',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your message';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            MailerIsolate mailerIsolate = MailerIsolate();
                            mailerIsolate.start('ContactUsMailer', userEmail!, userName:_nameController.text, userMessage: _messageController.text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: ThemeColors.themeBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Send Message',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ]
                  ),
                ),
              )
            ),
          ),
        ],
      );
    },
  ),
);

  }
}
