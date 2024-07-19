import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:wavefinder/constants/credentials.dart';

class ResetPasswordMailer {
    /// Sends an email with the token to the user's email.
    ///
    /// @param userEmail The email of the user to whom the email is sent.
    /// @param token The token to be included in the email.
    /// @return A Future that completes when the email has been sent.
    Future<void> sendEmail(String userEmail, String token) async {
      final smtpServer = gmail(contactEmail, gmailAppKey);
      // Create our email message.
      final message = Message()
        ..from = const Address(contactEmail, 'Julia from WaveFinder')
        ..recipients.add(userEmail)
        ..subject = 'WaveFinder: Your Verification Token'
        ..text = '''
Dear WaveFinder User,

Thank you for using WaveFinder. We received a request to reset your password. 

Here is your verification token: $token

Please enter this token in the app to proceed with resetting your password. If you did not request a password reset, please ignore this email.

Best regards,
Julia
WaveFinder Team
        ''';

      try {
        final sendReport = await send(message, smtpServer);
        print('Message sent: $sendReport');
        print('Message token: $token');
      } catch (e) {
        print('Message not sent: $e');
      }
    }
  }