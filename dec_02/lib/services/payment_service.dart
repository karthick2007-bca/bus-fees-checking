import 'package:flutter/foundation.dart' show kIsWeb;
import 'payment_service_mobile.dart' if (dart.library.html) 'payment_service_web.dart';

class PaymentService {
  final _impl = PaymentServiceImpl();

  void initialize({
    required Function(dynamic) onSuccess,
    required Function(dynamic) onFailure,
    required Function() onWallet,
  }) {
    _impl.initialize(
      onSuccess: onSuccess,
      onFailure: onFailure,
      onWallet: onWallet,
    );
  }

  void openCheckout({
    required double amount,
    required String name,
    required String phone,
    required String email,
  }) {
    _impl.openCheckout(
      amount: amount,
      name: name,
      phone: phone,
      email: email,
    );
  }

  void dispose() {
    _impl.dispose();
  }
}
