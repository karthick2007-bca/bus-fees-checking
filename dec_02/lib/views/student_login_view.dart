import 'package:flutter/material.dart';
import '../services/api_service.dart';
// import '../models/student.dart'; // Uncomment if you need the Student model

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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        final students = await ApiService.getStudents();
        final userId = _userIdController.text.trim();
        final password = _passwordController.text.trim();

        print('Login attempt - UserID: $userId, Password: $password');
        print('Total students in DB: ${students.length}');

        // Find student by phone and dob
        final found = students.firstWhere(
          (s) => s['phone']?.toString() == userId && 
                 s['dob']?.toString().split('T')[0] == password,
          orElse: () => null,
        );

        if (found != null) {
          print('Login successful for: ${found['name']}');
          widget.onLoginSuccess(userId, password);
        } else {
          setState(() {
            _errorMessage = 'Invalid User ID or Password. Please try again.';
          });
        }
      } catch (e) {
        print('Login error: $e');
        setState(() {
          _errorMessage = 'Connection error. Please try again.';
        });
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCheckReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCheckingReport = true;
        _errorMessage = null;
      });
      
      try {
        final students = await ApiService.getStudents();
        final userId = _userIdController.text.trim();
        final password = _passwordController.text.trim();

        final found = students.firstWhere(
          (s) => s['phone']?.toString() == userId && 
                 s['dob']?.toString().split('T')[0] == password,
          orElse: () => null,
        );

        if (found != null) {
          if (widget.onCheckReport != null) {
            widget.onCheckReport!(userId, password);
          } else {
            // If onCheckReport is not provided, just do login
            widget.onLoginSuccess(userId, password);
          }
        } else {
          setState(() {
            _errorMessage = 'Invalid User ID or Password. Please try again.';
          });
        }
      } catch (e) {
        print('Check report error: $e');
        setState(() {
          _errorMessage = 'Connection error. Please try again.';
        });
      }
      
      if (mounted) {
        setState(() => _isCheckingReport = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            margin: const EdgeInsets.all(20),
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
                  // Back Button
                  TextButton(
                    onPressed: widget.onBack,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, size: 16, color: Color(0xFF94A3B8)),
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
                  
                  // Title
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
                  
                  // User ID Field
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
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'User ID is required';
                      }
                      if (value.length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() => _errorMessage = null),
                    decoration: InputDecoration(
                      hintText: 'Enter your phone number',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Password Field
                  const Text(
                    'PASSWORD (DOB)',
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
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      // Validate date format (YYYY-MM-DD)
                      final RegExp dateRegExp = RegExp(
                        r'^\d{4}-\d{2}-\d{2}$',
                      );
                      if (!dateRegExp.hasMatch(value)) {
                        return 'Use format: YYYY-MM-DD';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() => _errorMessage = null),
                    decoration: InputDecoration(
                      hintText: 'YYYY-MM-DD',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF94A3B8),
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                    ),
                  ),
                  
                  // Error Message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  // Login Button
                  ElevatedButton(
                    onPressed: (_isLoading || _isCheckingReport) ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size(double.infinity, 0),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
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
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Register Button
                  OutlinedButton(
                    onPressed: (_isLoading || _isCheckingReport) ? null : widget.onRegister,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: const Text(
                      'New Student? Register Here',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Check Report Button
                  TextButton(
                    onPressed: (_isLoading || _isCheckingReport) ? null : _handleCheckReport,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: _isCheckingReport
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4F46E5),
                            ),
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
      ),
    );
  }
}