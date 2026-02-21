import 'package:flutter/material.dart';

enum PaymentStatus { pending, succeed, issues }

class PaymentRecord {
  final String id;
  final String studentId;
  final String studentName;
  final DateTime date;
  final double amount;
  final PaymentStatus status;

  PaymentRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.amount,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'date': date.millisecondsSinceEpoch,
      'amount': amount,
      'status': status.toString().split('.').last,
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'],
      studentId: map['studentId'],
      studentName: map['studentName'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      amount: (map['amount'] as num).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
      ),
    );
  }
}