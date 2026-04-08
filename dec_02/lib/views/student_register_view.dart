import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../models/location.dart' as location_model;
import 'student_report.dart';
import 'edit_report_page.dart';

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

  String? _currentLoggedInPhone;
  String? _currentLoggedInDob;
  Map<String, dynamic>? _currentStudentData;

  // Design constants
  static const _bg = Color(0xFF0F0F1A);
  static const _overlayColor = Color(0xCC0F0F1A); // 80% dark overlay
  static const _card = Color(0xFF1A1A2E);
  static const _accent = Color(0xFF6C63FF);
  static const _accent2 = Color(0xFF00D4AA);
  static const _textPrimary = Color(0xFFEEEEFF);
  static const _textSecondary = Color(0xFF8888AA);
  static const _fieldBg = Color(0xFF22223A);
  static const _border = Color(0xFF2E2E4A);

  @override
  void initState() {
    super.initState();
    _clearFormFields();
    amountCtrl.clear();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onWallet: () {},
    );
    _initializeView();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    nameCtrl.dispose(); rollCtrl.dispose(); classCtrl.dispose();
    parentCtrl.dispose(); addressCtrl.dispose(); phoneCtrl.dispose();
    dobCtrl.dispose(); amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeView() async {
    await _validateSession();
    if (_isSessionValid) {
      await loadRoutes();
      await _loadLoggedInStudent();
    }
  }

  Future<void> _validateSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLoggedInPhone = prefs.getString('loggedInPhone');
      _currentLoggedInDob = prefs.getString('loggedInDob');
      if (_currentLoggedInPhone == null || _currentLoggedInDob == null) {
        setState(() => _isSessionValid = false);
        _showSessionExpiredDialog();
      }
    } catch (e) {
      setState(() => _isSessionValid = false);
    }
  }

  void _clearFormFields() {
    nameCtrl.clear(); rollCtrl.clear(); classCtrl.clear();
    parentCtrl.clear(); addressCtrl.clear(); phoneCtrl.clear();
    dobCtrl.clear(); amountCtrl.clear();
    setState(() { selectedRoute = null; _currentStudentData = null; });
  }

  Future<void> _loadLoggedInStudent() async {
    if (!_isSessionValid) return;
    setState(() => _isLoading = true);
    try {
      final students = await ApiService.getStudents();
      final loggedInStudent = students.firstWhere(
        (s) => s['phone']?.toString() == _currentLoggedInPhone &&
               s['dob']?.toString().split('T')[0] == _currentLoggedInDob,
        orElse: () => null,
      );
      if (loggedInStudent != null) {
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
            }
          }
        });
      } else {
        _showUserNotFoundDialog();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> loadRoutes() async {
    setState(() { _isLoadingRoutes = true; _frameError = null; });
    try {
      final data = await ApiService.getLocations();
      setState(() {
        routes = data.map((loc) => location_model.Route(
          id: loc['id']?.toString() ?? '',
          name: loc['name']?.toString() ?? '',
          fee: (loc['fee'] as num?)?.toDouble() ?? 0.0,
        )).toList();
        _isLoadingRoutes = false;
      });
    } catch (e) {
      setState(() { _frameError = e.toString(); _isLoadingRoutes = false; });
    }
  }

  void _handlePaymentSuccess(dynamic response) async {
    try {
      if (!await _verifySession()) { _showSessionExpiredDialog(); return; }
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
      await ApiService.saveTransaction({
        'paymentId': paymentId, 'orderId': response['orderId']?.toString() ?? '',
        'studentId': capturedPhone, 'studentName': capturedName,
        'phone': capturedPhone, 'rollNo': capturedRoll,
        'amount': capturedAmount, 'status': 'success', 'timestamp': now,
      });
      await ApiService.saveReport({
        'phone': capturedPhone, 'name': capturedName, 'rollNo': capturedRoll,
        'studentClass': capturedClass, 'parentName': capturedParent,
        'address': capturedAddress, 'location': capturedLocation, 'dob': capturedDob,
        'totalDue': 0, 'amountPaid': capturedAmount, 'status': 'succeed',
        'paymentId': paymentId, 'paymentDate': now, 'generatedAt': now,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful! ✅'), backgroundColor: Colors.green));
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => StudentReport(
          phone: capturedPhone!, dob: capturedDob!, onLogout: () => _logout(),
          initialData: {
            'name': capturedName, 'rollNo': capturedRoll, 'studentClass': capturedClass,
            'parentName': capturedParent, 'address': capturedAddress,
            'phone': capturedPhone, 'dob': capturedDob, 'location': capturedLocation,
            'amountPaid': capturedAmount, 'totalDue': 0, 'status': 'succeed',
            'paymentId': paymentId, 'paymentDate': now,
          },
        )), (route) => false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _handlePaymentFailure(dynamic response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response['message'] ?? 'Unknown error'}'),
        backgroundColor: Colors.red));
  }

  Future<void> _saveStudent({bool fromPayment = false}) async {
    try {
      if (!await _verifySession()) throw Exception('Session invalid');
      final students = await ApiService.getStudents();
      final existingStudent = students.firstWhere(
        (s) => s['phone']?.toString() == _currentLoggedInPhone &&
               s['dob']?.toString().split('T')[0] == _currentLoggedInDob,
        orElse: () => null,
      );
      await ApiService.addStudent({
        'id': existingStudent?['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'name': nameCtrl.text, 'rollNo': rollCtrl.text, 'studentClass': classCtrl.text,
        'parentName': parentCtrl.text, 'location': selectedRoute?.name ?? '',
        'totalDue': 0, 'amountPaid': selectedRoute?.fee ?? 0, 'status': 'succeed',
        'address': addressCtrl.text, 'phone': _currentLoggedInPhone, 'dob': _currentLoggedInDob,
        'registrationDate': existingStudent?['registrationDate'] ?? DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'payments': existingStudent?['payments'] ?? [],
        'locationHistory': existingStudent?['locationHistory'] ?? [],
      });
      if (!fromPayment && mounted) {
        _clearFormFields();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered Successfully ✅'), backgroundColor: Colors.green));
        widget.onSuccess();
        widget.onRegisterSuccess();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<bool> _verifySession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final p = prefs.getString('loggedInPhone');
      final d = prefs.getString('loggedInDob');
      return p == _currentLoggedInPhone && d == _currentLoggedInDob && p != null;
    } catch (_) { return false; }
  }

  Future<void> _clearLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInPhone');
    await prefs.remove('loggedInDob');
    setState(() {
      _currentLoggedInPhone = null; _currentLoggedInDob = null;
      _isSessionValid = false; _currentStudentData = null;
    });
  }

  void _navigateToLogin() { if (mounted) widget.onBack(); }

  Future<void> _logout() async {
    await _clearLoggedInUser();
    if (mounted) _navigateToLogin();
  }

  void _showSessionExpiredDialog() {
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Your session has expired. Please login again.'),
        actions: [TextButton(onPressed: () { Navigator.of(context).pop(); _logout(); }, child: const Text('OK'))],
      ));
  }

  void _showUserNotFoundDialog() {
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('User Not Found'),
        content: const Text('Your account could not be found. Please login again.'),
        actions: [TextButton(onPressed: () { Navigator.of(context).pop(); _logout(); }, child: const Text('Login Again'))],
      ));
  }

  Future<void> submit() async {
    if (!await _verifySession()) { _showSessionExpiredDialog(); return; }
    if (!_formKey.currentState!.validate()) return;
    if (selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select location'), backgroundColor: Colors.orange));
      return;
    }
    if (phoneCtrl.text != _currentLoggedInPhone || dobCtrl.text != _currentLoggedInDob) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session mismatch. Please login again.'), backgroundColor: Colors.red));
      Future.delayed(const Duration(seconds: 2), () { if (mounted) _logout(); });
      return;
    }
    _paymentService.openCheckout(
      amount: selectedRoute!.fee, name: nameCtrl.text, phone: phoneCtrl.text, email: '');
  }

  // ── Field builder ──
  Widget _field(TextEditingController ctrl, String label,
      {bool readOnly = false, TextInputType? keyboardType}) {
    final icons = {
      'Student Name': Icons.person_rounded,
      'Roll No': Icons.badge_rounded,
      'Std / Section': Icons.school_rounded,
      'Parent Name': Icons.supervisor_account_rounded,
      'Address': Icons.home_rounded,
      'Phone': Icons.phone_rounded,
      'Date of Birth': Icons.cake_rounded,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _textSecondary, fontSize: 13),
          prefixIcon: Icon(icons[label] ?? Icons.edit_rounded, color: _accent, size: 20),
          filled: true,
          fillColor: readOnly ? const Color(0xFF1E1E32) : _fieldBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent, width: 1.8)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent)),
          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (label == 'Date of Birth') {
            try { DateTime.parse(v); } catch (_) { return 'Use YYYY-MM-DD'; }
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSessionValid) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _border),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: const Icon(Icons.lock_outline_rounded, color: Colors.redAccent, size: 30),
              ),
              const SizedBox(height: 20),
              const Text('Session Expired', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textPrimary)),
              const SizedBox(height: 8),
              const Text('Please login again to continue', style: TextStyle(color: _textSecondary, fontSize: 13)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Go to Login', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.45),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary, size: 18),
          onPressed: _logout,
        ),
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_accent, Color(0xFF9C63FF)]),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          const Text('Registration', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt_rounded, color: _accent, size: 22),
            tooltip: 'Change Location',
            onPressed: () async {
              if (await _verifySession()) {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EditReportPage(
                    phone: _currentLoggedInPhone!,
                    dob: _currentLoggedInDob!,
                    currentLocation: selectedRoute?.name ?? '',
                  ),
                ));
                if (mounted) _initializeView();
              } else {
                _showSessionExpiredDialog();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _textSecondary, size: 20),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: Stack(
        children: [
          // ── Background image with overlay ──
          Positioned.fill(
            child: Image.network(
              'https://img.freepik.com/premium-photo/group-students-walking-school-together_1204564-32168.jpg?w=1060',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: _bg),
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.72))),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: _accent))
          else
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── User badge ──
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _accent.withOpacity(0.25)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.verified_user_rounded, color: _accent, size: 16),
                            const SizedBox(width: 8),
                            Text('Logged in as: $_currentLoggedInPhone',
                              style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        const SizedBox(height: 22),

                        // ── Section: Personal Info ──
                        _sectionLabel('Personal Info', Icons.person_outline_rounded),
                        const SizedBox(height: 12),
                        _field(nameCtrl, 'Student Name'),
                        _field(rollCtrl, 'Roll No'),
                        _field(classCtrl, 'Std / Section'),
                        _field(parentCtrl, 'Parent Name'),
                        _field(addressCtrl, 'Address'),

                        const SizedBox(height: 6),

                        // ── Section: Account ──
                        _sectionLabel('Account Details', Icons.lock_outline_rounded),
                        const SizedBox(height: 12),
                        _field(phoneCtrl, 'Phone', readOnly: true, keyboardType: TextInputType.phone),
                        _field(dobCtrl, 'Date of Birth', readOnly: true),

                        const SizedBox(height: 6),

                        // ── Section: Bus Route ──
                        _sectionLabel('Bus Route & Fee', Icons.directions_bus_rounded),
                        const SizedBox(height: 12),

                        // Location dropdown
                        _isLoadingRoutes
                            ? const Center(child: CircularProgressIndicator(color: _accent))
                            : DropdownButtonFormField<location_model.Route>(
                                value: selectedRoute,
                                dropdownColor: const Color(0xFF1E1E32),
                                style: const TextStyle(color: _textPrimary, fontSize: 14),
                                iconEnabledColor: _accent,
                                decoration: InputDecoration(
                                  labelText: 'Select Location',
                                  labelStyle: const TextStyle(color: _textSecondary, fontSize: 13),
                                  prefixIcon: const Icon(Icons.location_on_rounded, color: _accent, size: 20),
                                  filled: true,
                                  fillColor: _fieldBg,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: _border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: _border)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: _accent, width: 1.8)),
                                ),
                                hint: const Text('Choose your stop', style: TextStyle(color: _textSecondary, fontSize: 13)),
                                items: routes.map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text('${r.name}  ·  ₹${r.fee.toStringAsFixed(0)}',
                                    style: const TextStyle(color: _textPrimary, fontSize: 13)),
                                )).toList(),
                                onChanged: (r) => setState(() {
                                  selectedRoute = r;
                                  amountCtrl.text = r?.fee.toString() ?? '';
                                }),
                                validator: (v) => v == null ? 'Select a location' : null,
                              ),

                        const SizedBox(height: 14),

                        // Amount display
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: _accent2.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _accent2.withOpacity(0.25)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: _accent2.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.currency_rupee_rounded, color: _accent2, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Bus Fee Amount', style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(
                                selectedRoute != null ? '₹ ${selectedRoute!.fee.toStringAsFixed(0)}' : '— Select location first',
                                style: TextStyle(
                                  color: selectedRoute != null ? _accent2 : _textSecondary,
                                  fontSize: 18, fontWeight: FontWeight.w800,
                                ),
                              ),
                            ]),
                          ]),
                        ),

                        const SizedBox(height: 32),

                        // ── Pay Now button ──
                        SizedBox(
                          width: double.infinity, height: 54,
                          child: ElevatedButton(
                            onPressed: submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payment_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text('Pay Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.3)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: _accent, size: 16),
      const SizedBox(width: 7),
      Text(title.toUpperCase(),
        style: const TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1, color: _border)),
    ]);
  }
}
