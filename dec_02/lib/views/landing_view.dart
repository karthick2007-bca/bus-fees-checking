import 'dart:math' as math;
import 'package:flutter/material.dart';

class LandingView extends StatefulWidget {
  final VoidCallback onAdminLogin;
  final VoidCallback onStudentLogin;

  const LandingView({
    super.key,
    required this.onAdminLogin,
    required this.onStudentLogin,
  });

  @override
  State<LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<LandingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  int? _hoveredCard;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _fadeIn = CurvedAnimation(
      parent: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..forward(),
      curve: Curves.easeOut,
    );

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..forward(),
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                colors: [
                  Color(0xFF050010),
                  Color(0xFF0A0A2E),
                  Color(0xFF001428),
                  Color(0xFF030810),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
          // Animated plexus
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => CustomPaint(
                painter: _LandingPlexusPainter(_controller.value),
              ),
            ),
          ),
          // Glow orbs
          Positioned(
            top: -100, left: -80,
            child: _glowOrb(350, const Color(0xFF6C00FF).withOpacity(0.12)),
          ),
          Positioned(
            bottom: -80, right: -80,
            child: _glowOrb(300, const Color(0xFF0066FF).withOpacity(0.1)),
          ),
          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C00FF), Color(0xFF0066FF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C00FF).withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    const Text(
                      'TransitPay',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Bus Fee Management System',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.45),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select your role to continue',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Admin Card
                    _RoleCard(
                      hovered: _hoveredCard == 0,
                      onHover: (v) => setState(() => _hoveredCard = v ? 0 : null),
                      onTap: widget.onAdminLogin,
                      gradientColors: const [Color(0xFF1A0040), Color(0xFF2D0080)],
                      glowColor: const Color(0xFF6C00FF),
                      icon: Icons.admin_panel_settings_rounded,
                      iconColor: const Color(0xFFB794F4),
                      title: 'Administrator',
                      description: 'Manage routes, students, fees and analytics',
                    ),

                    const SizedBox(height: 14),

                    // Student Card
                    _RoleCard(
                      hovered: _hoveredCard == 1,
                      onHover: (v) => setState(() => _hoveredCard = v ? 1 : null),
                      onTap: widget.onStudentLogin,
                      gradientColors: const [Color(0xFF001040), Color(0xFF002880)],
                      glowColor: const Color(0xFF0066FF),
                      icon: Icons.school_rounded,
                      iconColor: const Color(0xFF90CDF4),
                      title: 'Student',
                      description: 'View profile, pay fees and check reports',
                    ),

                    const SizedBox(height: 36),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dot(),
                        const SizedBox(width: 10),
                        Text(
                          'Secure  ·  Fast  ·  Reliable',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.3),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _dot(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );

  Widget _dot() => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
      );
}

class _RoleCard extends StatelessWidget {
  final bool hovered;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final Color glowColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _RoleCard({
    required this.hovered,
    required this.onHover,
    required this.onTap,
    required this.gradientColors,
    required this.glowColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(hovered ? 0.15 : 0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(hovered ? 0.35 : 0.15),
              blurRadius: hovered ? 40 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: Colors.white.withOpacity(0.06),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Icon(icon, size: 26, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withOpacity(0.55),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Arrow
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.translationValues(hovered ? 4 : 0, 0, 0),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: iconColor,
                        size: 16,
                      ),
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

class _LandingPlexusPainter extends CustomPainter {
  final double t;
  static final _rng = math.Random(77);
  static late List<_LNode> _nodes;
  static bool _initialized = false;

  _LandingPlexusPainter(this.t) {
    if (!_initialized) {
      _nodes = List.generate(35, (_) => _LNode(
        x: _rng.nextDouble(), y: _rng.nextDouble(),
        vx: (_rng.nextDouble() - 0.5) * 0.001,
        vy: (_rng.nextDouble() - 0.5) * 0.001,
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
    final linePaint = Paint()..strokeWidth = 0.5..style = PaintingStyle.stroke;
    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        final dx = _nodes[i].x - _nodes[j].x;
        final dy = _nodes[i].y - _nodes[j].y;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < 0.2) {
          final opacity = (1 - dist / 0.2) * 0.3;
          linePaint.color = Color.lerp(
            const Color(0xFF6C00FF), const Color(0xFF0066FF), _nodes[i].x)!.withOpacity(opacity);
          canvas.drawLine(
            Offset(_nodes[i].x * size.width, _nodes[i].y * size.height),
            Offset(_nodes[j].x * size.width, _nodes[j].y * size.height),
            linePaint,
          );
        }
      }
    }

    for (final n in _nodes) {
      final pos = Offset(n.x * size.width, n.y * size.height);
      dotPaint.color = Color.lerp(
        const Color(0xFF6C00FF), const Color(0xFF0066FF), n.x)!.withOpacity(0.6);
      canvas.drawCircle(pos, 2, dotPaint);
      dotPaint.color = Colors.white.withOpacity(0.4);
      canvas.drawCircle(pos, 1, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_LandingPlexusPainter old) => old.t != t;
}

class _LNode {
  double x, y, vx, vy;
  _LNode({required this.x, required this.y, required this.vx, required this.vy});
}
