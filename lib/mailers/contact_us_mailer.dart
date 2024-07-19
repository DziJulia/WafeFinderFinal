import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:wavefinder/constants/credentials.dart';

/// `ContactUsMailer` is a class that handles sending emails to a contact email address.
///
/// It uses the `mailer` package to send emails via Gmail's SMTP server.
///
/// The `contactEmail` and `gmailAppKey` are required to authenticate with the SMTP server.
class ContactUsMailer {
  /// Sends an email to the contact email address with the user's name, email, and message.
  ///
  /// The `name` parameter is the user's name.
  /// The `email` parameter is the user's email.
  /// The `message` parameter is the user's message.
  ///
  /// This method creates a `Message` with the provided parameters and sends it using the SMTP server.
  /// If the email is sent successfully, it prints a confirmation message.
  /// If the email is not sent, it prints an error message.
  Future<void> sendEmail(String name, String email, String message) async {
    final smtpServer = gmail(contactEmail, gmailAppKey);
    final mailMessage = Message()
      ..from = const Address(contactEmail, 'Julia')
      ..recipients.add(contactEmail)
      ..subject = 'Contact Us Message from $name'
      ..text = 'Name: $name\nEmail: $email\nMessage: $message';

    try {
      final sendReport = await send(mailMessage, smtpServer);
      print('Message sent: $sendReport');
    } catch (e) {
      print('Message not sent.');
      print(e.toString());
    }
  }
}
