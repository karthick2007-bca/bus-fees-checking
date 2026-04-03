import 'dart:math' as math;
import 'package:dec_02/data/storage.dart';
import 'package:flutter/material.dart';
import '../models/admin.dart';

class AdminLoginView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onLoginSuccess;

  const AdminLoginView({super.key, required this.onBack, required this.onLoginSuccess});

  @override
  State<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    final admins = await DataStorage.loadAdmins();
    final found = admins.firstWhere(
      (a) => a.username == _usernameController.text && _passwordController.text == _usernameController.text,
      orElse: () => AdminUser(id: '', username: '', role: AdminRole.route),
    );
    if (found.id.isNotEmpty) {
      widget.onLoginSuccess();
    } else {
      setState(() { _errorMessage = 'Invalid credentials. Hint: username = password'; _isLoading = false; });
    }
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
                colors: [Color(0xFF0A0015), Color(0xFF0D0A2E), Color(0xFF0A1628), Color(0xFF050D1A)],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
          // Plexus animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (_, __) => CustomPaint(
                painter: _PlexusPainter(_animController.value),
              ),
            ),
          ),
          // Glow orbs
          Positioned(top: -100, left: -100,
            child: _glowOrb(350, const Color(0xFF6C00FF).withOpacity(0.18))),
          Positioned(bottom: -80, right: -80,
            child: _glowOrb(300, const Color(0xFF0066FF).withOpacity(0.15))),
          Positioned(top: MediaQuery.of(context).size.height * 0.4, right: -60,
            child: _glowOrb(200, const Color(0xFF00CCFF).withOpacity(0.1))),
          // Login card
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.05)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6C00FF).withOpacity(0.2), blurRadius: 60, spreadRadius: -10),
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
                  onTap: widget.onBack,
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
                const SizedBox(height: 32),
                // Icon
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C00FF), Color(0xFF0066FF)],
                    ),
                    boxShadow: [BoxShadow(color: const Color(0xFF6C00FF).withOpacity(0.5), blurRadius: 20, spreadRadius: -4)],
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 20),
                const Text('Admin Portal',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text('Sign in to manage the system',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),
                // Username
                _glassField(_usernameController, 'Username', Icons.person_rounded, false),
                const SizedBox(height: 16),
                // Password
                _glassField(_passwordController, 'Password', Icons.lock_rounded, true),
                // Error
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
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
                const SizedBox(height: 28),
                // Login button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6C00FF), Color(0xFF0066FF)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: const Color(0xFF6C00FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.vpn_key_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 10),
                                Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                              ],
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassField(TextEditingController ctrl, String hint, IconData icon, bool isPassword) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      onChanged: (_) => setState(() => _errorMessage = null),
      validator: (v) => (v == null || v.isEmpty) ? '$hint is required' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.white.withOpacity(0.5), size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6C00FF), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}

// Plexus painter
class _PlexusPainter extends CustomPainter {
  final double t;
  static final _rng = math.Random(42);
  static late List<_Node> _nodes;
  static bool _initialized = false;

  _PlexusPainter(this.t) {
    if (!_initialized) {
      _nodes = List.generate(40, (_) => _Node(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        vx: (_rng.nextDouble() - 0.5) * 0.0015,
        vy: (_rng.nextDouble() - 0.5) * 0.0015,
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
    final triPaint = Paint()..strokeWidth = 0.8..style = PaintingStyle.stroke;

    // Draw connecting lines
    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        final dx = _nodes[i].x - _nodes[j].x;
        final dy = _nodes[i].y - _nodes[j].y;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < 0.22) {
          final opacity = (1 - dist / 0.22) * 0.4;
          linePaint.color = Color.lerp(
            const Color(0xFF6C00FF), const Color(0xFF00CCFF), _nodes[i].x)!.withOpacity(opacity);
          canvas.drawLine(
            Offset(_nodes[i].x * size.width, _nodes[i].y * size.height),
            Offset(_nodes[j].x * size.width, _nodes[j].y * size.height),
            linePaint,
          );
        }
      }
    }

    // Draw triangles
    for (int i = 0; i < _nodes.length - 2; i += 3) {
      final a = Offset(_nodes[i].x * size.width, _nodes[i].y * size.height);
      final b = Offset(_nodes[i + 1].x * size.width, _nodes[i + 1].y * size.height);
      final c = Offset(_nodes[i + 2].x * size.width, _nodes[i + 2].y * size.height);
      final dist = (a - b).distance;
      if (dist < size.width * 0.25) {
        triPaint.color = const Color(0xFF6C00FF).withOpacity(0.08);
        final path = Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy)..lineTo(c.dx, c.dy)..close();
        canvas.drawPath(path, triPaint..style = PaintingStyle.fill);
        triPaint.color = const Color(0xFF00CCFF).withOpacity(0.15);
        triPaint.style = PaintingStyle.stroke;
        canvas.drawPath(path, triPaint);
      }
    }

    // Draw nodes
    for (final n in _nodes) {
      final pos = Offset(n.x * size.width, n.y * size.height);
      dotPaint.color = Color.lerp(const Color(0xFF6C00FF), const Color(0xFF00CCFF), n.x)!.withOpacity(0.7);
      canvas.drawCircle(pos, 2.5, dotPaint);
      dotPaint.color = Colors.white.withOpacity(0.5);
      canvas.drawCircle(pos, 1.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_PlexusPainter old) => old.t != t;
}

class _Node {
  double x, y, vx, vy;
  _Node({required this.x, required this.y, required this.vx, required this.vy});
}
