import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:wavefinder/config/credit_card.dart';
import 'package:wavefinder/config/database_helper.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  /// Creates a [PaymentBloc].
  PaymentBloc() : super(const PaymentState()) {
    on<PaymentStart>(_onPaymentStart);
    on<PaymentCreateIntent>(_onPaymentCreateIntent);
    on<PaymentConfirmIntent>(_onPaymentConfirmIntent);
    on<PaymentCancelSubscription>(_onPaymentCancelSubscription);
  }

  void _onPaymentStart(
    PaymentStart event,
    Emitter<PaymentState> emit,
  ) {
    emit(state.copyWith(status: PaymentStatus.initial));
  }


  void _onPaymentCancelSubscription(
    PaymentCancelSubscription event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(status: PaymentStatus.loading)); // Enter loading state

    try {
      await _callCancelSubscriptionEndpoint(
        subscriptionId: event.subscriptionId,
      );
      print('Canceled');
      emit(state.copyWith(status: PaymentStatus.deleted));
    } catch (e) {
      // Handle any errors that occur during subscription cancellation
      print('Error cancelling subscription: $e');
      emit(state.copyWith(status: PaymentStatus.failure));
    }
  }

  void _onPaymentCreateIntent(
    PaymentCreateIntent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(status: PaymentStatus.loading));

  try {
      final paymentMehotdParam = PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(billingDetails: event.billing)
      );
      final paymentMehtod = await Stripe.instance.createPaymentMethod(
        params: paymentMehotdParam,
      );

      final paymentIntentResult = await _callPayEndpointMethodId(
        useStripeSdk: true,
        paymentMethodId: paymentMehtod.id,
        email: event.billing.email!,
      );
   
      if(paymentIntentResult['error']!= null) {
        print('ERROR');
        emit(state.copyWith(status: PaymentStatus.failure));
      }

      if(paymentIntentResult['clientSecret']!= null && paymentIntentResult['requireAction'] == null ) {
        CreditCard? userCard = await DBHelper().getUserCard(event.billing.email!);
        print(userCard?.subscriptionId);
        final subscriptionResult = await _createSubscription(
            customerId: paymentIntentResult['customer'],
            paymentMethodId: paymentMehtod.id,
            subscriptionId: userCard?.subscriptionId,
          );
        print(subscriptionResult);
        emit(state.copyWith(status: PaymentStatus.success, subscriptionResult: subscriptionResult));
      }

      // extra step to confirm the transaction
      if(paymentIntentResult['clientSecret']!= null && paymentIntentResult['requireAction'] == true ) {
        final String clientSecret = paymentIntentResult['clientSecret'];

        add(PaymentConfirmIntent(clientSecret: clientSecret, params: paymentMehotdParam));
      }
    } catch (e) {
    if (e is StripeException) {
      // Handle the invalid expiry year error
      print('The expiry year of your card is invalid. Please enter a valid expiry year.');
      emit(state.copyWith(status: PaymentStatus.failure));
    } else {
      // Handle other errors
      print(e.toString());
      emit(state.copyWith(status: PaymentStatus.failure));
    }
  }
  }

  /// Handles the [PaymentConfirmIntent] event.
  ///
  /// Confirms the payment intent.
  void _onPaymentConfirmIntent(
    PaymentConfirmIntent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final paymentIntent = await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: event.clientSecret,
        params: event.params,
      );
        print('paymentIntent'); 
        print(paymentIntent); 

      if (paymentIntent.status == 'Succeeded') {
        emit(state.copyWith(status: PaymentStatus.success));
      } else {
        print('SUCCES'); 
        emit(state.copyWith(status: PaymentStatus.failure));
      }
    } catch (e) {
      print(e);
      emit(state.copyWith(status: PaymentStatus.failure));
    }
  }
}

Future<Map<String, dynamic>>_callPayEndpointIntentId(
  {
    required String paymentIntentId,
  }
) async {
  final url = Uri.parse(
    'https://us-central1-wavefinder-417017.cloudfunctions.net/StripePayEndPointIntentId'
  );

  final response = await http.post(
    url,
    headers: {'Content-type': 'application/json'} ,
    body: json.encode(
      {
        'paymentIntentId': paymentIntentId,
      }
    )
  );
  print(response);
  if (response.statusCode == 200) {
    // If the server returns a 200 OK response, parse the JSON.
    return json.decode(response.body);
  } else {
    // If the server returns an unexpected response, throw an exception.
    throw Exception('Unexpected response from the server: ${response.statusCode}');
  }
} 

Future<Map<String, dynamic>> _callPayEndpointMethodId({
  required bool useStripeSdk,
  required String paymentMethodId,
  required String email,
}) async {
  final url = Uri.parse(
    'https://us-central1-wavefinder-417017.cloudfunctions.net/StripePayEndPointMethodId',
  );
  final response = await http.post(
    url,
    headers: {'Content-type': 'application/json'},
    body: json.encode({
      'useStripeSdk': useStripeSdk,
      'paymentMethodId': paymentMethodId,
      'userEmail': email,
    }),
  );
  print('Response Intend: ${response.body}');
  if (response.statusCode == 200) {
    // If the server returns a 200 OK response, parse the JSON.
    try {
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to decode JSON response');
    }
  } else {
    // If the server returns an unexpected response, throw an exception.
    throw Exception('Unexpected response from the server: ${response.statusCode}');
  }
}

Future<Map<String, dynamic>> _createSubscription({
  required String customerId,
  required String paymentMethodId,
  required String? subscriptionId,
}) async {
  final url = Uri.parse(
    'https://us-central1-wavefinder-417017.cloudfunctions.net/createSubscription'
  );

  final response = await http.post(
    url,
    headers: {'Content-type': 'application/json'},
    body: json.encode({
      'customerId': customerId,
      'paymentMethodId': paymentMethodId,
      'subscriptionId': subscriptionId,
    }),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Unexpected response from the server: ${response.statusCode}');
  }
}

Future<Map<String, dynamic>> _callCancelSubscriptionEndpoint({
  required String subscriptionId,
}) async {
  final url = Uri.parse('https://us-central1-wavefinder-417017.cloudfunctions.net/cancelSubscription');

  final response = await http.post(
    url,
    headers: {'Content-type': 'application/json'},
    body: json.encode({
      'subscriptionId': subscriptionId,
    }),
  );

  if (response.statusCode == 200) {
    print(json.decode(response.body));
    return json.decode(response.body);
  } else {
    throw Exception('Unexpected response from the server: ${response.statusCode}');
  }
}
