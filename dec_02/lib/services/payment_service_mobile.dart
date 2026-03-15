// ignore_for_file: depend_on_referenced_packages
import 'dart:io' show Platform;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class PaymentServiceImpl {
  Razorpay? _razorpay;
  Function(dynamic)? _onSuccess;
  Function(dynamic)? _onFailure;

  void initialize({
    required Function(dynamic) onSuccess,
    required Function(dynamic) onFailure,
    required Function() onWallet,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    if (Platform.isAndroid || Platform.isIOS) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
        final res = response as PaymentSuccessResponse;
        _onSuccess?.call({
          'paymentId': res.paymentId,
          'orderId': res.orderId ?? '',
          'signature': res.signature ?? '',
        });
      });
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
        final res = response as PaymentFailureResponse;
        _onFailure?.call({'message': res.message});
      });
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) => onWallet());
    }
  }

  Future<void> openCheckout({
    required double amount,
    required String name,
    required String phone,
    required String email,
  }) async {
    var options = {
      'key': 'rzp_live_SNyLCysaEf0ooI',
      'amount': (amount * 100).toInt(),
      'name': 'Fee Payment',
      'description': 'Student Fee Payment',
      'prefill': {'contact': phone, },
      'theme': {'color': '#4F46E5'}
    };
    if (_razorpay != null && (Platform.isAndroid || Platform.isIOS)) {
      _razorpay!.open(options);
    } else {
      // Desktop (Windows/macOS/Linux) fallback: open hosted web checkout in browser
      final uri = Uri.parse('${ApiService.baseUrl}/pay').replace(queryParameters: {
        'amount': (amount * 100).toInt().toString(),
        'name': name,
        'phone': phone,
        'email': email,
      });
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        _onFailure?.call({'message': 'Unable to open payment page: $e'});
      }
    }
  }

  void dispose() {
    _razorpay?.clear();
  }
}
