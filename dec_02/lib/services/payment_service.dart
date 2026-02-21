import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';

class PaymentService {
  late Razorpay _razorpay;

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function() onWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) => onSuccess(response as PaymentSuccessResponse));
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) => onFailure(response as PaymentFailureResponse));
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) => onWallet());
  }

  void openCheckout({
    required double amount,
    required String name,
    required String phone,
    required String email,
  }) {
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your Razorpay key
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
