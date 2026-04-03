import 'dart:math' as math;
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
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isCheckingReport = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _clearExistingSession();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
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
        (s) => s['phone']?.toString() == userId && s['dob']?.toString().split('T')[0] == password,
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
        (s) => s['phone']?.toString() == userId && s['dob']?.toString().split('T')[0] == password,
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
    } catch (_) {
      return 'Invalid date';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dark gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF050010), Color(0xFF0A0A2E), Color(0xFF001428), Color(0xFF030810)],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
          // Plexus animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (_, __) => CustomPaint(
                painter: _StudentPlexusPainter(_animController.value),
              ),
            ),
          ),
          // Glow orbs
          Positioned(top: -120, right: -80,
            child: _glowOrb(400, const Color(0xFF4F46E5).withOpacity(0.15))),
          Positioned(bottom: -100, left: -100,
            child: _glowOrb(350, const Color(0xFF06B6D4).withOpacity(0.12))),
          Positioned(top: MediaQuery.of(context).size.height * 0.5, left: -50,
            child: _glowOrb(200, const Color(0xFF8B5CF6).withOpacity(0.1))),
          // Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _glassCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );

  Widget _glassCard() {
    final busy = _isLoading || _isCheckingReport;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.11), Colors.white.withOpacity(0.04)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.13), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.2), blurRadius: 60, spreadRadius: -10),
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back
                GestureDetector(
                  onTap: _handleBack,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text('Back', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Icon
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)]),
                    boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.5), blurRadius: 20, spreadRadius: -4)],
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 18),
                const Text('Student Access',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text('View your transport fee summary',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
                const SizedBox(height: 28),
                // Phone
                _glassField(_userIdController, 'Phone Number (User ID)', Icons.phone_rounded, false, _validatePhone),
                const SizedBox(height: 14),
                // DOB
                _glassField(_passwordController, 'Date of Birth (YYYY-MM-DD)', Icons.calendar_today_rounded, true, _validateDob),
                // Error
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_rounded, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Dashboard button
                _gradientButton(
                  onTap: busy ? null : _handleLogin,
                  colors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.dashboard_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text('Open Dashboard', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                      ]),
                ),
                const SizedBox(height: 10),
                // Register button
                SizedBox(
                  width: double.infinity, height: 48,
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _clearExistingSession().then((_) { if (mounted) widget.onRegister(); }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.25), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.white.withOpacity(0.06),
                    ),
                    child: const Text('New Student? Register Here', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                // Check report button
                _gradientButton(
                  onTap: busy ? null : _handleCheckReport,
                  colors: const [Color(0xFF0891B2), Color(0xFF06B6D4)],
                  child: _isCheckingReport
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text('Check My Report', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                      ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradientButton({required VoidCallback? onTap, required List<Color> colors, required Widget child}) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: onTap == null ? [Colors.grey.shade700, Colors.grey.shade600] : colors),
            borderRadius: BorderRadius.circular(14),
            boxShadow: onTap == null ? [] : [BoxShadow(color: colors[0].withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Container(alignment: Alignment.center, child: child),
        ),
      ),
    );
  }

  Widget _glassField(TextEditingController ctrl, String hint, IconData icon, bool isPassword, String? Function(String?) validator) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: isPassword ? TextInputType.text : TextInputType.phone,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      onChanged: (_) => setState(() => _errorMessage = null),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.45), size: 20),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.white.withOpacity(0.45), size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}

class _StudentPlexusPainter extends CustomPainter {
  final double t;
  static final _rng = math.Random(99);
  static late List<_SNode> _nodes;
  static bool _initialized = false;

  _StudentPlexusPainter(this.t) {
    if (!_initialized) {
      _nodes = List.generate(45, (_) => _SNode(
        x: _rng.nextDouble(), y: _rng.nextDouble(),
        vx: (_rng.nextDouble() - 0.5) * 0.0012,
        vy: (_rng.nextDouble() - 0.5) * 0.0012,
      ));
      _initialized = true;
    }
    for (final n in _nodes) {
      n.x = (n.x + n.vx) % 1.0;
      n.y = (n.y + n.vy) % 1.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..strokeWidth = 0.6..style = PaintingStyle.stroke;
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final triPaint = Paint()..strokeWidth = 0.7..style = PaintingStyle.stroke;

    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        final dx = _nodes[i].x - _nodes[j].x;
        final dy = _nodes[i].y - _nodes[j].y;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < 0.2) {
          final opacity = (1 - dist / 0.2) * 0.35;
          linePaint.color = Color.lerp(const Color(0xFF4F46E5), const Color(0xFF06B6D4), _nodes[i].y)!.withOpacity(opacity);
          canvas.drawLine(
            Offset(_nodes[i].x * size.width, _nodes[i].y * size.height),
            Offset(_nodes[j].x * size.width, _nodes[j].y * size.height),
            linePaint,
          );
        }
      }
    }

    for (int i = 0; i < _nodes.length - 2; i += 3) {
      final a = Offset(_nodes[i].x * size.width, _nodes[i].y * size.height);
      final b = Offset(_nodes[i + 1].x * size.width, _nodes[i + 1].y * size.height);
      final c = Offset(_nodes[i + 2].x * size.width, _nodes[i + 2].y * size.height);
      if ((a - b).distance < size.width * 0.22) {
        triPaint.color = const Color(0xFF4F46E5).withOpacity(0.07);
        triPaint.style = PaintingStyle.fill;
        final path = Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy)..lineTo(c.dx, c.dy)..close();
        canvas.drawPath(path, triPaint);
        triPaint.color = const Color(0xFF06B6D4).withOpacity(0.12);
        triPaint.style = PaintingStyle.stroke;
        canvas.drawPath(path, triPaint);
      }
    }

    for (final n in _nodes) {
      final pos = Offset(n.x * size.width, n.y * size.height);
      dotPaint.color = Color.lerp(const Color(0xFF4F46E5), const Color(0xFF06B6D4), n.y)!.withOpacity(0.65);
      canvas.drawCircle(pos, 2.5, dotPaint);
      dotPaint.color = Colors.white.withOpacity(0.45);
      canvas.drawCircle(pos, 1.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_StudentPlexusPainter old) => old.t != t;
}

class _SNode {
  double x, y, vx, vy;
  _SNode({required this.x, required this.y, required this.vx, required this.vy});
}
