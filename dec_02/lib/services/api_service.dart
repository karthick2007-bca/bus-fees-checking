import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_service.dart';

class ApiService {
  static const String baseUrl = 'https://bus-fees-checking.vercel.app';
  static const Duration timeout = Duration(seconds: 60);
  
  static Future<List<dynamic>> getStudents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/students'),
      ).timeout(timeout);
      if (response.statusCode == 200) {
        final students = jsonDecode(response.body);
        for (var student in students) {
          await DatabaseService.insertStudent(student);
        }
        return students;
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      print('getStudents error: $e, loading from local DB');
      return await DatabaseService.getStudents();
    }
  }
  
  static Future<void> addStudent(Map<String, dynamic> student) async {
    await DatabaseService.insertStudent(student);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/students'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(student),
      ).timeout(timeout);
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('addStudent error: $e, saved locally');
    }
  }
  
  static Future<List<dynamic>> getLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/locations'),
      ).timeout(timeout);
      if (response.statusCode == 200) {
        final locations = jsonDecode(response.body);
        for (var location in locations) {
          await DatabaseService.insertLocation(location);
        }
        return locations;
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      print('getLocations error: $e, loading from local DB');
      return await DatabaseService.getLocations();
    }
  }
  
  static Future<void> addLocation(Map<String, dynamic> location) async {
    await DatabaseService.insertLocation(location);
    try {
      await http.post(
        Uri.parse('$baseUrl/api/locations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(location),
      ).timeout(timeout);
    } catch (e) {
      print('addLocation error: $e, saved locally');
    }
  }
  
  static Future<void> deleteLocation(String id) async {
    await http.delete(Uri.parse('$baseUrl/api/locations/$id'));
  }
  
  static Future<void> deleteStudent(String id) async {
    await http.delete(Uri.parse('$baseUrl/api/students/$id'));
  }
  
  static Future<void> deleteAllStudents() async {
    await http.delete(Uri.parse('$baseUrl/api/students'));
  }
   
  static Future<void> saveReport(Map<String, dynamic> reportData) async {
    await http.post(
      Uri.parse('$baseUrl/api/reports'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(reportData),
    );
  }
   
  static Future<List<dynamic>> getReports() async {
    final response = await http.get(Uri.parse('$baseUrl/api/reports'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load reports');
  }

  static Future<List<dynamic>> getRecycleBin() async {
    final response = await http.get(Uri.parse('$baseUrl/api/recyclebin'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load recycle bin');
  }

  static Future<void> restoreFromRecycleBin(String id) async {
    await http.post(Uri.parse('$baseUrl/api/recyclebin/restore/$id'));
  }

  static Future<void> permanentlyDelete(String id) async {
    await http.delete(Uri.parse('$baseUrl/api/recyclebin/$id'));
  }

  static Future<void> saveTransaction(Map<String, dynamic> transaction) async {
    await DatabaseService.insertTransaction(transaction);
    try {
      await http.post(
        Uri.parse('$baseUrl/api/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transaction),
      );
    } catch (e) {
      print('saveTransaction error: $e, saved locally');
    }
  }

  static Future<List<dynamic>> getTransactions() async {
    final response = await http.get(Uri.parse('$baseUrl/api/transactions'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load transactions');
  }

  static Future<List<dynamic>> getNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/api/notifications'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load notifications');
  }

  static Future<void> markNotificationRead(String id) async {
    await http.put(Uri.parse('$baseUrl/api/notifications/$id'));
  }

  static Future<void> deleteNotification(String id) async {
    await http.delete(Uri.parse('$baseUrl/api/notifications/$id'));
  }

  static Future<void> updateStudent(String phone, Map<String, dynamic> data) async {
    await DatabaseService.updateStudent(phone, data);
    try {
      await http.put(
        Uri.parse('$baseUrl/api/students/$phone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
    } catch (e) {
      print('updateStudent error: $e, updated locally');
    }
  }
}
