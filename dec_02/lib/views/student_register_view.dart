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
          
          // Strict matching with current session
          return studentPhone == _currentLoggedInPhone && 
                 studentDob == _currentLoggedInDob;
        },
        orElse: () => null,
      );

      if (loggedInStudent != null) {
        print('Found logged-in student: ${loggedInStudent['name']}');
        
        setState(() {
          _currentStudentData = Map<String, dynamic>.from(loggedInStudent);
          
          // Set all fields with student data
          phoneCtrl.text = loggedInStudent['phone']?.toString() ?? '';
          dobCtrl.text = loggedInStudent['dob']?.toString().split('T')[0] ?? '';
          nameCtrl.text = loggedInStudent['name']?.toString() ?? '';
          rollCtrl.text = loggedInStudent['rollNo']?.toString() ?? '';
          classCtrl.text = loggedInStudent['studentClass']?.toString() ?? '';
          parentCtrl.text = loggedInStudent['parentName']?.toString() ?? '';
          addressCtrl.text = loggedInStudent['address']?.toString() ?? '';
          
          // Find and select the route based on student's location
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
      // Double-check session before saving
      if (!await _verifySession()) {
        _showSessionExpiredDialog();
        return;
      }
      
      await _saveStudent();
      
      await ApiService.saveTransaction({
        'paymentId': response['paymentId']?.toString() ?? '',
        'orderId': response['orderId']?.toString() ?? '',
        'studentId': phoneCtrl.text,
        'studentName': nameCtrl.text,
        'amount': selectedRoute?.fee ?? 0,
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to report with current user data only
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => StudentReport(
            phone: _currentLoggedInPhone!,
            dob: _currentLoggedInDob!,
            onLogout: () {
              _logout();
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
  Future<void> _saveStudent() async {
    try {
      // Verify session again
      if (!await _verifySession()) {
        throw Exception('Session invalid');
      }
      
      // Get all students to check if exists
      final students = await ApiService.getStudents();
      
      // Find existing student by phone and dob (using session data)
      final existingStudent = students.firstWhere(
        (s) => s['phone']?.toString() == _currentLoggedInPhone && 
               s['dob']?.toString().split('T')[0] == _currentLoggedInDob,
        orElse: () => null,
      );

      // Prepare student data with session info
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

      // Save to API (ApiService.addStudent handles both POST and PUT)
      await ApiService.addStudent(studentData);

      if (!mounted) return;

      // Clear form after successful save
      _clearFormFields();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student Registered Successfully ✅'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onSuccess();
      widget.onRegisterSuccess();
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
    IconData icon;
    switch (label) {
      case 'Student Name':
        icon = Icons.person;
        break;
      case 'Roll No':
        icon = Icons.badge;
        break;
      case 'Std / Section':
        icon = Icons.school;
        break;
      case 'Parent Name':
        icon = Icons.family_restroom;
        break;
      case 'Address':
        icon = Icons.home;
        break;
      case 'Phone':
        icon = Icons.phone;
        break;
      case 'Date of Birth':
        icon = Icons.calendar_today;
        break;
      default:
        icon = Icons.edit;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.shade100 : null,
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (label == 'Date of Birth') {
            try {
              DateTime.parse(v);
            } catch (e) {
              return 'Invalid date format. Use YYYY-MM-DD';
            }
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
        appBar: AppBar(
          title: const Text('Student Registration'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Session Expired',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Please login again to continue'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _logout,
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _isFrameOpen = !_isFrameOpen;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Display current user info
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Logged in as: $_currentLoggedInPhone',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
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
                        
                        // Hidden fields for phone and dob (display them read-only)
                        _field(phoneCtrl, 'Phone', readOnly: true),
                        _field(dobCtrl, 'Date of Birth', readOnly: true),

                        const SizedBox(height: 16),

                        // Location Dropdown
                        _isLoadingRoutes
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<location_model.Route>(
                                value: selectedRoute,
                                decoration: const InputDecoration(
                                  labelText: 'Location',
                                  prefixIcon: Icon(Icons.location_on),
                                ),
                                hint: const Text('Select Location'),
                                items: routes.map((r) {
                                  return DropdownMenuItem<location_model.Route>(
                                    value: r,
                                    child: Text('${r.name} (₹${r.fee.toStringAsFixed(0)})'),
                                  );
                                }).toList(),
                                onChanged: (location_model.Route? route) {
                                  setState(() {
                                    selectedRoute = route;
                                    amountCtrl.text = route?.fee.toString() ?? '';
                                  });
                                },
                                validator: (v) => v == null ? 'Select location' : null,
                              ),

                        const SizedBox(height: 12),

                        // Amount Field
                        TextFormField(
                          controller: amountCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₹ ',
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Pay Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Pay Now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

          // Side Menu Frame
          if (_isFrameOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 250,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: Colors.grey.shade300, width: 2)),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Report',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _isFrameOpen = false),
                        ),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.edit_location),
                      title: const Text('Change Location'),
                      onTap: () async {
                        // Verify session before navigating
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
                          
                          // Refresh after returning from edit page
                          if (mounted) {
                            _initializeView();
                          }
                        } else {
                          _showSessionExpiredDialog();
                        }
                      },
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