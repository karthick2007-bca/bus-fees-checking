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

    // Register Dart callbacks in JS context so JS can call them
    context['_dartPaymentSuccess'] = (dynamic paymentId, dynamic orderId, dynamic signature) {
      _onSuccess?.call({
        'paymentId': paymentId?.toString() ?? '',
        'orderId': orderId?.toString() ?? '',
        'signature': signature?.toString() ?? '',
      });
    };

    context['_dartPaymentDismiss'] = () {
      _onFailure?.call({'message': 'Payment cancelled by user'});
    };
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
      'currency': 'INR',
      'name': 'Fee Payment',
      'description': 'Student Bus Fee Payment',
      'prefill': {'contact': phone, 'email': email.isEmpty ? 'student@school.com' : email},
      'theme': {'color': '#4F46E5'},
    });

    context.callMethod('openRazorpay', [options]);
  }

  void dispose() {
    context['_dartPaymentSuccess'] = null;
    context['_dartPaymentDismiss'] = null;
  }
}
