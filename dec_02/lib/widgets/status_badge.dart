import 'package:flutter/material.dart';
import '../models/payment.dart';

class StatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Map<PaymentStatus, Map<String, dynamic>> config = {
      PaymentStatus.succeed: {
        'bg': Colors.green.shade50,
        'text': Colors.green.shade700,
        'border': Colors.green.shade100,
        'label': 'Succeed',
        'icon': Icons.check_circle,
      },
      PaymentStatus.pending: {
        'bg': Colors.amber.shade50,
        'text': Colors.amber.shade700,
        'border': Colors.amber.shade100,
        'label': 'Pending',
        'icon': Icons.access_time,
      },
      PaymentStatus.issues: {
        'bg': Colors.red.shade50,
        'text': Colors.red.shade700,
        'border': Colors.red.shade100,
        'label': 'Refund Process',
        'icon': Icons.warning,
      },
    };

    final style = config[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style['bg'] as Color,
        border: Border.all(color: style['border'] as Color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            style['icon'] as IconData,
            size: 12,
            color: style['text'] as Color,
          ),
          const SizedBox(width: 4),
          Text(
            style['label'] as String,
            style: TextStyle(
              color: style['text'] as Color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}