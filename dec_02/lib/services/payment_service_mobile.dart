import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentServiceImpl {
  late Razorpay _razorpay;
  Function(dynamic)? _onSuccess;
  Function(dynamic)? _onFailure;

  void initialize({
    required Function(dynamic) onSuccess,
    required Function(dynamic) onFailure,
    required Function() onWallet,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
      final res = response as PaymentSuccessResponse;
      _onSuccess?.call({
        'paymentId': res.paymentId,
        'orderId': res.orderId ?? '',
        'signature': res.signature ?? '',
      });
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      final res = response as PaymentFailureResponse;
      _onFailure?.call({'message': res.message});
    });
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) => onWallet());
  }

  void openCheckout({
    required double amount,
    required String name,
    required String phone,
    required String email,
  }) {
    var options = {
      'key': 'rzp_live_SNyLCysaEf0ooI',
      'amount': (amount * 100).toInt(),
      'name': 'Fee Payment',
      'description': 'Student Fee Payment',
      'prefill': {'contact': phone, 'email': email},
      'theme': {'color': '#4F46E5'}
    };
    _razorpay.open(options);
  }

  void dispose() {
    _razorpay.clear();
  }
}
