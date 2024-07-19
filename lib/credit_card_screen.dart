import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:wavefinder/blocks/payment/payment_bloc.dart';
import 'package:wavefinder/components/bubbles.dart';
import 'package:wavefinder/components/buttons/save_button.dart';
import 'package:wavefinder/components/responsive_menu.dart';
import 'package:wavefinder/components/setting_header.dart';
import 'package:wavefinder/config/backround_service_db.dart';
import 'package:wavefinder/config/credit_card.dart';
import 'package:wavefinder/config/database_helper.dart';
import 'package:wavefinder/config/user_session.dart';
import 'package:wavefinder/constants/platform.dart';
import 'package:wavefinder/theme/colors.dart';

/// A screen for managing the user's credit card information.
///
/// This screen allows users to view their stored credit card information,
/// replace an existing card, or add a new card. It interacts with the
/// [PaymentBloc] to handle payment-related actions.
class CreditCardScreen extends StatefulWidget {
  const CreditCardScreen({super.key});

  @override
  CreditCardScreenState createState() => CreditCardScreenState();
}

class CreditCardScreenState extends State<CreditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CardFormEditController _cardController;
  late String _userEmail;
  final mailerIsolate = MailerIsolate();
  late String subId;
  bool emailSent = false;
  CreditCard? _storedCard;

  @override
  void initState() {
    super.initState();
    _cardController = CardFormEditController();
    _loadUserCard();
  }

  /// Loads the user's stored card information from the database.
  ///
  /// This function fetches the user's email from the [UserSession] and uses
  /// it to retrieve the stored card information from the database.
  Future<void> _loadUserCard() async {
    _userEmail = context.read<UserSession>().userEmail ?? '';
    _storedCard = await DBHelper().getUserCard(_userEmail);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    emailSent = false;
    _storedCard = null;
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _userEmail = context.read<UserSession>().userEmail ?? '';

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        context.read<PaymentBloc>().add(PaymentStart());
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: <Widget>[
            PositionedBubble(),
            const Positioned(
              top: 60,
              right: 0,
              child: ResponsiveMenu(),
            ),
            const SettingHeader(headerText: 'Payment Details'),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              bottom: MediaQuery.of(context).size.height * (isAndroid ? 0.01 : 0.1),
              left: 20,
              right: 20,
              child: _buildCreditCardForm(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the credit card form widget.
  ///
  /// This widget displays the stored card information, a form for adding or
  /// replacing the card, and handles the form submission and validation.
  Widget _buildCreditCardForm(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.always,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            StoredCardWidget(_storedCard),
            AddOrReplaceCardText(_storedCard),
            BlocBuilder<PaymentBloc, PaymentState>(
              builder: (context, state) {
                switch (state.status) {
                  case PaymentStatus.initial:
                    return _buildReplaceCardForm(context);
                  case PaymentStatus.success:
                    final subscriptionResult = state.subscriptionResult ?? {};
                    subId = subscriptionResult.containsKey('id') ? subscriptionResult['id'] : '';

                    return FutureBuilder(
                      future: _buildSuccessState(context),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return snapshot.data;
                        }
                      },
                    );
                  case PaymentStatus.deleted:
                    return _buildState(context, 'Subscription successfully CANCELED!', 'Back');
                  case PaymentStatus.failure:
                    return _buildState(context, 'The payment failed!', 'Try Again!');
                  default:
                    return const Center(child: CircularProgressIndicator());
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Builds the form for replacing the stored card.
  ///
  /// This widget displays the card form fields and the subscribe button.
  Widget _buildReplaceCardForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: isAndroid ? 1 : 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: _buildCardFormContainer(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            SaveButton(
              buttonName: 'Subscribe',
              onPressed: () => _subscribeButtonPressed(context),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ],
    );
  }

  /// Builds the success state widget.
  ///
  /// This function updates the stored card information in the database and
  /// sends an email notification if not already sent.
  Future<Widget> _buildSuccessState(BuildContext context) async {
    final newCard = CreditCard(
      lastFourDigits: _cardController.details.last4.toString(),
      expiryDate: '${_cardController.details.expiryMonth}/${_cardController.details.expiryYear}',
      subscriptionId: subId,
    );

    try {
      await DBHelper().replaceCreditCard(_userEmail, newCard);
      // Operation completed successfully
    } catch (error) {
      // Error occurred during the operation
      print('Error updating credit card: $error');
    }
    if (!emailSent) {
      mailerIsolate.start('CardUpdateMailer', _userEmail);
      emailSent = true;
    }
    return _buildState(context, 'The subscription is successful!', 'Back');
  }

  /// Builds a state widget with a message and button.
  ///
  /// This widget displays a message and a button for navigating back or retrying.
  Widget _buildState(BuildContext context, String message, String bMessage) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message),
        const SizedBox(height: 10, width: double.infinity),
        ElevatedButton(
          onPressed: () async {
            context.read<PaymentBloc>().add(PaymentStart());
            await _loadUserCard();
          },
          child: Text(bMessage),
        ),
      ],
    );
  }

  /// Handles the subscribe button press event.
  ///
  /// This function validates the card details and triggers the payment process.
  void _subscribeButtonPressed(BuildContext context) {
    if (_cardController.details.complete) {
      try {
        context.read<PaymentBloc>().add(
          PaymentCreateIntent(BillingDetails(email: _userEmail)),
        );
        _formKey.currentState!.reset();
      } catch (e) {
        if (e is StripeException) {
          if (e.error.type == 'card_error') {
            if (e.error.stripeErrorCode == 'invalid_expiry_year') {
              // Display a message to the user
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('The expiry year of your card is invalid. Please enter a valid expiry year.'),
                ),
              );
            }
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form is not completed'),
        ),
      );
    }
  }

  /// Builds the card form container widget.
  ///
  /// This widget displays the card form fields with styling based on the platform.
  Widget _buildCardFormContainer() {
    if (isAndroid) {
      return SizedBox(
        height: 245,
        child: CardFormField(
          controller: _cardController,
          style: CardFormStyle(
            fontSize: 12,
          ),
        ),
      );
    } else {
      return CardFormField(
        controller: _cardController,
        style: CardFormStyle(
          fontSize: 12,
        ),
      );
    }
  }
}

/// A widget that displays the stored credit card information.
///
/// This widget shows the last four digits and expiry date of the stored card,
/// or a message if no card is stored.
class StoredCardWidget extends StatelessWidget {
  final CreditCard? _storedCard;

  const StoredCardWidget(this._storedCard, {super.key});

  @override
  Widget build(BuildContext context) {
    return _buildStoredCard(context, _storedCard);
  }
}

/// Builds the stored card widget.
///
/// This function returns a widget that displays the stored card information
/// or a message if no card is stored.
Widget _buildStoredCard(BuildContext context, CreditCard? storedCard) {
  if (storedCard != null) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                padding: EdgeInsets.all(isAndroid ? 10.0 : 20.0),
                decoration: BoxDecoration(
                  color: ThemeColors.bubblesColor,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.credit_card),
                        const SizedBox(width: 10),
                        Text(
                          'Stored Card',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: MediaQuery.of(context).size.width * 0.05,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '**** **** **** ${storedCard.lastFourDigits}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          'Expires: ${storedCard.expiryDate}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: MediaQuery.of(context).size.width * 0.037,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Divider(color: Colors.black),
            ),
          ],
        ),
        Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            icon: const Icon(
              Icons.cancel,
              color: Colors.black,
            ),
            onPressed: () async {
              String userEmail = context.read<UserSession>().userEmail!;
              CreditCard? userCard = await DBHelper().getUserCard(userEmail);
              //soft delete card from DB
              await DBHelper().deleteUserCard(userEmail);
              // Cancel subscription
              context.read<PaymentBloc>().add(
                PaymentCancelSubscription(subscriptionId: userCard!.subscriptionId),
              );

              final mailerIsolate = MailerIsolate();
              mailerIsolate.start('CardRemovalMailer', userEmail);
            },
          ),
        ),
      ],
    );
  } else {
    return Center(
      child: Column(
        children: [
          Text(
            'Card not found!',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: MediaQuery.of(context).size.width * 0.05,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Divider(color: Colors.black),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays a text indicating the action to add or replace a card.
///
/// This widget shows 'Replace Card' if a card is stored, otherwise 'Add a Card'.
class AddOrReplaceCardText extends StatelessWidget {
  final CreditCard? _storedCard;

  const AddOrReplaceCardText(this._storedCard, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      _storedCard != null ? 'Replace Card' : 'Add a Card',
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: (isAndroid ? 19 : 24),
      ),
    );
  }
}
