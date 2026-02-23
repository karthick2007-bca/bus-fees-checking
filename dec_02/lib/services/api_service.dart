import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.66.131.187'; // Replace with your actual IP
  
  static Future<List<dynamic>> getStudents() async {
    final response = await http.get(Uri.parse('$baseUrl/students'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load students');
  }
  
  static Future<void> addStudent(Map<String, dynamic> student) async {
    await http.post(
      Uri.parse('$baseUrl/students'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(student),
    );
  }
  
  static Future<List<dynamic>> getLocations() async {
    final response = await http.get(Uri.parse('$baseUrl/locations'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load locations');
  }
  
  static Future<void> addLocation(Map<String, dynamic> location) async {
    await http.post(
      Uri.parse('$baseUrl/locations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(location),
    );
  }
  
  static Future<void> deleteLocation(String id) async {
    await http.delete(Uri.parse('$baseUrl/locations/$id'));
  }
  
  static Future<void> deleteStudent(String id) async {
    await http.delete(Uri.parse('$baseUrl/students/$id'));
  }
  
  static Future<void> deleteAllStudents() async {
    await http.delete(Uri.parse('$baseUrl/students'));
  }

  static Future<void> saveReport(Map<String, dynamic> reportData) async {
    await http.post(
      Uri.parse('$baseUrl/reports'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(reportData),
    );
  }

  static Future<List<dynamic>> getReports() async {
    final response = await http.get(Uri.parse('$baseUrl/reports'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load reports');
  }

  static Future<List<dynamic>> getRecycleBin() async {
    final response = await http.get(Uri.parse('$baseUrl/recyclebin'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load recycle bin');
  }

  static Future<void> restoreFromRecycleBin(String id) async {
    await http.post(Uri.parse('$baseUrl/recyclebin/restore/$id'));
  }

  static Future<void> permanentlyDelete(String id) async {
    await http.delete(Uri.parse('$baseUrl/recyclebin/$id'));
  }

  static Future<void> saveTransaction(Map<String, dynamic> transaction) async {
    await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transaction),
    );
  }

  static Future<List<dynamic>> getTransactions() async {
    final response = await http.get(Uri.parse('$baseUrl/transactions'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load transactions');
  }
}
