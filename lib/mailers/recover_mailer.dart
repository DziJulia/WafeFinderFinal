import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:wavefinder/constants/credentials.dart';

class AccountRecoveryMailer {
  Future<void> sendEmail(String userEmail) async {
    final smtpServer = gmail(contactEmail, gmailAppKey);
    final mailMessage = Message()
      ..from = const Address(contactEmail, 'WaveFinder App Team')
      ..recipients.add(userEmail)
      ..subject = 'Account Recovery Confirmation'
      ..text = '''
Dear WaveFinder User,

We're glad to see you back! Your account has been successfully recovered.

You can now log in to the app and continue using our services. If you encounter any issues or have any questions, don't hesitate to contact us.

We appreciate your trust in us.

Best regards,
Julia
WaveFinder Team
      ''';

    try {
      final sendReport = await send(mailMessage, smtpServer);
      print('Message sent: $sendReport');
    } catch (e) {
      print('Message not sent.');
      print(e.toString());
    }
  }
}
