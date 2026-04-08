
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:iconsax/iconsax.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:math' as math;
import '../data/storage.dart';
import '../services/api_service.dart';
import '../models/location.dart' as location_model;

class AdminDashboard extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminDashboard({super.key, required this.onLogout});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool isMenuExpanded = false;
  List<Map<String, dynamic>> locations = [];
  List<Map<String, dynamic>> filteredLocations = [];
  int totalStudents = 0;
  int paidStudents = 0;
  int _unreadCount = 0;
  final TextEditingController searchController = TextEditingController();
  String? _longPressedLocationId;
  bool _notificationShown = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadStudentCount();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final data = await ApiService.getLocations();
      setState(() {
        locations = data.map((loc) => {
          'id': (loc['_id'] ?? loc['id'])?.toString() ?? '',
          'name': loc['name'],
          'fee': loc['fee'],
        }).toList();
        filteredLocations = locations;
      });
    } catch (e) {
      print('Error loading locations: $e');
    }
  }

  Future<void> _loadStudentCount() async {
    try {
      final students = await ApiService.getStudents();
      setState(() {
        totalStudents = students.length;
        paidStudents = students.where((s) => s['status'] == 'succeed').length;
      });
    } catch (e) {
      print('Error loading students: $e');
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final notifications = await ApiService.getNotifications();
      setState(() {
        _unreadCount = notifications.where((n) => n['read'] != true).length;
      });
    } catch (_) {}
  }

  void _filterLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredLocations = locations;
        _notificationShown = false;
      } else {
        filteredLocations = locations.where((loc) => 
          loc['name'].toString().toLowerCase().contains(query.toLowerCase())
        ).toList();
        if (filteredLocations.isEmpty && query.isNotEmpty && !_notificationShown) {
          _notificationShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location not found'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  Future<void> _addLocation(String name, double fee) async {
    try {
      await ApiService.addLocation({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'fee': fee,
      });
      _loadLocations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _glowOrb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
    ),
  );

  Widget _sectionHeading(String title, {IconData? icon, Widget? trailing}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _glassContainer({required Widget child, EdgeInsets? padding, double radius = 16}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.13), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glassStatCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 130,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradient.first.withOpacity(0.55), gradient.last.withOpacity(0.35)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(height: 12),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteLocation(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteLocation(id);
        _loadLocations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location moved to recycle bin'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _appBarBtn({required IconData icon, required Color color, required Color bg, required Color border, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border, width: 1)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _glassSubheading(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6C00FF), Color(0xFF0066FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
      ],
    );
  }

  Widget _menuTile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Logo
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C00FF), Color(0xFF0066FF)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          boxShadow: [BoxShadow(color: const Color(0xFF6C00FF).withOpacity(0.5), blurRadius: 14, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Admin Dashboard',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
                      ),
                      // Delete action
                      if (_longPressedLocationId != null)
                        _appBarBtn(
                          icon: Icons.delete_rounded,
                          color: Colors.redAccent,
                          bg: Colors.red.withOpacity(0.18),
                          border: Colors.red.withOpacity(0.4),
                          onTap: () async {
                            final loc = locations.firstWhere((l) => l['id'] == _longPressedLocationId);
                            await _deleteLocation(loc['id'], loc['name']);
                            setState(() => _longPressedLocationId = null);
                          },
                        ),
                      const SizedBox(width: 8),
                      // Notifications
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _appBarBtn(
                            icon: Icons.receipt_long_rounded,
                            color: Colors.white,
                            bg: Colors.white.withOpacity(0.08),
                            border: Colors.white.withOpacity(0.14),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                              _loadUnreadCount();
                            },
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              right: 2, top: 2,
                              child: Container(
                                width: 16, height: 16,
                                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                child: Center(
                                  child: Text('$_unreadCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Logout
                      _appBarBtn(
                        icon: Icons.logout_rounded,
                        color: Colors.white70,
                        bg: Colors.white.withOpacity(0.08),
                        border: Colors.white.withOpacity(0.14),
                        onTap: widget.onLogout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // ── Rich deep navy background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF060818), Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),
          // Ambient glow orbs
          Positioned(top: -120, left: -120,
            child: _glowOrb(380, const Color(0xFF6C00FF).withOpacity(0.18))),
          Positioned(bottom: -100, right: -100,
            child: _glowOrb(320, const Color(0xFF0066FF).withOpacity(0.14))),
          Positioned(top: 180, right: -80,
            child: _glowOrb(220, const Color(0xFF00CCFF).withOpacity(0.09))),
          Positioned(top: 350, left: -60,
            child: _glowOrb(180, const Color(0xFF10B981).withOpacity(0.07))),

          // ── Main scrollable content ──
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(sw * 0.05, 20, sw * 0.05, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── MENU TOGGLE ──
                  GestureDetector(
                    onTap: () => setState(() => isMenuExpanded = !isMenuExpanded),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.14), width: 1),
                            boxShadow: [BoxShadow(color: const Color(0xFF6C00FF).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: isMenuExpanded
                                      ? Colors.redAccent.withOpacity(0.2)
                                      : const Color(0xFF6C00FF).withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isMenuExpanded ? Icons.close_rounded : Icons.grid_view_rounded,
                                  color: isMenuExpanded ? Colors.redAccent : const Color(0xFF00CCFF),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isMenuExpanded ? 'Close Menu' : 'Quick Menu',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isMenuExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: Colors.white.withOpacity(0.4), size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── MENU PANEL ──
                  if (isMenuExpanded) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))],
                          ),
                          child: Column(
                            children: [
                              // Row 1
                              Row(
                                children: [
                                  _menuTile(icon: Icons.add_location_alt_rounded, label: 'Add Location', color: const Color(0xFF6C00FF),
                                    onTap: () async {
                                      setState(() => isMenuExpanded = false);
                                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLocationPage()));
                                      if (result != null) _addLocation(result['name'], result['fee']);
                                    }),
                                  const SizedBox(width: 10),
                                  _menuTile(icon: Icons.analytics_rounded, label: 'Admin Role', color: const Color(0xFF0EA5E9),
                                    onTap: () {
                                      setState(() => isMenuExpanded = false);
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRolePage()));
                                    }),
                                  const SizedBox(width: 10),
                                  _menuTile(icon: Icons.person_add_rounded, label: 'Student Entry', color: const Color(0xFF10B981),
                                    onTap: () {
                                      setState(() => isMenuExpanded = false);
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadStudentDataPage()));
                                    }),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Row 2
                              Row(
                                children: [
                                  _menuTile(icon: Icons.delete_sweep_rounded, label: 'Recycle Bin', color: const Color(0xFFF59E0B),
                                    onTap: () {
                                      setState(() => isMenuExpanded = false);
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RecycleBinPage()));
                                    }),
                                  const SizedBox(width: 10),
                                  _menuTile(icon: Icons.settings_rounded, label: 'Settings', color: const Color(0xFF8B5CF6),
                                    onTap: () {
                                      setState(() => isMenuExpanded = false);
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                                    }),
                                  const SizedBox(width: 10),
                                  _menuTile(icon: Icons.feedback_rounded, label: 'Feedback', color: const Color(0xFF10B981),
                                    onTap: () {
                                      setState(() => isMenuExpanded = false);
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackPage()));
                                    }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── STATS SUBHEADING ──
                  _glassSubheading('Overview', Icons.bar_chart_rounded),
                  const SizedBox(height: 12),

                  // ── STAT CARDS ──
                  Row(
                    children: [
                      Expanded(child: _glassStatCard(
                        icon: Icons.location_on_rounded,
                        label: 'Locations',
                        value: '${locations.length}',
                        gradient: const [Color(0xFF6C00FF), Color(0xFF0066FF)],
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllLocationsPage())),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _glassStatCard(
                        icon: Icons.people_rounded,
                        label: 'Students',
                        value: '$totalStudents',
                        gradient: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllStudentsPage())),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _glassStatCard(
                        icon: Icons.check_circle_rounded,
                        label: 'Paid',
                        value: '$paidStudents',
                        gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaidUnpaidStudentsPage())),
                      )),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // ── BUS LOCATIONS SUBHEADING ──
                  _glassSubheading('Bus Locations', Icons.directions_bus_rounded),
                  const SizedBox(height: 12),

                  // ── SEARCH BAR ──
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.13), width: 1),
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: _filterLocations,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Search locations...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(10),
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C00FF).withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.search_rounded, color: Color(0xFF00CCFF), size: 18),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── LOCATION COUNT BADGE ──
                  if (filteredLocations.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C00FF).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF6C00FF).withOpacity(0.35)),
                            ),
                            child: Text(
                              '${filteredLocations.length} location${filteredLocations.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Color(0xFFB794F4), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Long press to select & delete',
                            style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
                        ],
                      ),
                    ),

                if (filteredLocations.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Icon(Icons.location_off_rounded, color: Colors.white.withOpacity(0.3), size: 30),
                        ),
                        const SizedBox(height: 14),
                        Text('No locations found',
                          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.35), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                else
                  ...List.generate(filteredLocations.length, (index) {
                            final location = filteredLocations[index];
                            final isLongPressed = _longPressedLocationId == location['id'];
                            // Cycle through accent colors per card
                            final List<List<Color>> cardGradients = [
                              [const Color(0xFF6C00FF), const Color(0xFF0066FF)],
                              [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
                              [const Color(0xFF10B981), const Color(0xFF059669)],
                              [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                              [const Color(0xFFEC4899), const Color(0xFFDB2777)],
                              [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
                            ];
                            final grad = cardGradients[index % cardGradients.length];
                            final accentColor = grad[0];

                            return GestureDetector(
                              onTap: () {
                                if (_longPressedLocationId != null) {
                                  setState(() => _longPressedLocationId = null);
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LocationStudentsPage(locationName: location['name']),
                                  ),
                                );
                              },
                              onLongPress: () {
                                setState(() {
                                  _longPressedLocationId = isLongPressed ? null : location['id'];
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: isLongPressed
                                        ? [Colors.red.withOpacity(0.25), Colors.red.withOpacity(0.12)]
                                        : [accentColor.withOpacity(0.18), accentColor.withOpacity(0.06)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: isLongPressed
                                        ? Colors.redAccent.withOpacity(0.5)
                                        : accentColor.withOpacity(0.35),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          // Icon container
                                          Container(
                                            width: 48, height: 48,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [accentColor.withOpacity(0.5), accentColor.withOpacity(0.25)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: accentColor.withOpacity(0.4), width: 1),
                                            ),
                                            child: isLongPressed
                                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                                                : Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
                                          ),
                                          const SizedBox(width: 14),
                                          // Text content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  location['name'],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    letterSpacing: 0.1,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: accentColor.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: accentColor.withOpacity(0.35), width: 0.8),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.currency_rupee_rounded, color: accentColor, size: 11),
                                                          Text(
                                                            '${location['fee']}',
                                                            style: TextStyle(
                                                              color: accentColor,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Bus Fee',
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.4),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveBackground extends StatefulWidget {
  const _WaveBackground();

  @override
  State<_WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<_WaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(_controller.value),
          child: Container(),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animValue;
  _WavePainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE0F7FA), Color(0xFFE8F5E9)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    _drawWave(canvas, size, animValue, const Color(0x4000BCD4), 0.35, 0.0);
    _drawWave(canvas, size, animValue, const Color(0x3066BB6A), 0.45, 0.3);
    _drawWave(canvas, size, animValue, const Color(0x3029B6F6), 0.55, 0.6);
  }

  void _drawWave(Canvas canvas, Size size, double anim, Color color,
      double heightRatio, double offset) {
    final paint = Paint()..color = color;
    final path = Path();
    final waveHeight = size.height * 0.06;
    final baseY = size.height * heightRatio;
    final phase = (anim + offset) * 2 * math.pi;

    path.moveTo(0, baseY);
    for (double x = 0; x <= size.width; x++) {
      final y = baseY + math.sin((x / size.width * 2 * math.pi) + phase) * waveHeight;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.animValue != animValue;
}

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController feeController = TextEditingController();

  InputDecoration _glassInputDec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF6C00FF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: const Color(0xFF00CCFF), size: 17),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6C00FF), width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6C00FF), Color(0xFF0066FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text('Add Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.14)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF060818), Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),
          // Glow orbs
          Positioned(top: -80, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF6C00FF).withOpacity(0.22), Colors.transparent])))),
          Positioned(bottom: -60, right: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF0066FF).withOpacity(0.15), Colors.transparent])))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                child: Column(
                  children: [
                    // Header icon + title
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6C00FF), Color(0xFF0066FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: const Color(0xFF6C00FF).withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 16),
                    const Text('New Bus Location', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                    const SizedBox(height: 6),
                    Text('Fill in the details to add a new route', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                    const SizedBox(height: 32),

                    // Glass form card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Location name field
                              Text('Location Name', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: nameController,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                decoration: _glassInputDec('e.g. Coimbatore North', Icons.location_on_rounded),
                              ),
                              const SizedBox(height: 20),

                              // Fee field
                              Text('Bus Fee Amount', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: feeController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                decoration: _glassInputDec('e.g. 2500', Icons.currency_rupee_rounded),
                              ),
                              const SizedBox(height: 28),

                              // Submit button
                              GestureDetector(
                                onTap: () {
                                  if (nameController.text.isNotEmpty && feeController.text.isNotEmpty) {
                                    Navigator.pop(context, {'name': nameController.text, 'fee': double.parse(feeController.text)});
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF6C00FF), Color(0xFF0066FF)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [BoxShadow(color: const Color(0xFF6C00FF).withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 6))],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 10),
                                      Text('Add Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.2)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

class EditLocationPage extends StatefulWidget {
  final String locationId;
  final String locationName;
  final double currentFee;

  const EditLocationPage({
    super.key,
    required this.locationId,
    required this.locationName,
    required this.currentFee,
  });

  @override
  State<EditLocationPage> createState() => _EditLocationPageState();
}

class _EditLocationPageState extends State<EditLocationPage> {
  late TextEditingController nameController;
  late TextEditingController feeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.locationName);
    feeController = TextEditingController(text: widget.currentFee.toStringAsFixed(0));
  }

  @override
  void dispose() {
    nameController.dispose();
    feeController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final newName = nameController.text.trim();
    final newFee = double.tryParse(feeController.text.trim());
    if (newName.isEmpty || newFee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.updateLocation(widget.locationId, newName, newFee);
      // Update totalDue & location name for all students in this location
      final students = await ApiService.getStudents();
      for (final s in students) {
        if (s['location']?.toString() == widget.locationName) {
          final phone = s['phone']?.toString() ?? '';
          if (phone.isNotEmpty) {
            await ApiService.updateStudent(phone, {
              ...Map<String, dynamic>.from(s),
              'location': newName,
              'totalDue': newFee,
            });
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _glassDec(String label, IconData icon, Color accent) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
    prefixIcon: Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.18),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: accent, size: 17),
    ),
    filled: true,
    fillColor: Colors.white.withOpacity(0.06),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accent, width: 1.5)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6C00FF), Color(0xFF0066FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [BoxShadow(color: const Color(0xFF6C00FF).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.edit_location_alt_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text('Edit Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.14)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF060818), Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),
          Positioned(top: -80, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF6C00FF).withOpacity(0.2), Colors.transparent])))),
          Positioned(bottom: -60, right: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF0066FF).withOpacity(0.14), Colors.transparent])))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6C00FF), Color(0xFF0066FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFF6C00FF).withOpacity(0.45), blurRadius: 22, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.edit_location_alt_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 14),
                    const Text('Edit Bus Location', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text('Update name and fee for this route', style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 12)),
                    const SizedBox(height: 28),

                    // Info banner — current values
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C00FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF6C00FF).withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Color(0xFF6C00FF), size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Editing: ${widget.locationName}  •  ₹${widget.currentFee.toStringAsFixed(0)}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.11), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Location Name
                              Text('Location Name', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: nameController,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                decoration: _glassDec('e.g. Coimbatore North', Icons.location_on_rounded, const Color(0xFF6C00FF)),
                              ),
                              const SizedBox(height: 18),

                              // Fee
                              Text('Bus Fee Amount', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: feeController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                decoration: _glassDec('e.g. 2500', Icons.currency_rupee_rounded, const Color(0xFF10B981)),
                              ),
                              const SizedBox(height: 24),

                              // Impact note
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.22)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 15),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'This will update the fee for all students assigned to this location.',
                                        style: TextStyle(color: const Color(0xFFF59E0B).withOpacity(0.85), fontSize: 11, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),

                              // Save button
                              GestureDetector(
                                onTap: _isLoading ? null : _update,
                                child: Container(
                                  width: double.infinity,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF6C00FF), Color(0xFF0066FF)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [BoxShadow(color: const Color(0xFF6C00FF).withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6))],
                                  ),
                                  child: _isLoading
                                      ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save_rounded, color: Colors.white, size: 20),
                                            SizedBox(width: 10),
                                            Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.2)),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

class AdminRolePage extends StatefulWidget {
  const AdminRolePage({super.key});

  @override
  State<AdminRolePage> createState() => _AdminRolePageState();
}

class _AdminRolePageState extends State<AdminRolePage> {
  bool _isLoading = true;
  Map<String, double> _locationData = {};
  Map<String, int> _locationCountData = {};
  Map<String, double> _yearData = {};
  Map<String, int> _yearCountData = {};
  int _totalStudents = 0;
  int _paidStudents = 0;
  double _totalCollection = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final students = await ApiService.getStudents();
      final Map<String, double> locationMap = {};
      final Map<String, int> locationCountMap = {};
      final Map<String, double> yearMap = {};
      final Map<String, int> yearCountMap = {};
      double total = 0;
      int paid = 0;

      for (var s in students) {
        final amount = (s['amountPaid'] as num?)?.toDouble() ?? 0;
        final loc = s['location']?.toString() ?? 'Unknown';

        if (loc.isNotEmpty && loc != 'Unknown') {
          locationCountMap[loc] = (locationCountMap[loc] ?? 0) + 1;
        }

        // Count all students per year
        final dateStr = s['lastUpdated'] ?? s['registrationDate'];
        if (dateStr != null) {
          try {
            final year = DateTime.parse(dateStr).year.toString();
            yearCountMap[year] = (yearCountMap[year] ?? 0) + 1;
          } catch (_) {}
        }

        if (amount <= 0) continue;
        paid++;
        total += amount;

        locationMap[loc] = (locationMap[loc] ?? 0) + amount;

        if (dateStr != null) {
          try {
            final year = DateTime.parse(dateStr).year.toString();
            yearMap[year] = (yearMap[year] ?? 0) + amount;
          } catch (_) {}
        }
      }

      setState(() {
        _locationData = locationMap;
        _locationCountData = locationCountMap;
        _yearData = yearMap;
        _yearCountData = yearCountMap;
        _totalStudents = students.length;
        _paidStudents = paid;
        _totalCollection = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatAmount(double value) {
    if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(0)}K';
    return '₹${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6C00FF), Color(0xFF0066FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text('Admin Role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.14)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C00FF)))
          : Stack(
              children: [
                // Background gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF060818), Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                      stops: [0.0, 0.3, 0.65, 1.0],
                    ),
                  ),
                ),
                // Glow orbs
                Positioned(top: -80, left: -80,
                  child: Container(width: 280, height: 280,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [const Color(0xFF6C00FF).withOpacity(0.2), Colors.transparent])))),
                Positioned(bottom: -60, right: -60,
                  child: Container(width: 240, height: 240,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [const Color(0xFF0EA5E9).withOpacity(0.15), Colors.transparent])))),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── STAT CARDS ──
                        Row(
                          children: [
                            _summaryCard('Students', '$_totalStudents', Icons.people_rounded, const Color(0xFF6C00FF)),
                            const SizedBox(width: 10),
                            _summaryCard('Paid', '$_paidStudents', Icons.check_circle_rounded, const Color(0xFF10B981)),
                            const SizedBox(width: 10),
                            _summaryCard('Collection', _formatAmount(_totalCollection), Icons.currency_rupee_rounded, const Color(0xFFF59E0B)),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // ── LOCATION CHART ──
                        _chartCard(
                          title: 'Fees by Location',
                          subtitle: 'Total collected per bus route',
                          icon: Icons.location_on_rounded,
                          color: const Color(0xFF6C00FF),
                          child: _locationData.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 28),
                                  child: Center(child: Text('No data available', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13))),
                                )
                              : SizedBox(height: 220, child: _LocationBarChart(data: _locationData, countData: _locationCountData, formatAmount: _formatAmount)),
                        ),
                        const SizedBox(height: 16),

                        // ── YEAR CHART ──
                        _chartCard(
                          title: 'Fees by Year',
                          subtitle: 'Year-wise payment trend',
                          icon: Icons.trending_up_rounded,
                          color: const Color(0xFF0EA5E9),
                          child: _yearData.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 28),
                                  child: Center(child: Text('No data available', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13))),
                                )
                              : SizedBox(height: 220, child: _YearLineChart(data: _yearData, countData: _yearCountData, formatAmount: _formatAmount)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.25), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(height: 10),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color, height: 1)),
                const SizedBox(height: 3),
                Text(title, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chartCard({required String title, required String subtitle, required IconData icon, required Color color, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3), width: 1),
                    ),
                    child: Icon(icon, color: color, size: 17),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.1)),
                      Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}


class _LocationBarChart extends StatelessWidget {
  final Map<String, double> data;
  final Map<String, int> countData;
  final String Function(double) formatAmount;

  const _LocationBarChart({required this.data, required this.countData, required this.formatAmount});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxVal = data.values.reduce((a, b) => a > b ? a : b);
    final colors = [
      const Color(0xFF4F46E5), const Color(0xFF10B981), const Color(0xFFF59E0B),
      const Color(0xFFEF4444), const Color(0xFF8B5CF6), const Color(0xFF06B6D4),
    ];

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(entries.length, (i) {
              final ratio = entries[i].value / maxVal;
              final location = entries[i].key;
              final count = countData[location] ?? 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Total students count on top
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors[i % colors.length].withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count students',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: colors[i % colors.length],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Fee amount
                      Text(
                        formatAmount(entries[i].value),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        height: 150 * ratio,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [colors[i % colors.length], colors[i % colors.length].withOpacity(0.6)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(entries.length, (i) {
            return Expanded(
              child: Text(
                entries[i].key.length > 8 ? '${entries[i].key.substring(0, 7)}..' : entries[i].key,
                style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.45)),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _YearLineChart extends StatelessWidget {
  final Map<String, double> data;
  final Map<String, int> countData;
  final String Function(double) formatAmount;

  const _YearLineChart({required this.data, required this.countData, required this.formatAmount});

  @override
  Widget build(BuildContext context) {
    final allYears = ['2026', '2027', '2028', '2029', '2030'];
    final values = allYears.map((y) => data[y] ?? 0).toList();
    final counts = allYears.map((y) => countData[y] ?? 0).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1.0 : maxVal;

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, 160),
            painter: _LineChartPainter(values: values, maxVal: safeMax),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(allYears.length, (i) {
            return Column(
              children: [
                // Total students count
                if (counts[i] > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${counts[i]} students',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                if (values[i] > 0)
                  Text(
                    formatAmount(values[i]),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF00CCFF)),
                  ),
                Text(allYears[i], style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.45))),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxVal;

  _LineChartPainter({required this.values, required this.maxVal});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final linePaint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF4F46E5).withOpacity(0.3), const Color(0xFF4F46E5).withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..style = PaintingStyle.fill;

    final points = List.generate(values.length, (i) {
      final x = i * size.width / (values.length - 1);
      final y = size.height - (values[i] / maxVal) * size.height * 0.85 - 10;
      return Offset(x, y);
    });

    // Fill path
    final fillPath = Path();
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line path
    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(p, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class UploadStudentDataPage extends StatefulWidget {
  const UploadStudentDataPage({super.key});

  @override
  State<UploadStudentDataPage> createState() => _UploadStudentDataPageState();
}

class _UploadStudentDataPageState extends State<UploadStudentDataPage> {
  bool _isUploading = false;
  bool _isSubmitting = false;
  List<dynamic> _students = [];
  String? _longPressedStudentId;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    phoneController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final students = await ApiService.getStudents();
    setState(() => _students = students);
  }

  Future<void> _submitStudent() async {
    if (phoneController.text.isEmpty || dobController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Check for duplicate phone + dob
      final existing = _students.any(
        (s) => s['phone']?.toString() == phoneController.text.trim() &&
               s['dob']?.toString().split('T')[0] == dobController.text.trim(),
      );

      if (existing) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Duplicate Entry'),
              content: Text(
                'Student with Phone: ${phoneController.text} and DOB: ${dobController.text} already exists.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }
      await ApiService.addStudent({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': '',
        'rollNo': '',
        'studentClass': '',
        'parentName': '',
        'phone': phoneController.text,
        'email': '',
        'address': '',
        'location': '',
        'dob': dobController.text,
        'totalDue': 0,
        'amountPaid': 0,
        'status': 'pending',
        'lastUpdated': DateTime.now().toIso8601String(),
        'payments': [],
        'locationHistory': [],
      });

      await _loadStudents();
      phoneController.clear();
      dobController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickAndUploadExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      setState(() => _isUploading = true);
      try {
        final file = File(result.files.single.path!);
        final bytes = file.readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);
        int count = 0;

        for (var table in excel.tables.keys) {
          for (var row in excel.tables[table]!.rows.skip(1)) {
            if (row.length >= 2) {
              final phone = row[0]?.value?.toString() ?? '';
              final dobStr = row[1]?.value?.toString() ?? '';
              
              await ApiService.addStudent({
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'name': '',
                'rollNo': '',
                'studentClass': '',
                'parentName': '',
                'phone': phone,
                'email': '',
                'address': '',
                'location': '',
                'dob': dobStr,
                'totalDue': 0,
                'amountPaid': 0,
                'status': 'pending',
                'lastUpdated': DateTime.now().toIso8601String(),
                'payments': [],
                'locationHistory': [],
              });
              count++;
            }
          }
        }

        await _loadStudents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count students uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Upload error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  InputDecoration _glassInput(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.18),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: const Color(0xFF10B981), size: 17),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text('Student Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
                      const Spacer(),
                      if (_longPressedStudentId != null)
                        GestureDetector(
                          onTap: () async {
                            final student = _students.firstWhere(
                              (s) => (s['_id'] ?? s['id'])?.toString() == _longPressedStudentId,
                            );
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Student'),
                                content: Text('Move ${student['phone']} to recycle bin?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ApiService.deleteStudent(_longPressedStudentId!);
                              setState(() => _longPressedStudentId = null);
                              await _loadStudents();
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student moved to recycle bin'), backgroundColor: Colors.orange));
                            }
                          },
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withOpacity(0.4)),
                            ),
                            child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 17),
                          ),
                        ),
                      if (_longPressedStudentId != null) const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.14)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF060818), Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),
          Positioned(top: -80, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF10B981).withOpacity(0.18), Colors.transparent])))),
          Positioned(bottom: -60, right: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF6C00FF).withOpacity(0.14), Colors.transparent])))),
          SafeArea(
            child: Column(
              children: [
                // ── INPUT FORM ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withOpacity(0.11), width: 1),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _glassInput('Phone Number', Icons.phone_rounded),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: dobController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _glassInput('Date of Birth (YYYY-MM-DD)', Icons.calendar_today_rounded),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _isSubmitting
                                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                                      : GestureDetector(
                                          onTap: _submitStudent,
                                          child: Container(
                                            height: 46,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                              borderRadius: BorderRadius.circular(13),
                                              boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
                                            ),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.person_add_rounded, color: Colors.white, size: 17),
                                                SizedBox(width: 7),
                                                Text('Add Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _isUploading
                                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C00FF)))
                                      : GestureDetector(
                                          onTap: _pickAndUploadExcel,
                                          child: Container(
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.07),
                                              borderRadius: BorderRadius.circular(13),
                                              border: Border.all(color: const Color(0xFF6C00FF).withOpacity(0.4), width: 1),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.upload_file_rounded, color: const Color(0xFF6C00FF).withOpacity(0.9), size: 17),
                                                const SizedBox(width: 7),
                                                Text('Upload Excel', style: TextStyle(color: const Color(0xFF6C00FF).withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── STUDENT COUNT BADGE ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_rounded, color: Color(0xFF10B981), size: 14),
                                const SizedBox(width: 6),
                                Text('${_students.length} student${_students.length == 1 ? '' : 's'}',
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Long press to select & delete',
                        style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── STUDENT LIST ──
                Expanded(
                  child: _students.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Icon(Icons.person_off_rounded, color: Colors.white.withOpacity(0.25), size: 28),
                              ),
                              const SizedBox(height: 12),
                              Text('No students yet', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final studentId = (student['_id'] ?? student['id'])?.toString();
                            final isSelected = _longPressedStudentId == studentId;
                            final colors = [
                              const Color(0xFF10B981), const Color(0xFF6C00FF),
                              const Color(0xFF0EA5E9), const Color(0xFFF59E0B),
                              const Color(0xFFEC4899), const Color(0xFF8B5CF6),
                            ];
                            final accent = colors[index % colors.length];
                            return GestureDetector(
                              onTap: () { if (_longPressedStudentId != null) setState(() => _longPressedStudentId = null); },
                              onLongPress: () => setState(() => _longPressedStudentId = isSelected ? null : studentId),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: isSelected ? Colors.red.withOpacity(0.12) : accent.withOpacity(0.08),
                                  border: Border.all(
                                    color: isSelected ? Colors.redAccent.withOpacity(0.5) : accent.withOpacity(0.25),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42, height: 42,
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.red.withOpacity(0.2) : accent.withOpacity(0.18),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: isSelected ? Colors.redAccent.withOpacity(0.4) : accent.withOpacity(0.3), width: 1),
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check_rounded, color: Colors.redAccent, size: 20)
                                                : Center(child: Text(
                                                    (student['phone']?.toString() ?? 'P').substring(0, 1),
                                                    style: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.w800),
                                                  )),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(student['phone'] ?? 'No Phone',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: accent.withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        'DOB: ${student['dob']?.toString().split('T')[0] ?? 'N/A'}',
                                                        style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.person_rounded, color: Colors.white.withOpacity(0.2), size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class LocationStudentsPage extends StatefulWidget {
  final String locationName;

  const LocationStudentsPage({super.key, required this.locationName});

  @override
  State<LocationStudentsPage> createState() => _LocationStudentsPageState();
}

class _LocationStudentsPageState extends State<LocationStudentsPage> {
  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final allStudents = await ApiService.getStudents();
      setState(() {
        _students = allStudents.where((s) => s['location'] == widget.locationName).toList();
        _filteredStudents = _students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((s) {
          final name = (s['name'] ?? '').toString().toLowerCase();
          final rollNo = (s['rollNo'] ?? '').toString().toLowerCase();
          final phone = (s['phone'] ?? '').toString().toLowerCase();
          final studentClass = (s['studentClass'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) ||
                 rollNo.contains(searchLower) ||
                 phone.contains(searchLower) ||
                 studentClass.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _deleteStudent(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteStudent(id);
        _loadStudents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student moved to recycle bin'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(widget.locationName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.14)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF060818), Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),
          Positioned(top: -80, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF0EA5E9).withOpacity(0.18), Colors.transparent])))),
          Positioned(bottom: -60, right: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF6C00FF).withOpacity(0.14), Colors.transparent])))),
          SafeArea(
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterStudents,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search students...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.search_rounded, color: Color(0xFF0EA5E9), size: 17),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Student count badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_rounded, color: Color(0xFF0EA5E9), size: 13),
                            const SizedBox(width: 5),
                            Text(
                              '${_filteredStudents.length} student${_filteredStudents.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Color(0xFF0EA5E9), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Student list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
                      : _filteredStudents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Icon(Icons.person_search_rounded, color: Colors.white.withOpacity(0.25), size: 28),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('No students found',
                                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = _filteredStudents[index];
                                final accents = [
                                  const Color(0xFF0EA5E9), const Color(0xFF6C00FF),
                                  const Color(0xFF10B981), const Color(0xFFF59E0B),
                                  const Color(0xFFEC4899), const Color(0xFF8B5CF6),
                                ];
                                final accent = accents[index % accents.length];
                                final name = student['name']?.toString() ?? '';
                                final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: accent.withOpacity(0.07),
                                    border: Border.all(color: accent.withOpacity(0.22), width: 1),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44, height: 44,
                                              decoration: BoxDecoration(
                                                color: accent.withOpacity(0.18),
                                                borderRadius: BorderRadius.circular(13),
                                                border: Border.all(color: accent.withOpacity(0.3), width: 1),
                                              ),
                                              child: Center(
                                                child: Text(initial,
                                                  style: TextStyle(color: accent, fontSize: 17, fontWeight: FontWeight.w800)),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name.isNotEmpty ? name : 'No Name',
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      if ((student['rollNo']?.toString() ?? '').isNotEmpty) ...[
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: accent.withOpacity(0.14),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            'Roll: ${student['rollNo']}',
                                                            style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                      ],
                                                      if ((student['studentClass']?.toString() ?? '').isNotEmpty)
                                                        Text(
                                                          'Class: ${student['studentClass']}',
                                                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StudentSearchDelegate extends SearchDelegate {
  final List<dynamic> students;

  StudentSearchDelegate(this.students);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = students.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final rollNo = (s['rollNo'] ?? '').toString().toLowerCase();
      final phone = (s['phone'] ?? '').toString().toLowerCase();
      final studentClass = (s['studentClass'] ?? '').toString().toLowerCase();
      final searchLower = query.toLowerCase();
      return name.contains(searchLower) ||
             rollNo.contains(searchLower) ||
             phone.contains(searchLower) ||
             studentClass.contains(searchLower);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final student = results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF4F46E5),
              child: Text(
                student['name']?.isNotEmpty == true ? student['name'][0] : 'S',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(student['name'] ?? 'No Name'),
            subtitle: Text('Roll: ${student['rollNo']} | Class: ${student['studentClass']}'),
            trailing: Text('₹${student['totalDue']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

class RecycleBinPage extends StatefulWidget {
  const RecycleBinPage({super.key});

  @override
  State<RecycleBinPage> createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends State<RecycleBinPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _students = [];
  List<dynamic> _locations = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final items = await ApiService.getRecycleBin();
      setState(() {
        _students = items.where((i) => i['type'] == 'student').toList();
        _locations = items.where((i) => i['type'] == 'location').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restore(String id) async {
    try {
      await ApiService.restoreFromRecycleBin(id);
      _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restored successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _permanentDelete(String id) async {
    try {
      await ApiService.permanentlyDelete(id);
      _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permanently deleted!'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildCard(dynamic item) {
    if (item == null) return const SizedBox.shrink();
    final type = item['type']?.toString() ?? 'unknown';
    final id = (item['_id'] ?? item['id'])?.toString() ?? '';
    final isStudent = type == 'student';
    final accent = isStudent ? const Color(0xFF6C00FF) : const Color(0xFFF59E0B);

    final String title = isStudent
        ? ((item['name']?.toString().isNotEmpty == true) ? item['name'].toString() : item['phone']?.toString() ?? 'Student')
        : item['name']?.toString() ?? 'Location';
    final String line1 = isStudent ? 'Phone: ${item['phone'] ?? 'N/A'}' : 'Fee: ₹${item['fee'] ?? 'N/A'}';
    final String line2 = isStudent
        ? 'DOB: ${item['dob']?.toString().split('T')[0] ?? 'N/A'}'
        : 'Deleted: ${item['deletedAt']?.toString().split('T')[0] ?? 'N/A'}';
    final String deletedAt = isStudent ? 'Deleted: ${item['deletedAt']?.toString().split('T')[0] ?? ''}' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: accent.withOpacity(0.07),
        border: Border.all(color: accent.withOpacity(0.22), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: accent.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(
                    isStudent ? Icons.person_rounded : Icons.location_on_rounded,
                    color: accent, size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(line1, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
                      Text(line2, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
                      if (isStudent && deletedAt.isNotEmpty)
                        Text(deletedAt, style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 10)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: id.isEmpty ? null : () => _restore(id),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.restore_rounded, color: Color(0xFF10B981), size: 17),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: id.isEmpty ? null : () => _permanentDelete(id),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 17),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: Colors.white.withOpacity(0.25), size: 30),
        ),
        const SizedBox(height: 14),
        Text(message, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text('Recycle Bin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.14)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF060818), Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),
          Positioned(top: -80, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFFF59E0B).withOpacity(0.14), Colors.transparent])))),
          Positioned(bottom: -60, right: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF6C00FF).withOpacity(0.14), Colors.transparent])))),
          SafeArea(
            child: Column(
              children: [
                // Tab bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFFF59E0B),
                          unselectedLabelColor: Colors.white.withOpacity(0.35),
                          indicatorColor: const Color(0xFFF59E0B),
                          indicatorWeight: 2,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_rounded, size: 15),
                                  const SizedBox(width: 6),
                                  Text('Students (${_students.length})'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 15),
                                  const SizedBox(width: 6),
                                  Text('Locations (${_locations.length})'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _students.isEmpty
                                ? _emptyState('No deleted students', Icons.person_off_rounded)
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                    itemCount: _students.length,
                                    itemBuilder: (_, i) => _buildCard(_students[i]),
                                  ),
                            _locations.isEmpty
                                ? _emptyState('No deleted locations', Icons.location_off_rounded)
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                    itemCount: _locations.length,
                                    itemBuilder: (_, i) => _buildCard(_locations[i]),
                                  ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await ApiService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
      // Mark all as read
      for (final n in notifications) {
        final id = (n['_id'] ?? n['id'])?.toString();
        if (id != null && n['read'] != true) {
          ApiService.markNotificationRead(id).catchError((_) {});
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await ApiService.deleteNotification(id);
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        iconTheme: const IconThemeData(color: Color(0xFF4F46E5)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_rounded,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No notifications',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    final id = (n['_id'] ?? n['id'])?.toString() ?? '';
                    final type = n['type']?.toString() ?? 'payment';
                    final isPayment = type == 'payment';
                    final isUnread = n['read'] != true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isUnread
                            ? const Color(0xFFEEF2FF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUnread
                              ? const Color(0xFFC7D2FE)
                              : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isPayment
                                ? const Color(0xFF10B981).withOpacity(0.1)
                                : const Color(0xFF4F46E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isPayment
                                ? Icons.receipt_long_rounded
                                : Icons.feedback_rounded,
                            color: isPayment
                                ? const Color(0xFF10B981)
                                : const Color(0xFF4F46E5),
                            size: 22,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                n['studentName'] ?? 'Student',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPayment
                                    ? const Color(0xFF10B981).withOpacity(0.1)
                                    : const Color(0xFF4F46E5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPayment ? 'PAYMENT' : 'FEEDBACK',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isPayment
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF4F46E5),
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              n['message'] ?? (isPayment
                                  ? 'Phone: ${n['phone'] ?? ''}  |  ₹${n['amount'] ?? 0}'
                                  : n['message'] ?? ''),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B)),
                            ),
                            if (n['createdAt'] != null)
                              Text(
                                n['createdAt'].toString().split('T')[0],
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8)),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_rounded,
                              color: Colors.red, size: 20),
                          onPressed: id.isEmpty
                              ? null
                              : () => _deleteNotification(id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: color.withOpacity(0.07),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3), width: 1),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                      ],
                    ),
                  ),
                  trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Text(label.toUpperCase(),
      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6C00FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.14)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF060818), Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),
          Positioned(top: -80, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF8B5CF6).withOpacity(0.18), Colors.transparent])))),
          Positioned(bottom: -60, right: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF6C00FF).withOpacity(0.14), Colors.transparent])))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withOpacity(0.11), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6C00FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
                              ),
                              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Administrator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                                  const SizedBox(height: 3),
                                  Text('Bus Fees Management System', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                              ),
                              child: const Text('Active', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // General section
                  _sectionLabel('General'),
                  _settingsTile(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    subtitle: 'Manage push notifications',
                    color: const Color(0xFF6C00FF),
                  ),
                  _settingsTile(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    subtitle: 'English (Default)',
                    color: const Color(0xFF0EA5E9),
                  ),
                  _settingsTile(
                    icon: Icons.dark_mode_rounded,
                    title: 'Appearance',
                    subtitle: 'Dark mode enabled',
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 8),

                  // Data section
                  _sectionLabel('Data & Privacy'),
                  _settingsTile(
                    icon: Icons.backup_rounded,
                    title: 'Backup Data',
                    subtitle: 'Export all records',
                    color: const Color(0xFF10B981),
                  ),
                  _settingsTile(
                    icon: Icons.security_rounded,
                    title: 'Security',
                    subtitle: 'Password & access control',
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 8),

                  // About section
                  _sectionLabel('About'),
                  _settingsTile(
                    icon: Icons.info_rounded,
                    title: 'App Version',
                    subtitle: 'v1.0.0 — Bus Fees System',
                    color: const Color(0xFF00CCFF),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00CCFF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Latest', style: TextStyle(color: Color(0xFF00CCFF), fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Coming soon banner
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.construction_rounded, color: const Color(0xFF8B5CF6).withOpacity(0.7), size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('More settings coming soon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text('Additional configuration options will be available in future updates.',
                                    style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
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


class AllStudentsPage extends StatefulWidget {
  const AllStudentsPage({super.key});

  @override
  State<AllStudentsPage> createState() => _AllStudentsPageState();
}

class _AllStudentsPageState extends State<AllStudentsPage> {
  List<dynamic> _students = [];
  bool _isLoading = true;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await ApiService.getStudents();
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Students'),
        content: Text('Move ${_selectedIds.length} student(s) to recycle bin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      for (final id in _selectedIds) {
        await ApiService.deleteStudent(id);
      }
      setState(() => _selectedIds.clear());
      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Students moved to recycle bin'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.people_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedIds.isEmpty ? 'All Students' : '${_selectedIds.length} Selected',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3),
                        ),
                      ),
                      if (_selectedIds.isNotEmpty)
                        GestureDetector(
                          onTap: _deleteSelected,
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withOpacity(0.4)),
                            ),
                            child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 17),
                          ),
                        ),
                      if (_selectedIds.isNotEmpty) const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.14)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF060818), Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),
          Positioned(top: -80, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF0EA5E9).withOpacity(0.18), Colors.transparent])))),
          Positioned(bottom: -60, right: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF6C00FF).withOpacity(0.14), Colors.transparent])))),
          SafeArea(
            child: Column(
              children: [
                // Count badge
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_rounded, color: Color(0xFF0EA5E9), size: 13),
                            const SizedBox(width: 5),
                            Text(
                              '${_students.length} student${_students.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Color(0xFF0EA5E9), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Long press to select & delete',
                        style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Student list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
                      : _students.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Icon(Icons.person_off_rounded, color: Colors.white.withOpacity(0.25), size: 28),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('No students found',
                                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                final id = (student['_id'] ?? student['id'])?.toString() ?? '';
                                final isSelected = _selectedIds.contains(id);
                                final accents = [
                                  const Color(0xFF0EA5E9), const Color(0xFF6C00FF),
                                  const Color(0xFF10B981), const Color(0xFFF59E0B),
                                  const Color(0xFFEC4899), const Color(0xFF8B5CF6),
                                ];
                                final accent = accents[index % accents.length];
                                final phone = student['phone']?.toString() ?? '';
                                final initial = phone.isNotEmpty ? phone[0] : 'S';

                                return GestureDetector(
                                  onTap: () {
                                    if (_selectedIds.isNotEmpty) {
                                      setState(() {
                                        isSelected ? _selectedIds.remove(id) : _selectedIds.add(id);
                                      });
                                    }
                                  },
                                  onLongPress: () {
                                    setState(() {
                                      isSelected ? _selectedIds.remove(id) : _selectedIds.add(id);
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      color: isSelected ? Colors.red.withOpacity(0.12) : accent.withOpacity(0.07),
                                      border: Border.all(
                                        color: isSelected ? Colors.redAccent.withOpacity(0.5) : accent.withOpacity(0.22),
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 44, height: 44,
                                                decoration: BoxDecoration(
                                                  color: isSelected ? Colors.red.withOpacity(0.2) : accent.withOpacity(0.18),
                                                  borderRadius: BorderRadius.circular(13),
                                                  border: Border.all(
                                                    color: isSelected ? Colors.redAccent.withOpacity(0.4) : accent.withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: isSelected
                                                    ? const Icon(Icons.check_rounded, color: Colors.redAccent, size: 20)
                                                    : Center(
                                                        child: Text(initial,
                                                          style: TextStyle(color: accent, fontSize: 17, fontWeight: FontWeight.w800)),
                                                      ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(phone.isNotEmpty ? phone : 'No Phone',
                                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: accent.withOpacity(0.14),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            'DOB: ${student['dob']?.toString().split('T')[0] ?? 'N/A'}',
                                                            style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(Icons.person_rounded, color: Colors.white.withOpacity(0.2), size: 18),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditStudentPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const EditStudentPage({super.key, required this.student});

  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  late TextEditingController nameController;
  late TextEditingController rollNoController;
  late TextEditingController classController;
  late TextEditingController parentNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.student['name']);
    rollNoController = TextEditingController(text: widget.student['rollNo']);
    classController = TextEditingController(text: widget.student['studentClass']);
    parentNameController = TextEditingController(text: widget.student['parentName']);
    phoneController = TextEditingController(text: widget.student['phone']);
    emailController = TextEditingController(text: widget.student['email']);
    addressController = TextEditingController(text: widget.student['address']);
  }

  @override
  void dispose() {
    nameController.dispose();
    rollNoController.dispose();
    classController.dispose();
    parentNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _updateStudent() async {
    try {
      final studentId = (widget.student['_id'] ?? widget.student['id'])?.toString() ?? '';
      final phone = widget.student['phone']?.toString() ?? '';

      if (phone.isEmpty) throw Exception('Student phone not found');

      await ApiService.updateStudentById(studentId, {
        'name': nameController.text.trim(),
        'rollNo': rollNoController.text.trim(),
        'studentClass': classController.text.trim(),
        'parentName': parentNameController.text.trim(),
        'phone': phone, // keep original phone for lookup
        'email': emailController.text.trim(),
        'address': addressController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student & Report updated successfully! ✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  InputDecoration _glassDec(String label, IconData icon, Color accent) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
    prefixIcon: Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.18),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: accent, size: 17),
    ),
    filled: true,
    fillColor: Colors.white.withOpacity(0.06),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accent, width: 1.5)),
  );

  @override
  Widget build(BuildContext context) {
    // Accent colors per field
    final fieldAccents = [
      const Color(0xFF6C00FF),
      const Color(0xFF0EA5E9),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF00CCFF),
    ];
    final fields = [
      (nameController,       'Full Name',    Icons.person_rounded,         fieldAccents[0]),
      (rollNoController,     'Roll Number',  Icons.badge_rounded,          fieldAccents[1]),
      (classController,      'Class',        Icons.school_rounded,         fieldAccents[2]),
      (parentNameController, 'Parent Name',  Icons.family_restroom_rounded, fieldAccents[3]),
      (phoneController,      'Phone',        Icons.phone_rounded,          fieldAccents[4]),
      (emailController,      'Email',        Icons.email_rounded,          fieldAccents[5]),
      (addressController,    'Address',      Icons.home_rounded,           fieldAccents[6]),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text('Edit Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.14)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF060818), Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),
          // Glow orbs
          Positioned(top: -80, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF10B981).withOpacity(0.18), Colors.transparent])))),
          Positioned(bottom: -60, right: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF6C00FF).withOpacity(0.14), Colors.transparent])))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.45), blurRadius: 22, offset: const Offset(0, 8))],
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text('Edit Student Info', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text('Update the student details below', style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 12)),
                  const SizedBox(height: 24),

                  // Student info banner
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.09),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.person_pin_rounded, color: Color(0xFF10B981), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.student['name']?.toString().isNotEmpty == true
                                        ? widget.student['name']
                                        : widget.student['phone'] ?? 'Student',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Phone: ${widget.student['phone'] ?? 'N/A'}  •  ${widget.student['location']?.toString().isNotEmpty == true ? widget.student['location'] : 'No location'}',
                                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.student['status'] == 'succeed'
                                    ? const Color(0xFF10B981).withOpacity(0.18)
                                    : const Color(0xFFF59E0B).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: widget.student['status'] == 'succeed'
                                      ? const Color(0xFF10B981).withOpacity(0.35)
                                      : const Color(0xFFF59E0B).withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                widget.student['status'] == 'succeed' ? 'Paid' : 'Pending',
                                style: TextStyle(
                                  color: widget.student['status'] == 'succeed' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.11), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section label
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C00FF).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.edit_note_rounded, color: Color(0xFF6C00FF), size: 15),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Student Details', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                                ],
                              ),
                            ),
                            // All fields
                            ...List.generate(fields.length, (i) {
                              final (ctrl, label, icon, accent) = fields[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: TextField(
                                  controller: ctrl,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                  decoration: _glassDec(label, icon, accent),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            // Save button
                            GestureDetector(
                              onTap: _updateStudent,
                              child: Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6))],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 10),
                                    Text('Update Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.2)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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


class PaidUnpaidStudentsPage extends StatefulWidget {
  const PaidUnpaidStudentsPage({super.key});

  @override
  State<PaidUnpaidStudentsPage> createState() => _PaidUnpaidStudentsPageState();
}

class _PaidUnpaidStudentsPageState extends State<PaidUnpaidStudentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _paidStudents = [];
  List<dynamic> _unpaidStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await ApiService.getStudents();
      setState(() {
        _paidStudents = students.where((s) => s['status'] == 'succeed').toList();
        _unpaidStudents = students.where((s) => s['status'] != 'succeed').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStudentCard(Map<String, dynamic> student, bool isPaid, int index) {
    final accents = [
      const Color(0xFF10B981), const Color(0xFF6C00FF),
      const Color(0xFF0EA5E9), const Color(0xFFF59E0B),
      const Color(0xFFEC4899), const Color(0xFF8B5CF6),
    ];
    final accent = accents[index % accents.length];
    final name = student['name']?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : (student['phone']?.toString().isNotEmpty == true ? student['phone'][0] : 'S');
    final statusColor = isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: accent.withOpacity(0.07),
        border: Border.all(color: accent.withOpacity(0.22), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: accent.withOpacity(0.3), width: 1),
                  ),
                  child: Center(
                    child: Text(initial,
                      style: TextStyle(color: accent, fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : student['phone'] ?? 'N/A',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if ((student['phone']?.toString() ?? '').isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                student['phone'],
                                style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          if ((student['location']?.toString() ?? '').isNotEmpty)
                            Text(
                              student['location'],
                              style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Amount + edit
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.currency_rupee_rounded, color: statusColor, size: 11),
                          Text(
                            isPaid ? '${student['amountPaid'] ?? 0}' : '${student['totalDue'] ?? 0}',
                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditStudentPage(student: student)),
                        );
                        if (result == true) _loadStudents();
                      },
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Icon(Icons.edit_rounded, color: Colors.white.withOpacity(0.6), size: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String message, IconData icon, Color color) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color.withOpacity(0.4), size: 30),
        ),
        const SizedBox(height: 14),
        Text(message, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text('Payment Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.14)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF060818), Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),
          Positioned(top: -80, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF10B981).withOpacity(0.18), Colors.transparent])))),
          Positioned(bottom: -60, right: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFFF59E0B).withOpacity(0.14), Colors.transparent])))),
          SafeArea(
            child: Column(
              children: [
                // Stats row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30, height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${_paidStudents.length}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.w900, height: 1)),
                                      Text('Paid', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30, height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(Icons.pending_rounded, color: Color(0xFFF59E0B), size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${_unpaidStudents.length}', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.w900, height: 1)),
                                      Text('Unpaid', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tab bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFF10B981),
                          unselectedLabelColor: Colors.white.withOpacity(0.35),
                          indicatorColor: const Color(0xFF10B981),
                          indicatorWeight: 2,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 15),
                                  const SizedBox(width: 6),
                                  Text('Paid (${_paidStudents.length})'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.pending_rounded, size: 15, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 6),
                                  Text('Unpaid (${_unpaidStudents.length})',
                                    style: TextStyle(color: _tabController.index == 1 ? const Color(0xFFF59E0B) : null)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _paidStudents.isEmpty
                                ? _emptyState('No paid students yet', Icons.check_circle_outline_rounded, const Color(0xFF10B981))
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                    itemCount: _paidStudents.length,
                                    itemBuilder: (context, index) => _buildStudentCard(_paidStudents[index], true, index),
                                  ),
                            _unpaidStudents.isEmpty
                                ? _emptyState('All students have paid!', Icons.celebration_rounded, const Color(0xFF10B981))
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                    itemCount: _unpaidStudents.length,
                                    itemBuilder: (context, index) => _buildStudentCard(_unpaidStudents[index], false, index),
                                  ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AllLocationsPage extends StatefulWidget {
  const AllLocationsPage({super.key});

  @override
  State<AllLocationsPage> createState() => _AllLocationsPageState();
}

class _AllLocationsPageState extends State<AllLocationsPage> {
  List<dynamic> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await ApiService.getLocations();
      setState(() {
        _locations = locations.map((loc) => {
          ...loc,
          'id': (loc['_id'] ?? loc['id'])?.toString() ?? '',
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editLocation(Map<String, dynamic> location) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLocationPage(
          locationId: location['id'],
          locationName: location['name'],
          currentFee: location['fee'].toDouble(),
        ),
      ),
    );
    if (result == true) _loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6C00FF), Color(0xFF0066FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text('All Locations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.14)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF060818), Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),
          Positioned(top: -80, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF6C00FF).withOpacity(0.18), Colors.transparent])))),
          Positioned(bottom: -60, right: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF0066FF).withOpacity(0.14), Colors.transparent])))),
          SafeArea(
            child: Column(
              children: [
                // Count badge
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C00FF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF6C00FF).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFFB794F4), size: 13),
                            const SizedBox(width: 5),
                            Text(
                              '${_locations.length} location${_locations.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Color(0xFFB794F4), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Location list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C00FF)))
                      : _locations.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Icon(Icons.location_off_rounded, color: Colors.white.withOpacity(0.25), size: 28),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('No locations found',
                                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _locations.length,
                              itemBuilder: (context, index) {
                                final location = _locations[index];
                                final accents = [
                                  const Color(0xFF6C00FF), const Color(0xFF0EA5E9),
                                  const Color(0xFF10B981), const Color(0xFFF59E0B),
                                  const Color(0xFFEC4899), const Color(0xFF8B5CF6),
                                ];
                                final accent = accents[index % accents.length];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: accent.withOpacity(0.07),
                                    border: Border.all(color: accent.withOpacity(0.22), width: 1),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        child: Row(
                                          children: [
                                            // Icon
                                            Container(
                                              width: 44, height: 44,
                                              decoration: BoxDecoration(
                                                color: accent.withOpacity(0.18),
                                                borderRadius: BorderRadius.circular(13),
                                                border: Border.all(color: accent.withOpacity(0.3), width: 1),
                                              ),
                                              child: Icon(Icons.location_on_rounded, color: accent, size: 22),
                                            ),
                                            const SizedBox(width: 12),
                                            // Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    location['name'] ?? 'Unknown',
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: accent.withOpacity(0.14),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.currency_rupee_rounded, color: accent, size: 11),
                                                        Text(
                                                          '${location['fee'] ?? 0}  Bus Fee',
                                                          style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Edit button
                                            GestureDetector(
                                              onTap: () => _editLocation(location),
                                              child: Container(
                                                width: 34, height: 34,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                                ),
                                                child: Icon(Icons.edit_rounded, color: Colors.white.withOpacity(0.6), size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  List<dynamic> _feedbacks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    try {
      final notifications = await ApiService.getNotifications();
      setState(() {
        _feedbacks = notifications
            .where((n) => n['type']?.toString() == 'feedback')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060818),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.feedback_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text('Student Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.14)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF060818), Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
                stops: [0.0, 0.3, 0.65, 1.0],
              ),
            ),
          ),
          // Glow orbs
          Positioned(top: -80, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF10B981).withOpacity(0.18), Colors.transparent])))),
          Positioned(bottom: -60, right: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF6C00FF).withOpacity(0.14), Colors.transparent])))),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _feedbacks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Icon(Icons.feedback_outlined, color: Colors.white.withOpacity(0.25), size: 32),
                            ),
                            const SizedBox(height: 16),
                            Text('No feedback yet', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text('Student feedback will appear here', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: _feedbacks.length,
                        itemBuilder: (context, index) {
                          final fb = _feedbacks[index];
                          final name = fb['studentName']?.toString() ?? 'Student';
                          final phone = fb['phone']?.toString() ?? '';
                          final message = fb['message']?.toString() ?? '';
                          final date = fb['createdAt']?.toString().split('T')[0] ?? '';
                          final accents = [
                            const Color(0xFF10B981), const Color(0xFF6C00FF),
                            const Color(0xFF0EA5E9), const Color(0xFFF59E0B),
                            const Color(0xFFEC4899), const Color(0xFF8B5CF6),
                          ];
                          final accent = accents[index % accents.length];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: accent.withOpacity(0.07),
                              border: Border.all(color: accent.withOpacity(0.22), width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header row
                                      Row(
                                        children: [
                                          Container(
                                            width: 44, height: 44,
                                            decoration: BoxDecoration(
                                              color: accent.withOpacity(0.18),
                                              borderRadius: BorderRadius.circular(13),
                                              border: Border.all(color: accent.withOpacity(0.35), width: 1),
                                            ),
                                            child: Icon(Icons.person_rounded, color: accent, size: 22),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(name,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.1)),
                                                if (phone.isNotEmpty)
                                                  Text(phone,
                                                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                          if (date.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: accent.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: accent.withOpacity(0.25)),
                                              ),
                                              child: Text(date,
                                                style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w600)),
                                            ),
                                        ],
                                      ),
                                      if (message.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        // Divider line
                                        Container(
                                          height: 1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [accent.withOpacity(0.3), Colors.transparent],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Message bubble
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(13),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.format_quote_rounded, color: accent.withOpacity(0.5), size: 16),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(message,
                                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.5)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
