import 'dart:isolate';

import 'package:wavefinder/mailers/account_delete_mailer.dart';
import 'package:wavefinder/mailers/card_removal_maiiler.dart';
import 'package:wavefinder/mailers/card_update_mailer.dart';
import 'package:wavefinder/mailers/contact_us_mailer.dart';
import 'package:wavefinder/mailers/password_update_mailer.dart';
import 'package:wavefinder/mailers/recover_mailer.dart';
import 'package:wavefinder/mailers/reset_password_email.dart';
import 'package:wavefinder/mailers/welcome_mailer.dart';

///
///`MailerIsolate` is a class designed to handle the sending of emails in a non-blocking manner.
///
/// This class uses Dart's `Isolate` system to run email sending operations in parallel with the main application. 
/// This ensures that the main application can continue running smoothly while emails are being sent, even if the email sending process takes a long time or encounters errors.
/// 
///  Each instance of `MailerIsolate` represents a separate worker that can send emails. The type of email to send (e.g., 'AccountRemovalMailer', 'CardRemovalMailer') and the recipient's email address are passed to the `start` method when starting the worker.
/// 
/// Example usage:
/// ```dart
/// MailerIsolate mailerIsolate = MailerIsolate();
/// mailerIsolate.start('AccountRemovalMailer', 'user@example.com');
/// ```
/// 
/// Note: Managing multiple `Isolates` can be complex and might require careful handling of resources. Also, communication between isolates
/// happens via message passing, and only simple data types can be passed between isolates.
///

class MailerIsolate {
  void start(String mailerType, String? userEmail, {String? userName, String? userMessage, String? userToken}) async {
    // Check if userEmail is null before starting the isolate
    if (userEmail == null) {
      print('Error: userEmail is null');
      return;
    }
    // Create a message to send to the new isolate.
    Map<String, dynamic> message = {
      'mailerType': mailerType,
      'userEmail': userEmail,
    };


    if (userName != null) {
      message['userName'] = userName;
    }

    if (userMessage != null) {
      message['userMessage'] = userMessage;
    }

    if (userToken != null) {
      message['userToken'] = userToken;
    }

    // Start the isolate.
    await Isolate.spawn(mailerEntryPoint, message);
  }

  void mailerEntryPoint(Map<String, dynamic> message) async {
    // Extract the information from the message.
    String mailerType = message['mailerType'];
    String userEmail = message['userEmail'];

  // Depending on the mailerType, call the appropriate function.
    switch (mailerType) {
      case 'AccountRemovalMailer':
        AccountRemovalMailer().sendEmail(userEmail);
        break;
      case 'CardRemovalMailer':
        CardRemovalMailer().sendEmail(userEmail);
        break;
      case 'CardUpdateMailer':
        CardUpdateMailer().sendEmail(userEmail);
        break;
      case 'ContactUsMailer':
        ContactUsMailer().sendEmail(message['userName'], userEmail, message['userMessage']);
        break;
      case 'PasswordUpdateMailer':
        PasswordUpdateMailer().sendEmail(userEmail);
        break;
      case 'ResetPasswordMailer':
        ResetPasswordMailer().sendEmail(userEmail, message['userToken']);
        break;
      case 'WelcomeMailer':
        WelcomeMailer().sendEmail(userEmail);
      case 'AccountRecoveryMailer':
        AccountRecoveryMailer().sendEmail(userEmail);
      default:
        print('Unknown mailer type: $mailerType');
    }
  }
}
