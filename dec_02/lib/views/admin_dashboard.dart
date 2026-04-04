
import 'package:flutter/material.dart';
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
  final TextEditingController searchController = TextEditingController();
  String? _longPressedLocationId;
  bool _notificationShown = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadStudentCount();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          if (_longPressedLocationId != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete location',
              onPressed: () async {
                final loc = locations.firstWhere((l) => l['id'] == _longPressedLocationId);
                await _deleteLocation(loc['id'], loc['name']);
                setState(() => _longPressedLocationId = null);
              },
            ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          ),
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _WaveBackground()),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isMenuExpanded = !isMenuExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF4F46E5), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isMenuExpanded ? Icons.keyboard_double_arrow_down : Icons.keyboard_double_arrow_right,
                      color: const Color(0xFF4F46E5),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllLocationsPage(),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                '${locations.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Total Locations',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllStudentsPage(),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              const Icon(Icons.people, color: Colors.white, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                '$totalStudents',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Total Students',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaidUnpaidStudentsPage(),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                '$paidStudents',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Paid Students',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Locations',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  onChanged: _filterLocations,
                  decoration: InputDecoration(
                    hintText: 'Search locations...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredLocations.isEmpty
                      ? const Center(
                          child: Text(
                            'Location not found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                    itemCount: filteredLocations.length,
                    itemBuilder: (context, index) {
                      final location = filteredLocations[index];
                      final isLongPressed = _longPressedLocationId == location['id'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isLongPressed ? const Color(0xFFEEF2FF) : null,
                        child: ListTile(
                          onTap: () {
                            if (_longPressedLocationId != null) {
                              setState(() => _longPressedLocationId = null);
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocationStudentsPage(
                                  locationName: location['name'],
                                ),
                              ),
                            );
                          },
                          onLongPress: () {
                            setState(() {
                              _longPressedLocationId = isLongPressed ? null : location['id'];
                            });
                          },
                          leading: isLongPressed
                              ? Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                                )
                              : const Icon(Icons.location_on, color: Color(0xFF4F46E5)),
                          title: Text(
                            location['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Fee: ₹${location['fee']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF4F46E5), size: 20),
                            onPressed: () async {
                              setState(() => _longPressedLocationId = null);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditLocationPage(
                                    locationId: location['id'],
                                    locationName: location['name'],
                                    currentFee: (location['fee'] as num).toDouble(),
                                  ),
                                ),
                              );
                              if (result == true) _loadLocations();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (isMenuExpanded)
            Positioned(
              top: 80,
              left: 24,
              right: MediaQuery.of(context).size.width * 0.3,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF4F46E5), width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 234, 234, 236).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async {
                        setState(() => isMenuExpanded = false);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddLocationPage(),
                          ),
                        );
                        if (result != null) {
                          _addLocation(result['name'], result['fee']);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_location, color: Color(0xFF4F46E5), size: 32),
                            SizedBox(width: 16),
                            Text(
                              'Add Location',
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        setState(() => isMenuExpanded = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminRolePage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: Color(0xFF4F46E5), size: 32),
                            SizedBox(width: 16),
                            Text(
                              'Admin Role',
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        setState(() => isMenuExpanded = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UploadStudentDataPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.person_add, color: Color(0xFF4F46E5), size: 32),
                            SizedBox(width: 16),
                            Text(
                              'Student Entry',
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        setState(() => isMenuExpanded = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecycleBinPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.delete, color: Color(0xFF4F46E5), size: 32),
                            SizedBox(width: 16),
                            Text(
                              'Recycle Bin',
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        setState(() => isMenuExpanded = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.settings, color: Color(0xFF4F46E5), size: 32),
                            SizedBox(width: 16),
                            Text(
                              'Settings',
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
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

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4F46E5)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Add Location', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        iconTheme: const IconThemeData(color: Color(0xFF4F46E5)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameController, decoration: _inputDec('Location Name', Icons.location_on)),
                  const SizedBox(height: 16),
                  TextField(controller: feeController, keyboardType: TextInputType.number, decoration: _inputDec('Fee Amount (₹)', Icons.currency_rupee)),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty && feeController.text.isNotEmpty) {
                        Navigator.pop(context, {'name': nameController.text, 'fee': double.parse(feeController.text)});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Add Location', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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
  late TextEditingController feeController;

  @override
  void initState() {
    super.initState();
    feeController = TextEditingController(text: widget.currentFee.toString());
  }

  @override
  void dispose() {
    feeController.dispose();
    super.dispose();
  }

  Future<void> _updateFee() async {
    if (feeController.text.isEmpty) return;
    try {
      await ApiService.updateLocation(
        widget.locationId,
        widget.locationName,
        double.parse(feeController.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fee updated successfully!'), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Edit Location Fee', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        iconTheme: const IconThemeData(color: Color(0xFF4F46E5)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.locationName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 24),
                  TextField(
                    controller: feeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Fee Amount',
                      prefixText: '₹ ',
                      prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF4F46E5)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _updateFee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Update Fee', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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

class AdminRolePage extends StatefulWidget {
  const AdminRolePage({super.key});

  @override
  State<AdminRolePage> createState() => _AdminRolePageState();
}

class _AdminRolePageState extends State<AdminRolePage> {
  bool _isLoading = true;
  Map<String, double> _locationData = {};
  Map<String, double> _yearData = {};
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
      final Map<String, double> yearMap = {};
      double total = 0;
      int paid = 0;

      for (var s in students) {
        final amount = (s['amountPaid'] as num?)?.toDouble() ?? 0;
        if (amount <= 0) continue;
        paid++;
        total += amount;

        // Location
        final loc = s['location']?.toString() ?? 'Unknown';
        locationMap[loc] = (locationMap[loc] ?? 0) + amount;

        // Year
        final dateStr = s['paymentDate'] ?? s['lastUpdated'] ?? s['registrationDate'];
        if (dateStr != null) {
          try {
            final year = DateTime.parse(dateStr).year.toString();
            yearMap[year] = (yearMap[year] ?? 0) + amount;
          } catch (_) {}
        }
      }

      setState(() {
        _locationData = locationMap;
        _yearData = yearMap;
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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      _summaryCard('Total Students', '$_totalStudents', Icons.people, const Color(0xFF4F46E5)),
                      const SizedBox(width: 12),
                      _summaryCard('Paid', '$_paidStudents', Icons.check_circle, const Color(0xFF10B981)),
                      const SizedBox(width: 12),
                      _summaryCard('Collection', _formatAmount(_totalCollection), Icons.currency_rupee, const Color(0xFFF59E0B)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Location Bar Chart
                  _chartCard(
                    title: 'Fees Collection by Location',
                    subtitle: 'Total collected per bus route',
                    icon: Icons.location_on,
                    child: _locationData.isEmpty
                        ? const Center(child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No data available', style: TextStyle(color: Colors.grey)),
                          ))
                        : SizedBox(
                            height: 220,
                            child: _LocationBarChart(data: _locationData, formatAmount: _formatAmount),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Year Line Chart
                  _chartCard(
                    title: 'Fees Collection by Year',
                    subtitle: 'Year-wise payment trend',
                    icon: Icons.trending_up,
                    child: _yearData.isEmpty
                        ? const Center(child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No data available', style: TextStyle(color: Colors.grey)),
                          ))
                        : SizedBox(
                            height: 220,
                            child: _YearLineChart(data: _yearData, formatAmount: _formatAmount),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _chartCard({required String title, required String subtitle, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}


class _LocationBarChart extends StatelessWidget {
  final Map<String, double> data;
  final String Function(double) formatAmount;

  const _LocationBarChart({required this.data, required this.formatAmount});

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
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        formatAmount(entries[i].value),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                style: const TextStyle(fontSize: 9, color: Colors.grey),
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
  final String Function(double) formatAmount;

  const _YearLineChart({required this.data, required this.formatAmount});

  @override
  Widget build(BuildContext context) {
    final allYears = ['2021', '2022', '2023', '2024', '2025'];
    final values = allYears.map((y) => data[y] ?? 0).toList();
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
                Text(
                  values[i] > 0 ? formatAmount(values[i]) : '',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                ),
                Text(allYears[i], style: const TextStyle(fontSize: 10, color: Colors.grey)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Student Entry', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        iconTheme: const IconThemeData(color: Color(0xFF4F46E5)),
        actions: [
          if (_longPressedStudentId != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete student',
              onPressed: () async {
                final student = _students.firstWhere(
                  (s) => (s['_id'] ?? s['id'])?.toString() == _longPressedStudentId,
                );
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Student'),
                    content: Text('Move ${student['phone']} to recycle bin?'),
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
                  await ApiService.deleteStudent(_longPressedStudentId!);
                  setState(() => _longPressedStudentId = null);
                  await _loadStudents();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Student moved to recycle bin'), backgroundColor: Colors.orange),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone, color: Color(0xFF4F46E5)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dobController,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth (YYYY-MM-DD)',
                      prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF4F46E5)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _isSubmitting
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                            : ElevatedButton(
                                onPressed: _submitStudent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: const Text('Add Student', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isUploading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                            : ElevatedButton.icon(
                                onPressed: _pickAndUploadExcel,
                                icon: const Icon(Icons.file_upload),
                                label: const Text('Upload Excel', style: TextStyle(fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Total Students: ${_students.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _students.isEmpty
                ? const Center(child: Text('No students uploaded yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final studentId = (student['_id'] ?? student['id'])?.toString();
                      final isSelected = _longPressedStudentId == studentId;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isSelected ? const Color(0xFFEEF2FF) : null,
                        child: ListTile(
                          onTap: () {
                            if (_longPressedStudentId != null) {
                              setState(() => _longPressedStudentId = null);
                            }
                          },
                          onLongPress: () {
                            setState(() {
                              _longPressedStudentId = isSelected ? null : studentId;
                            });
                          },
                          leading: isSelected
                              ? Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                                )
                              : CircleAvatar(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  child: Text(
                                    student['phone']?[0] ?? 'P',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                          title: Text(student['phone'] ?? 'No Phone'),
                          subtitle: Text('DOB: ${student['dob']?.toString().split('T')[0] ?? ''}'),
                          trailing: const Icon(Icons.person, color: Color(0xFF4F46E5)),
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
      appBar: AppBar(
        title: Text(widget.locationName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterStudents,
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredStudents.isEmpty
                      ? const Center(child: Text('No students found'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
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

    final String title = isStudent
        ? ((item['name']?.toString().isNotEmpty == true)
            ? item['name'].toString()
            : item['phone']?.toString() ?? 'Student')
        : item['name']?.toString() ?? 'Location';

    final String line1 = isStudent
        ? 'Phone: ${item['phone'] ?? 'N/A'}'
        : 'Fee: ₹${item['fee'] ?? 'N/A'}';

    final String line2 = isStudent
        ? 'DOB: ${item['dob']?.toString().split('T')[0] ?? 'N/A'}'
        : 'Deleted: ${item['deletedAt']?.toString().split('T')[0] ?? 'N/A'}';

    final String deletedAt = isStudent
        ? 'Deleted: ${item['deletedAt']?.toString().split('T')[0] ?? ''}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isStudent
                    ? const Color(0xFF4F46E5).withOpacity(0.1)
                    : const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isStudent ? Icons.person_rounded : Icons.location_on_rounded,
                color: isStudent ? const Color(0xFF4F46E5) : const Color(0xFFF59E0B),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(line1,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                  Text(line2,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                  if (isStudent && deletedAt.isNotEmpty)
                    Text(deletedAt,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.restore_rounded,
                      color: Colors.green, size: 22),
                  tooltip: 'Restore',
                  onPressed: id.isEmpty ? null : () => _restore(id),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded,
                      color: Colors.red, size: 22),
                  tooltip: 'Delete permanently',
                  onPressed: id.isEmpty ? null : () => _permanentDelete(id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Recycle Bin',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        iconTheme: const IconThemeData(color: Color(0xFF4F46E5)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF4F46E5),
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.person_rounded, size: 18),
              text: 'Students (${_students.length})',
            ),
            Tab(
              icon: const Icon(Icons.location_on_rounded, size: 18),
              text: 'Locations (${_locations.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : TabBarView(
              controller: _tabController,
              children: [
                // Page 1 — Deleted Students
                _students.isEmpty
                    ? _emptyState(
                        'No deleted students', Icons.person_off_rounded)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (_, i) => _buildCard(_students[i]),
                      ),

                // Page 2 — Deleted Locations
                _locations.isEmpty
                    ? _emptyState('No deleted locations',
                        Icons.location_off_rounded)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _locations.length,
                        itemBuilder: (_, i) => _buildCard(_locations[i]),
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
      appBar: AppBar(
        title: const Text('Payment Notifications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF10B981),
                          child: Icon(Icons.payment, color: Colors.white),
                        ),
                        title: Text(notification['studentName'] ?? 'Student'),
                        subtitle: Text(
                          'Phone: ${notification['phone']}\n'
                          'Amount: ₹${notification['amount']}\n'
                          'Location: ${notification['location']}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNotification(notification['_id']),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        iconTheme: const IconThemeData(color: Color(0xFF4F46E5)),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings, size: 48, color: Color(0xFF4F46E5)),
              SizedBox(height: 16),
              Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              SizedBox(height: 8),
              Text('Coming soon...', style: TextStyle(color: Color(0xFF94A3B8))),
            ],
          ),
        ),
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
      appBar: AppBar(
        title: _selectedIds.isEmpty
            ? const Text('All Students')
            : Text('${_selectedIds.length} Selected'),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete selected',
              onPressed: _deleteSelected,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('No students found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final id = (student['_id'] ?? student['id'])?.toString() ?? '';
                    final isSelected = _selectedIds.contains(id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isSelected ? const Color(0xFFEEF2FF) : null,
                      child: ListTile(
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
                        leading: isSelected
                            ? Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F46E5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 20),
                              )
                            : CircleAvatar(
                                backgroundColor: const Color(0xFF10B981),
                                child: Text(
                                  (student['phone']?.toString() ?? 'S').substring(0, 1),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                        title: Text(
                          student['phone'] ?? 'No Phone',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Password: ${student['dob']?.toString().split('T')[0] ?? 'N/A'}',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    );
                  },
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
      // Use the MongoDB _id to update the exact student - no duplicates
      final studentId = (widget.student['_id'] ?? widget.student['id'])?.toString() ?? '';
      await ApiService.updateStudentById(studentId, {
        'name': nameController.text,
        'rollNo': rollNoController.text,
        'studentClass': classController.text,
        'parentName': parentNameController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        'address': addressController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student updated successfully!'), backgroundColor: Colors.green),
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

  Widget _editField(TextEditingController ctrl, String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4F46E5)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Edit Student', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        iconTheme: const IconThemeData(color: Color(0xFF4F46E5)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  _editField(nameController, 'Name', Icons.person),
                  _editField(rollNoController, 'Roll Number', Icons.badge),
                  _editField(classController, 'Class', Icons.school),
                  _editField(parentNameController, 'Parent Name', Icons.family_restroom),
                  _editField(phoneController, 'Phone', Icons.phone),
                  _editField(emailController, 'Email', Icons.email),
                  _editField(addressController, 'Address', Icons.home),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _updateStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Update Student', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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

  Widget _buildStudentCard(Map<String, dynamic> student, bool isPaid) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          child: Icon(
            isPaid ? Icons.check : Icons.pending,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          student['name']?.isNotEmpty == true ? student['name'] : student['phone'] ?? 'N/A',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${student['phone'] ?? 'N/A'}'),
            Text('Roll No: ${student['rollNo'] ?? 'N/A'}'),
            Text('Class: ${student['studentClass'] ?? 'N/A'}'),
            Text('Location: ${student['location'] ?? 'N/A'}'),
            Text(
              isPaid
                  ? 'Paid: ₹${student['amountPaid'] ?? 0}'
                  : 'Due: ₹${student['totalDue'] ?? 0}',
              style: TextStyle(
                color: isPaid ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students Payment Status'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.check_circle),
              text: 'Paid (${_paidStudents.length})',
            ),
            Tab(
              icon: const Icon(Icons.pending),
              text: 'Unpaid (${_unpaidStudents.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Page 1 - Paid Students
                _paidStudents.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No paid students yet', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _paidStudents.length,
                        itemBuilder: (context, index) =>
                            _buildStudentCard(_paidStudents[index], true),
                      ),
                // Page 2 - Unpaid Students
                _unpaidStudents.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.celebration, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('All students have paid!', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _unpaidStudents.length,
                        itemBuilder: (context, index) =>
                            _buildStudentCard(_unpaidStudents[index], false),
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
      appBar: AppBar(
        title: const Text('All Locations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? const Center(child: Text('No locations found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final location = _locations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.location_on, color: Color(0xFF4F46E5)),
                        title: Text(location['name']),
                        subtitle: Text('Fee: ₹${location['fee']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF4F46E5)),
                          onPressed: () => _editLocation(location),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
