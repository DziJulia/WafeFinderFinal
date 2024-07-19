import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:wavefinder/constants/credentials.dart';

class PasswordUpdateMailer {
  Future<void> sendEmail(String userEmail) async {
    final smtpServer = gmail(contactEmail, gmailAppKey);
    final mailMessage = Message()
      ..from = const Address(contactEmail, 'WaveFinder App Team')
      ..recipients.add(userEmail)
      ..subject = 'Password Update Confirmation'
      ..text = '''
Dear WaveFinder User,

Your password has been updated successfully. If you did not make this change, please contact us immediately.

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
