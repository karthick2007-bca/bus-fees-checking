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

class _LandingViewState extends State<LandingView> {
  int? _hoveredCard;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Original background image
          Positioned.fill(
            child: Image.network(
              'https://5.imimg.com/data5/SELLER/Default/2021/2/IC/ZO/OY/3332884/led-sign-board-1000x1000.jpg',
              headers: const {'User-Agent': 'Mozilla/5.0'},
              fit: BoxFit.cover,
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
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
                            color: const Color(0xFF6C00FF).withValues(alpha: 0.4),
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
                        color: Colors.white.withValues(alpha: 0.45),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select your role to continue',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withValues(alpha: 0.35),
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
                            color: Colors.white.withValues(alpha: 0.3),
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

  Widget _dot() => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
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
            color: Colors.white.withValues(alpha: hovered ? 0.15 : 0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: hovered ? 0.35 : 0.15),
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
            splashColor: Colors.white.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
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
                            color: Colors.white.withValues(alpha: 0.55),
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
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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

