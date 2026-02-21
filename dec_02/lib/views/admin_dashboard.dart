
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:io';
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
  Set<String> selectedLocationIds = {};

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
          'id': loc['id'],
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
      } else {
        filteredLocations = locations.where((loc) => 
          loc['name'].toString().toLowerCase().contains(query.toLowerCase())
        ).toList();
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
          if (selectedLocationIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Locations'),
                    content: Text('Delete ${selectedLocationIds.length} location(s)?'),
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
                  for (var id in selectedLocationIds) {
                    final loc = locations.firstWhere((l) => l['id'] == id);
                    await _deleteLocation(id, loc['name']);
                  }
                  setState(() => selectedLocationIds.clear());
                }
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                    const SizedBox(width: 12),
                    Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                    const SizedBox(width: 12),
                    Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                  ],
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
                  child: ListView.builder(
                    itemCount: filteredLocations.length,
                    itemBuilder: (context, index) {
                      final location = filteredLocations[index];
                      final isSelected = selectedLocationIds.contains(location['id']);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isSelected ? const Color(0xFFEEF2FF) : null,
                        child: ListTile(
                          onTap: selectedLocationIds.isEmpty
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LocationStudentsPage(
                                        locationName: location['name'],
                                      ),
                                    ),
                                  );
                                }
                              : () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedLocationIds.remove(location['id']);
                                    } else {
                                      selectedLocationIds.add(location['id']);
                                    }
                                  });
                                },
                          onLongPress: () {
                            setState(() {
                              if (isSelected) {
                                selectedLocationIds.remove(location['id']);
                              } else {
                                selectedLocationIds.add(location['id']);
                              }
                            });
                          },
                          leading: isSelected
                              ? const Icon(Icons.check_circle, color: Color(0xFF4F46E5))
                              : const Icon(Icons.location_on, color: Color(0xFF4F46E5)),
                          title: Text(
                            location['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Fee: ₹${location['fee']}'),
                          trailing: selectedLocationIds.isEmpty
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Color(0xFF4F46E5)),
                                      onPressed: () async {
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
                                      },
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
                                  ],
                                )
                              : null,
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
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController feeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Location'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Location Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fee Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && feeController.text.isNotEmpty) {
                  Navigator.pop(context, {
                    'name': nameController.text,
                    'fee': double.parse(feeController.text),
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Add Location'),
            ),
          ],
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
      await ApiService.addLocation({
        'id': widget.locationId,
        'name': widget.locationName,
        'fee': double.parse(feeController.text),
      });
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
      appBar: AppBar(
        title: const Text('Edit Location Fee'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.locationName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: feeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fee Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _updateFee,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Update Fee'),
            ),
          ],
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
  Map<String, int> locationStudentCount = {};

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final students = await DataStorage.loadStudents();
    final Map<String, int> counts = {};
    for (var student in students) {
      counts[student.location] = (counts[student.location] ?? 0) + 1;
    }
    setState(() {
      locationStudentCount = counts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalStudents = locationStudentCount.values.fold(0, (a, b) => a + b);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Role'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Students: $totalStudents',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Students by Location:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: locationStudentCount.entries.map((entry) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: Color(0xFF4F46E5)),
                      title: Text(entry.key),
                      trailing: Text(
                        '${entry.value} students',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      appBar: AppBar(
        title: const Text('Student Entry'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dobController,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _isSubmitting
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _submitStudent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                minimumSize: const Size(0, 48),
                              ),
                              child: const Text('Add Student'),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _pickAndUploadExcel,
                              icon: const Icon(Icons.file_upload),
                              label: const Text('Upload Excel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                minimumSize: const Size(0, 48),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Total Students: ${_students.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF4F46E5),
                            child: Text(
                              student['phone']?[0] ?? 'P',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(student['phone'] ?? 'No Phone'),
                          subtitle: Text('DOB: ${student['dob']}'),
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

class _RecycleBinPageState extends State<RecycleBinPage> {
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await ApiService.getRecycleBin();
      setState(() {
        _items = items;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Recycle bin is empty'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final type = item['type'];
                    final data = item['data'];
                    final id = item['_id'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          type == 'student' ? Icons.person : Icons.location_on,
                          color: const Color(0xFF4F46E5),
                        ),
                        title: Text(
                          type == 'student'
                              ? (data['name']?.isNotEmpty == true ? data['name'] : data['phone'] ?? 'Student')
                              : data['name'] ?? 'Location',
                        ),
                        subtitle: Text(
                          type == 'student'
                              ? 'Phone: ${data['phone']}'
                              : 'Fee: ₹${data['fee']}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore, color: Colors.green),
                              onPressed: () => _restore(id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () => _permanentDelete(id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
