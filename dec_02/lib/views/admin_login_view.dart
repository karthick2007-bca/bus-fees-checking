import 'package:dec_02/data/storage.dart';
import 'package:flutter/material.dart';
import '../models/admin.dart';

class AdminLoginView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onLoginSuccess;

  const AdminLoginView({
    super.key,
    required this.onBack,
    required this.onLoginSuccess,
  });

  @override
  State<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final admins = await DataStorage.loadAdmins();
      final username = _usernameController.text;
      final password = _passwordController.text;

      final found = admins.firstWhere(
        (a) => a.username == username && password == username,
        orElse: () => AdminUser(id: '', username: '', role: AdminRole.route),
      );

      if (found.id.isNotEmpty) {
        widget.onLoginSuccess();
      } else {
        setState(() {
          _errorMessage = 'Invalid credentials. Hint: username = password';
          _isLoading = false;
        });
      }
    }
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
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
          borderSide: const BorderSide(color: Color(0xFF4338CA), width: 2),
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
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
              ),
            ),
          ),

          // Decorative circles
          Positioned(top: -60, right: -60,
            child: _circle(260, Colors.white.withOpacity(0.04))),
          Positioned(bottom: -100, left: -80,
            child: _circle(340, Colors.white.withOpacity(0.04))),

          // Content
          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: isWide
                    ? _wideLayout()
                    : _narrowLayout(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  // Wide: left branding panel + right form
  Widget _wideLayout() {
    return Container(
      width: 860,
      height: 560,
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
                colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                bottomLeft: Radius.circular(32),
              ),
            ),
            child: Stack(
              children: [
                Positioned(top: -40, right: -40,
                    child: _circle(180, Colors.white.withOpacity(0.05))),
                Positioned(bottom: -60, left: -30,
                    child: _circle(220, Colors.white.withOpacity(0.05))),
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: widget.onBack,
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
                        child: const Icon(Icons.admin_panel_settings_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 24),
                      const Text('Admin Portal',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 10),
                      Text('Manage routes, students\nand fee collections.',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                              height: 1.6)),
                      const SizedBox(height: 32),
                      _featureChip(Icons.location_on_rounded, 'Route Management'),
                      const SizedBox(height: 10),
                      _featureChip(Icons.people_rounded, 'Student Records'),
                      const SizedBox(height: 10),
                      _featureChip(Icons.bar_chart_rounded, 'Analytics'),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right form
          Expanded(child: _formPanel()),
        ],
      ),
    );
  }

  // Narrow: just the form card
  Widget _narrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 16))
            ],
          ),
          child: Column(
            children: [
              // Mini header
              Container(
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onBack,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    const Text('Admin Portal',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: _formContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formPanel() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: _formContent(),
    );
  }

  Widget _formContent() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome back',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          const Text('Sign in to your admin account',
              style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 32),

          // Username
          _label('USERNAME'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _usernameController,
            onChanged: (_) => setState(() => _errorMessage = null),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Username is required' : null,
            decoration: _inputDec('admin / finance / route', Icons.person_rounded),
          ),

          const SizedBox(height: 20),

          // Password
          _label('PASSWORD'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            onChanged: (_) => setState(() => _errorMessage = null),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Password is required' : null,
            decoration: _inputDec(
              '••••••••',
              Icons.lock_rounded,
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

          const SizedBox(height: 28),

          // Login button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4338CA),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                shadowColor: const Color(0xFF4338CA).withOpacity(0.4),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.vpn_key_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Sign In',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
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
