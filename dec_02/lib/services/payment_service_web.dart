library payment_service_web;

import 'dart:js' show JsObject, context;

class PaymentServiceImpl {
  Function(Map<String, dynamic>)? _onSuccess;
  Function(Map<String, dynamic>)? _onFailure;

  void initialize({
    required Function(dynamic) onSuccess,
    required Function(dynamic) onFailure,
    required Function() onWallet,
  }) {
    _onSuccess = (response) => onSuccess(response);
    _onFailure = (response) => onFailure(response);
  }

  void openCheckout({
    required double amount,
    required String name,
    required String phone,
    required String email,
  }) {
    final options = JsObject.jsify({
      'key': 'rzp_live_SNyLCysaEf0ooI',
      'amount': (amount * 100).toInt(),
      'name': 'Fee Payment',
      'description': 'Student Fee Payment',
      'prefill': {'contact': phone, 'email': email},
      'handler': (response) {
        _onSuccess?.call({
          'paymentId': response['razorpay_payment_id'] ?? '',
          'orderId': response['razorpay_order_id'] ?? '',
          'signature': response['razorpay_signature'] ?? '',
        });
      },
      'modal': {
        'ondismiss': () {
          _onFailure?.call({'message': 'Payment cancelled by user'});
        }
      },
      'theme': {'color': '#4F46E5'},
    });

    context.callMethod('openRazorpay', [options]);
  }

  void dispose() {}
}
