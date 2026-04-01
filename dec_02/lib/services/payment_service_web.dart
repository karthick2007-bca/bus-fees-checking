// ignore: avoid_web_libraries_in_flutter
library payment_service_web;

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' show allowInterop;

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
    // Store callbacks in JS context so they can be called from JS
    js.context['_flutterPaymentSuccess'] = allowInterop((paymentId, orderId, signature) {
      _onSuccess?.call({
        'paymentId': paymentId?.toString() ?? '',
        'orderId': orderId?.toString() ?? '',
        'signature': signature?.toString() ?? '',
      });
    });

    js.context['_flutterPaymentDismiss'] = allowInterop(() {
      _onFailure?.call({'message': 'Payment cancelled by user'});
    });

    final options = js.JsObject.jsify({
      'key': 'rzp_live_SNyLCysaEf0ooI',
      'amount': (amount * 100).toInt(),
      'name': 'Fee Payment',
      'description': 'Student Fee Payment',
      'prefill': {'contact': phone, 'email': email},
      'theme': {'color': '#4F46E5'},
    });

    js.context.callMethod('openRazorpayCheckout', [options]);
  }

  void dispose() {}
}
