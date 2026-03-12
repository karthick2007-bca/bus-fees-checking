library payment_service_web;

import 'dart:js' show JsObject, context;
import 'dart:html' as html;

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

  bool _isMobile() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('android') || 
           userAgent.contains('iphone') || 
           userAgent.contains('ipad') || 
           userAgent.contains('mobile');
  }

  void openCheckout({
    required double amount,
    required String name,
    required String phone,
    required String email,
  }) {
    if (_isMobile()) {
      // For mobile, show alert and redirect to UPI or payment link
      html.window.alert('Mobile payment: Please use desktop browser or contact admin for UPI payment');
      _onFailure?.call({'message': 'Mobile browser not supported. Use desktop or UPI payment'});
      return;
    }

    final handler = (response) {
      _onSuccess?.call({
        'paymentId': response['razorpay_payment_id'],
        'orderId': response['razorpay_order_id'] ?? '',
        'signature': response['razorpay_signature'] ?? '',
      });
    };

    final ondismiss = () {
      _onFailure?.call({'message': 'Payment cancelled by user'});
    };

    final options = JsObject.jsify({
      'key': 'rzp_live_SNyLCysaEf0ooI',
      'amount': (amount * 100).toInt(),
      'name': 'Fee Payment',
      'description': 'Student Fee Payment',
      'prefill': {'contact': phone, 'email': email},
      'handler': handler,
      'modal': {'ondismiss': ondismiss},
      'theme': {'color': '#4F46E5'}
    });

    context.callMethod('openRazorpay', [options]);
  }

  void dispose() {}
}
