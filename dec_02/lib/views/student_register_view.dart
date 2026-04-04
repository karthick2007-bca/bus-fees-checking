import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../models/location.dart' as location_model;
import 'student_report.dart';
import 'edit_report_page.dart';
import 'student_login_view.dart';

class StudentRegisterView extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onBack;
  final VoidCallback onRegisterSuccess;

  const StudentRegisterView({
    super.key,
    required this.onSuccess,
    required this.onBack,
    required this.onRegisterSuccess,
  });

  @override
  State<StudentRegisterView> createState() => _StudentRegisterViewState();
}

class _StudentRegisterViewState extends State<StudentRegisterView> {
  final _formKey = GlobalKey<FormState>();
  final PaymentService _paymentService = PaymentService();
  bool _isFrameOpen = false;
  String? _frameError;
  bool _isLoadingRoutes = false;
  bool _isLoading = false;
  bool _isSessionValid = true;

  // Text Controllers
  final nameCtrl = TextEditingController();
  final rollCtrl = TextEditingController();
  final classCtrl = TextEditingController();
  final parentCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final amountCtrl = TextEditingController();

  List<location_model.Route> routes = [];
  location_model.Route? selectedRoute;
  
  // Store current logged in user
  String? _currentLoggedInPhone;
  String? _currentLoggedInDob;
  Map<String, dynamic>? _currentStudentData;

  @override
  void initState() {
    super.initState();
    
    // Clear all form fields when opening a new registration form
    _clearFormFields();
    
    amountCtrl.clear();
    
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onWallet: () => print('Wallet selected'),
    );
    
    // Load routes and validate session
    _initializeView();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    nameCtrl.dispose();
    rollCtrl.dispose();
    classCtrl.dispose();
    parentCtrl.dispose();
    addressCtrl.dispose();
    phoneCtrl.dispose();
    dobCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  // Initialize view with session validation
  Future<void> _initializeView() async {
    await _validateSession();
    if (_isSessionValid) {
      await loadRoutes();
      await _loadLoggedInStudent();
    }
  }

  // Validate current session
  Future<void> _validateSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLoggedInPhone = prefs.getString('loggedInPhone');
      _currentLoggedInDob = prefs.getString('loggedInDob');

      print('Validating session - Phone: $_currentLoggedInPhone, DOB: $_currentLoggedInDob');

      if (_currentLoggedInPhone == null || _currentLoggedInDob == null) {
        print('No valid session found');
        setState(() {
          _isSessionValid = false;
        });
        _showSessionExpiredDialog();
      }
    } catch (e) {
      print('Error validating session: $e');
      setState(() {
        _isSessionValid = false;
      });
    }
  }

  // Clear all form fields
  void _clearFormFields() {
    nameCtrl.clear();
    rollCtrl.clear();
    classCtrl.clear();
    parentCtrl.clear();
    addressCtrl.clear();
    phoneCtrl.clear();
    dobCtrl.clear();
    amountCtrl.clear();
    setState(() {
      selectedRoute = null;
      _currentStudentData = null;
    });
  }

  // Load ONLY logged-in student data
  Future<void> _loadLoggedInStudent() async {
    if (!_isSessionValid) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('Loading logged-in student: $_currentLoggedInPhone');

      // Fetch all students (ApiService.getStudents() already has cache busting)
      final students = await ApiService.getStudents();
      
      // Find the specific logged-in student
      final loggedInStudent = students.firstWhere(
        (s) {
          final studentPhone = s['phone']?.toString();
          final studentDob = s['dob']?.toString().split('T')[0];
          return studentPhone == _currentLoggedInPhone && 
                 studentDob == _currentLoggedInDob;
        },
        orElse: () => null,
      );

      if (loggedInStudent != null) {
        print('Found logged-in student: ${loggedInStudent['name']}');
        
        setState(() {
          _currentStudentData = Map<String, dynamic>.from(loggedInStudent);
          phoneCtrl.text = loggedInStudent['phone']?.toString() ?? '';
          dobCtrl.text = loggedInStudent['dob']?.toString().split('T')[0] ?? '';
          nameCtrl.text = loggedInStudent['name']?.toString() ?? '';
          rollCtrl.text = loggedInStudent['rollNo']?.toString() ?? '';
          classCtrl.text = loggedInStudent['studentClass']?.toString() ?? '';
          parentCtrl.text = loggedInStudent['parentName']?.toString() ?? '';
          addressCtrl.text = loggedInStudent['address']?.toString() ?? '';
          
          if (loggedInStudent['location'] != null && routes.isNotEmpty) {
            final matches = routes.where((r) => r.name == loggedInStudent['location']).toList();
            if (matches.isNotEmpty) {
              selectedRoute = matches.first;
              amountCtrl.text = selectedRoute!.fee.toString();
            } else {
              selectedRoute = null;
              amountCtrl.clear();
            }
          }
        });
      } else {
        print('Logged-in student not found in database');
        // Only show not found if truly not in DB - don't block if name is empty
        _showUserNotFoundDialog();
      }
    } catch (e) {
      print('Error loading logged-in student: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading student data: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Load routes/locations
  Future<void> loadRoutes() async {
    setState(() {
      _isLoadingRoutes = true;
      _frameError = null;
    });
    
    try {
      final data = await ApiService.getLocations();
      print('Loaded locations: $data');
      
      setState(() {
        routes = data.map((loc) => location_model.Route(
          id: loc['id']?.toString() ?? '',
          name: loc['name']?.toString() ?? '',
          fee: (loc['fee'] as num?)?.toDouble() ?? 0.0,
        )).toList();
        _isLoadingRoutes = false;
      });
      
      print('Routes count: ${routes.length}');
      
    } catch (e) {
      print("Error loading routes: $e");
      setState(() {
        _frameError = e.toString();
        _isLoadingRoutes = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading locations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle payment success
  void _handlePaymentSuccess(dynamic response) async {
    try {
      if (!await _verifySession()) {
        _showSessionExpiredDialog();
        return;
      }

      // Capture all form values BEFORE _saveStudent() clears the form
      final capturedName = nameCtrl.text;
      final capturedRoll = rollCtrl.text;
      final capturedClass = classCtrl.text;
      final capturedParent = parentCtrl.text;
      final capturedAddress = addressCtrl.text;
      final capturedPhone = _currentLoggedInPhone;
      final capturedDob = _currentLoggedInDob;
      final capturedLocation = selectedRoute?.name ?? '';
      final capturedAmount = selectedRoute?.fee ?? 0;

      await _saveStudent(fromPayment: true);

      final paymentId = response['paymentId']?.toString() ?? '';
      final now = DateTime.now().toIso8601String();

      // Save transaction
      await ApiService.saveTransaction({
        'paymentId': paymentId,
        'orderId': response['orderId']?.toString() ?? '',
        'studentId': capturedPhone,
        'studentName': capturedName,
        'phone': capturedPhone,
        'rollNo': capturedRoll,
        'amount': capturedAmount,
        'status': 'success',
        'timestamp': now,
      });

      // Auto-generate report based on student details after payment
      await ApiService.saveReport({
        'phone': capturedPhone,
        'name': capturedName,
        'rollNo': capturedRoll,
        'studentClass': capturedClass,
        'parentName': capturedParent,
        'address': capturedAddress,
        'location': capturedLocation,
        'dob': capturedDob,
        'totalDue': 0,
        'amountPaid': capturedAmount,
        'status': 'succeed',
        'paymentId': paymentId,
        'paymentDate': now,
        'generatedAt': now,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment Successful! Report generated ✅'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to report page with all captured data
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => StudentReport(
            phone: capturedPhone!,
            dob: capturedDob!,
            onLogout: () => _logout(),
            initialData: {
              'name': capturedName,
              'rollNo': capturedRoll,
              'studentClass': capturedClass,
              'parentName': capturedParent,
              'address': capturedAddress,
              'phone': capturedPhone,
              'dob': capturedDob,
              'location': capturedLocation,
              'amountPaid': capturedAmount,
              'totalDue': 0,
              'status': 'succeed',
              'paymentId': paymentId,
              'paymentDate': now,
            },
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      print('Error in payment success handler: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle payment failure
  void _handlePaymentFailure(dynamic response) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response['message'] ?? 'Unknown error'}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Save/Update student
  Future<void> _saveStudent({bool fromPayment = false}) async {
    try {
      if (!await _verifySession()) {
        throw Exception('Session invalid');
      }
      
      final students = await ApiService.getStudents();
      
      final existingStudent = students.firstWhere(
        (s) => s['phone']?.toString() == _currentLoggedInPhone && 
               s['dob']?.toString().split('T')[0] == _currentLoggedInDob,
        orElse: () => null,
      );

      final studentData = {
        'id': existingStudent?['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'name': nameCtrl.text,
        'rollNo': rollCtrl.text,
        'studentClass': classCtrl.text,
        'parentName': parentCtrl.text,
        'location': selectedRoute?.name ?? '',
        'totalDue': 0,
        'amountPaid': selectedRoute?.fee ?? 0,
        'status': 'succeed',
        'address': addressCtrl.text,
        'phone': _currentLoggedInPhone,
        'dob': _currentLoggedInDob,
        'registrationDate': existingStudent?['registrationDate'] ?? DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'payments': existingStudent?['payments'] ?? [],
        'locationHistory': existingStudent?['locationHistory'] ?? [],
      };

      await ApiService.addStudent(studentData);

      // Only clear form and call callbacks if NOT triggered from payment
      if (!fromPayment && mounted) {
        _clearFormFields();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student Registered Successfully ✅'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
        widget.onRegisterSuccess();
      }
    } catch (e) {
      print("Error saving student: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving student: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Verify current session
  Future<bool> _verifySession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPhone = prefs.getString('loggedInPhone');
      final currentDob = prefs.getString('loggedInDob');
      
      final isValid = currentPhone == _currentLoggedInPhone && 
             currentDob == _currentLoggedInDob &&
             currentPhone != null;
      
      print('Session verification: $isValid');
      return isValid;
    } catch (e) {
      print('Error verifying session: $e');
      return false;
    }
  }

  // Clear logged-in user
  Future<void> _clearLoggedInUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('loggedInPhone');
      await prefs.remove('loggedInDob');
      
      setState(() {
        _currentLoggedInPhone = null;
        _currentLoggedInDob = null;
        _isSessionValid = false;
        _currentStudentData = null;
      });
      
      print('Logged-in user cleared');
    } catch (e) {
      print('Error clearing logged-in user: $e');
    }
  }

  // Navigate to login page
  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => StudentLoginView(
          onBack: () {
            // Handle back navigation - go back to previous screen
            Navigator.pop(context);
          },
          onLoginSuccess: (phone, dob) {
            // After successful login, navigate back to this view
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentRegisterView(
                  onSuccess: widget.onSuccess,
                  onBack: widget.onBack,
                  onRegisterSuccess: widget.onRegisterSuccess,
                ),
              ),
            );
          },
          onRegister: () {
            // If register is pressed, they're already here
            // So just stay on this page
            print('Already on register page');
          },
        ),
      ),
      (route) => false, // This removes all previous routes
    );
  }

  // Logout user
  Future<void> _logout() async {
    await _clearLoggedInUser();
    
    if (mounted) {
      _navigateToLogin();
    }
  }

  // Show session expired dialog
  void _showSessionExpiredDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Session Expired'),
          content: const Text('Your session has expired. Please login again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show user not found dialog
  void _showUserNotFoundDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('User Not Found'),
          content: const Text('Your account could not be found. Please contact support or login again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text('Login Again'),
            ),
          ],
        );
      },
    );
  }

  // Submit payment
  Future<void> submit() async {
    // Verify session before proceeding
    if (!await _verifySession()) {
      _showSessionExpiredDialog();
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;

    if (selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Verify that form data matches session
    if (phoneCtrl.text != _currentLoggedInPhone || 
        dobCtrl.text != _currentLoggedInDob) {
      
      print('Data mismatch! Form phone: ${phoneCtrl.text}, Session phone: $_currentLoggedInPhone');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session verification failed. Please login again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _logout();
      });
      
      return;
    }

    // Open payment checkout
    _paymentService.openCheckout(
      amount: selectedRoute!.fee,
      name: nameCtrl.text,
      phone: phoneCtrl.text, 
      email: '',
    );
  }

  // Build form field
  Widget _field(TextEditingController ctrl, String label, {bool readOnly = false}) {
    final icons = {
      'Student Name': Icons.person,
      'Roll No': Icons.badge,
      'Std / Section': Icons.school,
      'Parent Name': Icons.family_restroom,
      'Address': Icons.home,
      'Phone': Icons.phone,
      'Date of Birth': Icons.calendar_today,
    };
    final icon = icons[label] ?? Icons.edit;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF4F46E5)),
          filled: true,
          fillColor: readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (label == 'Date of Birth') {
            try { DateTime.parse(v); } catch (e) { return 'Invalid date format. Use YYYY-MM-DD'; }
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading or session invalid state
    if (!_isSessionValid) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
                  child: Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                ),
                const SizedBox(height: 24),
                const Text('Session Expired', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                const Text('Please login again to continue', style: TextStyle(color: Color(0xFF94A3B8))),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Go to Login', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Student Registration', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF4F46E5)),
          onPressed: () => setState(() => _isFrameOpen = !_isFrameOpen),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF94A3B8)),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFC7D2FE)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_pin, color: Color(0xFF4F46E5)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Logged in as: $_currentLoggedInPhone',
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _field(nameCtrl, 'Student Name'),
                            _field(rollCtrl, 'Roll No'),
                            _field(classCtrl, 'Std / Section'),
                            _field(parentCtrl, 'Parent Name'),
                            _field(addressCtrl, 'Address'),
                            _field(phoneCtrl, 'Phone', readOnly: true),
                            _field(dobCtrl, 'Date of Birth', readOnly: true),
                            const SizedBox(height: 8),
                            _isLoadingRoutes
                                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                                : DropdownButtonFormField<location_model.Route>(
                                    value: selectedRoute,
                                    decoration: InputDecoration(
                                      labelText: 'Location',
                                      prefixIcon: const Icon(Icons.location_on, color: Color(0xFF4F46E5)),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                                      ),
                                    ),
                                    hint: const Text('Select Location'),
                                    items: routes.map((r) => DropdownMenuItem<location_model.Route>(
                                      value: r,
                                      child: Text('${r.name} (₹${r.fee.toStringAsFixed(0)})'),
                                    )).toList(),
                                    onChanged: (location_model.Route? route) {
                                      setState(() {
                                        selectedRoute = route;
                                        amountCtrl.text = route?.fee.toString() ?? '';
                                      });
                                    },
                                    validator: (v) => v == null ? 'Select location' : null,
                                  ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: amountCtrl,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixText: '₹ ',
                                prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF4F46E5)),
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton(
                              onPressed: submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.payment, size: 20),
                                  SizedBox(width: 10),
                                  Text('Pay Now', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          if (_isFrameOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 260,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                          onPressed: () => setState(() => _isFrameOpen = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        if (await _verifySession()) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditReportPage(
                                phone: _currentLoggedInPhone!,
                                dob: _currentLoggedInDob!,
                                currentLocation: selectedRoute?.name ?? '',
                              ),
                            ),
                          );
                          if (mounted) _initializeView();
                        } else {
                          _showSessionExpiredDialog();
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_location, color: Color(0xFF4F46E5)),
                            SizedBox(width: 12),
                            Text('Change Location', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}