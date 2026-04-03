import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

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

class _StudentLoginViewState extends State<StudentLoginView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isCheckingReport = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _clearExistingSession();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _clearExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInPhone');
    await prefs.remove('loggedInDob');
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loggedInPhone', userId);
        await prefs.setString('loggedInDob', password);
        if (mounted) widget.onLoginSuccess(userId, password);
      } else {
        setState(() => _errorMessage = 'Invalid User ID or Password.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCheckReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isCheckingReport = true; _errorMessage = null; });
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loggedInPhone', userId);
        await prefs.setString('loggedInDob', password);
        if (mounted) {
          widget.onCheckReport != null
              ? widget.onCheckReport!(userId, password)
              : widget.onLoginSuccess(userId, password);
        }
      } else {
        setState(() => _errorMessage = 'Invalid User ID or Password.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isCheckingReport = false);
    }
  }

  Future<void> _handleBack() async {
    await _clearExistingSession();
    if (mounted) widget.onBack();
  }

  String? _validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Enter a valid 10-digit number';
    return null;
  }

  String? _validateDob(String? v) {
    if (v == null || v.isEmpty) return 'Date of birth is required';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return 'Use format: YYYY-MM-DD';
    try {
      final parts = v.split('-');
      final y = int.parse(parts[0]), m = int.parse(parts[1]), d = int.parse(parts[2]);
      if (m < 1 || m > 12) return 'Invalid month';
      if (d < 1 || d > 31) return 'Invalid day';
      final date = DateTime(y, m, d);
      if (date.isAfter(DateTime.now())) return 'Date cannot be in future';
      if (date.isAfter(DateTime(DateTime.now().year - 3, m, d))) return 'Must be at least 3 years old';
    } catch (_) {
      return 'Invalid date';
    }
    return null;
  }

  InputDecoration _inputDec(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.network(
              'https://img.freepik.com/premium-photo/free-vector-bus-background-design_951220-28959.jpg',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stack) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                  ),
                ),
              ),
            ),
          ),
          // Dark overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.55),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: isWide ? _wideLayout() : _narrowLayout(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Widget _wideLayout() {
    return Container(
      width: 900,
      constraints: const BoxConstraints(maxHeight: 640),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 60,
              offset: const Offset(0, 24))
        ],
      ),
      child: Row(
        children: [
          // Left panel
          Container(
            width: 340,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF312E81), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                bottomLeft: Radius.circular(32),
              ),
            ),
            child: Stack(
              children: [
                Positioned(top: -40, right: -40,
                    child: _circle(180, Colors.white.withOpacity(0.06))),
                Positioned(bottom: -60, left: -30,
                    child: _circle(220, Colors.white.withOpacity(0.05))),
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _handleBack,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text('Back',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 24),
                      const Text('Student Portal',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 10),
                      Text('Access your transport\nfee details and reports.',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                              height: 1.6)),
                      const SizedBox(height: 32),
                      _featureChip(Icons.receipt_long_rounded, 'Payment Receipts'),
                      const SizedBox(height: 10),
                      _featureChip(Icons.directions_bus_rounded, 'Bus Route Info'),
                      const SizedBox(height: 10),
                      _featureChip(Icons.history_rounded, 'Payment History'),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: _formContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _narrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 12))
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF312E81), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _handleBack,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.school_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text('Student Portal',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: _formContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formContent() {
    final busy = _isLoading || _isCheckingReport;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome back',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Sign in with your phone & date of birth',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),

          _label('PHONE NUMBER'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _userIdController,
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
            onChanged: (_) => setState(() => _errorMessage = null),
            decoration: _inputDec('Enter 10-digit phone number', Icons.phone_rounded),
          ),

          const SizedBox(height: 14),

          _label('DATE OF BIRTH (PASSWORD)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: _validateDob,
            onChanged: (_) => setState(() => _errorMessage = null),
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: _inputDec(
              'YYYY-MM-DD',
              Icons.calendar_today_rounded,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: const Color(0xFF94A3B8),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),

          // Error
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_rounded,
                      color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Open Dashboard button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: busy ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Open Dashboard',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 10),

          // Register button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: busy
                  ? null
                  : () => _clearExistingSession()
                      .then((_) { if (mounted) widget.onRegister(); }),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFFE0E7FF), width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('New Student? Register Here',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),

          const SizedBox(height: 10),

          // Check report button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: TextButton(
              onPressed: busy ? null : _handleCheckReport,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                backgroundColor: const Color(0xFFF5F3FF),
              ),
              child: _isCheckingReport
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Color(0xFF4F46E5), strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 17),
                        SizedBox(width: 8),
                        Text('Check My Report',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 1.5),
      );

  Widget _featureChip(IconData icon, String label) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      );
}
