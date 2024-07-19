part of 'payment_bloc.dart';

enum PaymentStatus { initial, loading, success, failure , deleted }

class PaymentState extends Equatable {
  final PaymentStatus status;
  final CardFieldInputDetails card;
  final Map<String, dynamic>? subscriptionResult;

  const PaymentState(
    {
      this.status = PaymentStatus.initial,
      this.card = const CardFieldInputDetails(complete: false),
      this.subscriptionResult,
    }
  );

  PaymentState copyWith(
    {
      PaymentStatus? status,
      CardFieldInputDetails? card,
      Map<String, dynamic>? subscriptionResult,
    }
  ) {
    return PaymentState(
      status: status ?? this.status,
      card: card ?? this.card,
      subscriptionResult: subscriptionResult ?? this.subscriptionResult,
    );
  }
  
  @override
  List<Object?> get props => [status, card, subscriptionResult];
}
