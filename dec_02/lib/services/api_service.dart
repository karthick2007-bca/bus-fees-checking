import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ Windows/Web-ku 'localhost' um, Android-ku '10.0.2.2' um auto-va switch aagum.
  static const String baseUrl = 'https://bus-fees-checking.vercel.app';

  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      };

  // --- 1. STUDENTS ---
  static Future<List<dynamic>> getStudents() async {
    try {
      final uri = Uri.parse('$baseUrl/api/students').replace(queryParameters: {
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      final response = await http.get(uri, headers: _headers).timeout(timeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Connection Failed: $e');
    }
  }

  static Future<void> addStudent(Map<String, dynamic> student) async {
    final response = await http.post(Uri.parse('$baseUrl/api/students'),
        headers: _headers, body: jsonEncode(student)).timeout(timeout);
    if (response.statusCode != 200 && response.statusCode != 201) throw Exception('Failed to add');
  }

  static Future<void> updateStudent(String phone, Map<String, dynamic> data) async {
    await http.put(Uri.parse('$baseUrl/api/students/$phone'),
        headers: _headers, body: jsonEncode(data)).timeout(timeout);
  }

  static Future<void> deleteStudent(String id) async {
    await http.delete(Uri.parse('$baseUrl/api/students/$id')).timeout(timeout);
  }

  static Future<void> deleteAllStudents() async {
    await http.delete(Uri.parse('$baseUrl/api/students')).timeout(timeout);
  }

  // --- 2. LOCATIONS ---
  static Future<List<dynamic>> getLocations() async {
    final response = await http.get(Uri.parse('$baseUrl/api/locations'), headers: _headers).timeout(timeout);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error: ${response.statusCode}');
  }

  static Future<void> addLocation(Map<String, dynamic> location) async {
    await http.post(Uri.parse('$baseUrl/api/locations'), headers: _headers, body: jsonEncode(location)).timeout(timeout);
  }

  static Future<void> updateLocation(String id, String name, double fee) async {
    await http.put(Uri.parse('$baseUrl/api/locations/$id'),
        headers: _headers, body: jsonEncode({'name': name, 'fee': fee})).timeout(timeout);
  }

  static Future<void> deleteLocation(String id) async {
    await http.delete(Uri.parse('$baseUrl/api/locations/$id')).timeout(timeout);
  }

  // --- 3. REPORTS (Fixed 'Member not found' error) ---
  static Future<void> saveReport(Map<String, dynamic> reportData) async {
    final response = await http.post(Uri.parse('$baseUrl/api/reports'), 
        headers: _headers, body: jsonEncode(reportData)).timeout(timeout);
    if (response.statusCode != 200 && response.statusCode != 201) throw Exception('Failed to save report');
  }

  static Future<List<dynamic>> getReports() async {
    final response = await http.get(Uri.parse('$baseUrl/api/reports')).timeout(timeout);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load reports');
  }

  // --- 4. TRANSACTIONS ---
  static Future<void> saveTransaction(Map<String, dynamic> transaction) async {
    await http.post(Uri.parse('$baseUrl/api/transactions'), headers: _headers, body: jsonEncode(transaction)).timeout(timeout);
  }

  static Future<List<dynamic>> getTransactions() async {
    final response = await http.get(Uri.parse('$baseUrl/api/transactions')).timeout(timeout);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load transactions');
  }

  // --- 5. NOTIFICATIONS (Fixed 'Member not found' error) ---
  static Future<List<dynamic>> getNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/api/notifications')).timeout(timeout);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load notifications');
  }

  static Future<void> markNotificationRead(String id) async {
    await http.put(Uri.parse('$baseUrl/api/notifications/$id')).timeout(timeout);
  }

  static Future<void> deleteNotification(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/notifications/$id')).timeout(timeout);
    if (response.statusCode != 200) throw Exception('Failed to delete notification');
  }

  // --- 6. RECYCLE BIN ---
  static Future<List<dynamic>> getRecycleBin() async {
    final response = await http.get(Uri.parse('$baseUrl/api/recyclebin')).timeout(timeout);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load recycle bin');
  }

  static Future<void> restoreFromRecycleBin(String id) async {
    await http.post(Uri.parse('$baseUrl/api/recyclebin/restore/$id')).timeout(timeout);
  }

  static Future<void> permanentlyDelete(String id) async {
    await http.delete(Uri.parse('$baseUrl/api/recyclebin/$id')).timeout(timeout);
  }
  
  // --- 7. AUTH (Add logic if needed) ---
  static Future<dynamic> loginStudent(String userId, String password) async {
    // Implement login logic here
  }
}