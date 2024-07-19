part of 'payment_bloc.dart';

/// Base class for all payment events in the PaymentBloc.
class PaymentEvent extends Equatable {
  /// Constructs a [PaymentEvent].
  const PaymentEvent();

  @override
  List<Object> get props => [];
}

/// Event to start the payment process.
class PaymentStart extends PaymentEvent {}

/// Event to create a payment intent with the provided billing details.
class PaymentCreateIntent extends PaymentEvent {
  /// The billing details required to create the payment intent.
  final BillingDetails billing;

  /// Constructs a [PaymentCreateIntent] with the given [billing] details.
  const PaymentCreateIntent(this.billing);

  @override
  List<Object> get props => [billing];
}

/// Event to confirm a payment intent with the provided client secret and payment method parameters.
class PaymentConfirmIntent extends PaymentEvent {
  /// The client secret required to confirm the payment intent.
  final String clientSecret;

  /// The payment method parameters required to confirm the payment intent.
  final PaymentMethodParams params;

  /// Constructs a [PaymentConfirmIntent] with the given [clientSecret] and [params].
  const PaymentConfirmIntent({
    required this.clientSecret,
    required this.params,
  });

  @override
  List<Object> get props => [clientSecret, params];
}

/// Event to cancel a subscription with the given subscription ID.
class PaymentCancelSubscription extends PaymentEvent {
  /// The ID of the subscription to be canceled.
  final String subscriptionId;

  /// Constructs a [PaymentCancelSubscription] with the given [subscriptionId].
  const PaymentCancelSubscription({required this.subscriptionId});

  @override
  List<Object> get props => [subscriptionId];
}
