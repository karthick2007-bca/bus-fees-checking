import 'package:dec_02/services/api_service.dart';
import 'package:dec_02/models/student.dart';
import 'package:flutter/material.dart';

class StudentLoginView extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String phone, String dob) onLoginSuccess;
  final VoidCallback onRegister;
  final Function(String phone, String dob)? onCheckReport;

  const StudentLoginView({
    super.key,
    required this.onBack,
    required this.onLoginSuccess,
    required this.onRegister,
    this.onCheckReport,
  });

  @override
  State<StudentLoginView> createState() => _StudentLoginViewState();
}

class _StudentLoginViewState extends State<StudentLoginView> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isCheckingReport = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        final students = await ApiService.getStudents();
        final userId = _userIdController.text;
        final password = _passwordController.text;

        print('Login attempt - UserID: $userId, Password: $password');
        print('Total students in DB: ${students.length}');

        final found = students.firstWhere(
          (s) => s['phone'] == userId && s['dob']?.toString().split('T')[0] == password,
          orElse: () => {},
        );

        if (found.isNotEmpty) {
          widget.onLoginSuccess(userId, password);
        } else {
          setState(() {
            _errorMessage = 'Invalid user ID or password.';
          });
        }
      } catch (e) {
        print('Login error: $e');
        setState(() {
          _errorMessage = 'Error: $e';
        });
      }
      
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton(
                  onPressed: widget.onBack,
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'BACK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Student Access',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'View Your Transport Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'USER ID',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _userIdController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'User ID is required';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() => _errorMessage = null),
                  decoration: InputDecoration(
                    hintText: '9876543210',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'PASSWORD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'YYYY-MM-DD',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    suffixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.warning, size: 14, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Open Dashboard',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: (_isLoading || _isCheckingReport) ? null : _handleCheckReport,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isCheckingReport
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 18, color: Color(0xFF4F46E5)),
                            SizedBox(width: 8),
                            Text(
                              'Check My Report',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCheckReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCheckingReport = true;
        _errorMessage = null;
      });
      
      try {
        final students = await ApiService.getStudents();
        final userId = _userIdController.text;
        final password = _passwordController.text;

        final found = students.firstWhere(
          (s) => s['phone'] == userId && s['dob']?.toString().split('T')[0] == password,
          orElse: () => {},
        );

        if (found.isNotEmpty) {
          if (widget.onCheckReport != null) {
            widget.onCheckReport!(userId, password);
          }
        } else {
          setState(() {
            _errorMessage = 'Invalid user ID or password.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: $e';
        });
      }
      
      setState(() => _isCheckingReport = false);
    }
  }

  _createEmptyStudent() {
    // Return an empty student - this is just a placeholder
    return Student.fromMap({
      'id': '',
      'name': '',
      'rollNo': '',
      'address': '',
      'email': '',
      'phone': '',
      'parentName': '',
      'class': '',
      'dob': 0,
      'location': '',
      'amountPaid': 0,
      'totalDue': 0,
      'status': 'pending',
      'lastUpdated': 0,
      'payments': [],
      'routeHistory': [],
    });
  }
}

// Import the Student class properly
