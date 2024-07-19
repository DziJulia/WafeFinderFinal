import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:wavefinder/constants/credentials.dart';

class CardRemovalMailer {
  Future<void> sendEmail(String userEmail) async {
    final smtpServer = gmail(contactEmail, gmailAppKey);
    final mailMessage = Message()
      ..from = const Address(contactEmail, 'WaveFinder App Team')
      ..recipients.add(userEmail)
      ..subject = 'Card Removal Confirmation'
      ..text = '''
Dear WaveFinder User,

We noticed that your card has been successfully removed from our system. If this action was not initiated by you, please get in touch with us immediately.

It's important to update your payment details promptly to avoid any interruption in services. If no alternative card is found in the system, please be aware that our services may be temporarily suspended until the payment information is updated.

We appreciate your prompt attention to this matter.

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
