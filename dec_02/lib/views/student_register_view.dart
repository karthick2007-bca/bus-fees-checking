import 'package:dec_02/models/student.dart';
import 'package:dec_02/models/payment.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../models/location.dart' as location_model;
import 'student_report.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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

  final nameCtrl = TextEditingController();
  final rollCtrl = TextEditingController();
  final classCtrl = TextEditingController();
  final parentCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final amountCtrl = TextEditingController();

  List<location_model.Route> routes = [];
  location_model.Route? selectedRoute;
  
  get selectedlocation => null;

  @override
  void initState() {
    super.initState();
    amountCtrl.clear();
    loadRoutes();
    _loadExistingStudent();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onWallet: () => print('Wallet selected'),
    );
  }

  Future<void> _loadExistingStudent() async {
    try {
      final students = await ApiService.getStudents();
      final loggedInStudent = students.firstWhere(
        (s) => s['phone'] != null && s['phone'].toString().isNotEmpty,
        orElse: () => {},
      );

      if (loggedInStudent.isNotEmpty) {
        setState(() {
          phoneCtrl.text = loggedInStudent['phone'] ?? '';
          dobCtrl.text = loggedInStudent['dob']?.toString().split('T')[0] ?? '';
          
          if (loggedInStudent['name']?.isNotEmpty == true) {
            nameCtrl.text = loggedInStudent['name'] ?? '';
            rollCtrl.text = loggedInStudent['rollNo'] ?? '';
            classCtrl.text = loggedInStudent['studentClass'] ?? '';
            parentCtrl.text = loggedInStudent['parentName'] ?? '';
            addressCtrl.text = loggedInStudent['address'] ?? '';
          }
        });
      }
    } catch (e) {
      print('Error loading student: $e');
    }
  }

  @override
  void dispose() {
    _paymentService.dispose();
    nameCtrl.dispose();
    rollCtrl.dispose();
    classCtrl.dispose();
    parentCtrl.dispose();
    addressCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    dobCtrl.dispose(); 
    amountCtrl.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await _saveStudent();
    await ApiService.saveTransaction({
      'paymentId': response.paymentId,
      'orderId': response.orderId,
      'studentId': phoneCtrl.text,
      'studentName': nameCtrl.text,
      'amount': selectedRoute!.fee,
      'status': 'success',
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Success: ${response.paymentId}'), backgroundColor: Colors.green),
    );
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentReport(
            phone: phoneCtrl.text,
            dob: dobCtrl.text,
            onLogout: widget.onBack,
          ),
        ),
      );
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  Future<void> loadRoutes() async {
    try {
      final data = await ApiService.getLocations();
      print('Loaded locations: $data');
      setState(() {
        routes = data.map((loc) => location_model.Route(
          id: loc['id'] ?? '',
          name: loc['name'] ?? '',
          fee: (loc['fee'] as num).toDouble(),
        )).toList();
      });
      print('Routes count: ${routes.length}');
    } catch (e) {
      print("Error loading routes: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading locations: $e')),
      );
    }
  }

  // ✅ SUBMIT STUDENT
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select location')),
      );
      return;
    }

    _paymentService.openCheckout(
      amount: selectedRoute!.fee,
      name: nameCtrl.text,
      phone: phoneCtrl.text,
      email: emailCtrl.text.isEmpty ? '${rollCtrl.text}@student.com' : emailCtrl.text,
    );
  }

  Future<void> _saveStudent() async {
    try {
      // Find existing student by phone and dob
      final students = await ApiService.getStudents();
      final existingStudent = students.firstWhere(
        (s) => s['phone'] == phoneCtrl.text && s['dob']?.toString().split('T')[0] == dobCtrl.text,
        orElse: () => {},
      );

      // Update existing student data
      await ApiService.addStudent({
        'id': existingStudent['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'name': nameCtrl.text,
        'rollNo': rollCtrl.text,
        'studentClass': classCtrl.text,
        'parentName': parentCtrl.text,
        'location': selectedRoute!.name,
        'totalDue': 0,
        'amountPaid': selectedRoute!.fee,
        'status': 'succeed',
        'address': addressCtrl.text,
        'email': emailCtrl.text,
        'phone': phoneCtrl.text,
        'dob': dobCtrl.text,
        'registrationDate': DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'payments': [],
        'locationHistory': [],
      });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
        leading: IconButton(
          icon: const Text('>>>', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          onPressed: () {
            setState(() {
              _isFrameOpen = !_isFrameOpen;
            });
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(nameCtrl, 'Student Name'),
                  _field(rollCtrl, 'Roll No'),
                  _field(classCtrl, 'Std / Section'),
                  _field(parentCtrl, 'Parent Name'),
                  _field(addressCtrl, 'Address'),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<location_model.Route>(
                    value: selectedRoute,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    hint: const Text('Select Location'),
                    items: routes.map((r) {
                      return DropdownMenuItem<location_model.Route>(
                        value: r,
                        child: Text('${r.name} (₹${r.fee})'),
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

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: submit,
                      child: const Text('Pay'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isFrameOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 250,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.grey.shade300, width: 2)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
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
      case 'Email':
        icon = Icons.email;
        break;
      case 'Phone':
        icon = Icons.phone;
        break;
      default:
        icon = Icons.calendar_today;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (label.contains('Date of Birth')) {
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
}
