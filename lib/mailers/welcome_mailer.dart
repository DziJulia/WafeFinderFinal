import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:wavefinder/constants/credentials.dart';

class WelcomeMailer {
  Future<void> sendEmail(String userEmail) async {
    print('MAIL WELCOME SENT');
    final smtpServer = gmail(contactEmail, gmailAppKey);
    final mailMessage = Message()
      ..from = const Address(contactEmail, 'WaveFinder App Team')
      ..recipients.add(userEmail)
      ..subject = 'Welcome to WaveFinder'
      ..text = '''
Dear WaveFinder User,

Welcome to WaveFinder! We're excited to have you join our community.

You can start exploring our app right away. If you have any questions or need assistance, don't hesitate to contact us.

We hope you enjoy using WaveFinder.

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
