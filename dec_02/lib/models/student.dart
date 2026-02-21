import 'package:dec_02/models/payment.dart';

class Student {
  final String id;
  String name;
  final String rollNo;
  String address;
  String email;
  String phone;
  String parentName;
  String studentClass;
  String dob;

  String location; // ✅ route removed
  double amountPaid;
  double totalDue;

  PaymentStatus status;
  DateTime lastUpdated;
  List<PaymentRecord> payments;
  List<LocationHistoryEntry> locationHistory;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.address,
    required this.email,
    required this.phone,
    required this.parentName,
    required this.studentClass,
    required this.dob,
    required this.location,
    required this.amountPaid,
    required this.totalDue,
    required this.status,
    required this.lastUpdated,
    required this.payments,
    required this.locationHistory,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rollNo': rollNo,
      'address': address,
      'email': email,
      'phone': phone,
      'parentName': parentName,
      'studentClass': studentClass,
      'dob': dob,
      'location': location,
      'amountPaid': amountPaid,
      'totalDue': totalDue,
      'status': status.toString().split('.').last,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'payments': payments.map((p) => p.toMap()).toList(),
      'locationHistory': locationHistory.map((l) => l.toMap()).toList(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      rollNo: map['rollNo'],
      address: map['address'],
      email: map['email'],
      phone: map['phone'],
      parentName: map['parentName'],
      studentClass: map['studentClass'],
      dob: map['dob'].toString(),
      location: map['location'],
      amountPaid: (map['amountPaid'] as num).toDouble(),
      totalDue: (map['totalDue'] as num).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
      ),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']),
      payments: List<PaymentRecord>.from(
        (map['payments'] as List).map((p) => PaymentRecord.fromMap(p)),
      ),
      locationHistory: List<LocationHistoryEntry>.from(
        (map['locationHistory'] as List).map((l) => LocationHistoryEntry.fromMap(l)),
      ),
    );
  }
}

class LocationHistoryEntry {
  final String routeName;
  final double fee;
  final DateTime date;

  LocationHistoryEntry({
    required this.routeName,
    required this.fee,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'routeName': routeName,
      'fee': fee,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory LocationHistoryEntry.fromMap(Map<String, dynamic> map) {
    return LocationHistoryEntry(
      routeName: map['routeName'],
      fee: (map['fee'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }
}
