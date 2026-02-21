import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../models/admin.dart';
import '../models/location.dart';
import '../models/payment.dart';

class DataStorage {
  static const String studentKey = 'transit_pay_db_students_v4';
  static const String adminKey = 'transit_pay_db_admins_v4';
  static const String routeKey = 'transit_pay_db_routes_v4';

  static final List<Route> initialRoutes = [
    Route(id: '1', name: 'Aruppukottai', fee: 30000),
    Route(id: '2', name: 'Madurai', fee: 40000),
    Route(id: '3', name: 'Virudhunagar', fee: 25000),
    Route(id: '4', name: 'Sattur', fee: 20000),
    Route(id: '5', name: 'Kovilpatti', fee: 28000),
  ];

  static final List<AdminUser> defaultAdmins = [
    AdminUser(id: 'ADM-1', username: 'admin', role: AdminRole.superAdmin),
  
  ];

  static Future<List<Student>> loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(studentKey);
    if (data != null) {
      final list = json.decode(data) as List;
      return list.map((item) => Student.fromMap(item)).toList();
    }
    return [];
  }

  static Future<List<AdminUser>> loadAdmins() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(adminKey);
    if (data != null) {
      final list = json.decode(data) as List;
      return list.map((item) => AdminUser.fromMap(item)).toList();
    }
    return defaultAdmins;
  }

  static Future<List<Route>> loadRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(routeKey);
    if (data != null) {
      final list = json.decode(data) as List;
      return list.map((item) => Route.fromMap(item)).toList();
    }
    return initialRoutes;
  }

  static Future<void> saveStudents(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(students.map((s) => s.toMap()).toList());
    await prefs.setString(studentKey, data);
  }

  static Future<void> saveAdmins(List<AdminUser> admins) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(admins.map((a) => a.toMap()).toList());
    await prefs.setString(adminKey, data);
  }

  static Future<void> saveRoutes(List<Route> routes) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(routes.map((r) => r.toMap()).toList());
    await prefs.setString(routeKey, data);
  }

}