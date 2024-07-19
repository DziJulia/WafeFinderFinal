import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:wavefinder/constants/credentials.dart';

class AccountRemovalMailer {
  Future<void> sendEmail(String userEmail) async {
    final smtpServer = gmail(contactEmail, gmailAppKey);
    final mailMessage = Message()
      ..from = const Address(contactEmail, 'WaveFinder App Team')
      ..recipients.add(userEmail)
      ..subject = 'Account Deletion Confirmation'
      ..text = '''
Dear WaveFinder User,

We have received a request to delete your account. If this action was not initiated by you, please get in touch with us immediately.

Please note that you have **7 days** to reactivate your account. After this period, if no action is taken, your account will be permanently deleted.

To reactivate your account, please log in to the app and select 'Reactivate Account'. If you encounter any issues, don't hesitate to contact us.

We appreciate your understanding.

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
