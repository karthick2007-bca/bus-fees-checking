import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class GenerateReportPage extends StatefulWidget {
  const GenerateReportPage({super.key});

  @override
  State<GenerateReportPage> createState() => _GenerateReportPageState();
}

class _GenerateReportPageState extends State<GenerateReportPage> {
  final _nameCtrl     = TextEditingController();
  final _classCtrl    = TextEditingController();
  final _rollCtrl     = TextEditingController();
  final _parentCtrl   = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _amountCtrl   = TextEditingController();
  final _phoneCtrl    = TextEditingController();

  bool _isSubmitting   = false;
  bool _loadingReports = true;
  List<dynamic> _reports   = [];
  List<dynamic> _locations = [];
  String? _selectedLocation;

  static const _bg     = Color(0xFF060818);
  static const _accent = Color(0xFF00CCFF);
  static const _green  = Color(0xFF10B981);
  static const _tp     = Color(0xFFEEEEFF);
  static const _ts     = Color(0xFF8888AA);

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadReports();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _classCtrl.dispose(); _rollCtrl.dispose();
    _parentCtrl.dispose(); _locationCtrl.dispose();
    _amountCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final locs = await ApiService.getLocations();
      setState(() => _locations = locs);
    } catch (_) {}
  }

  Future<void> _loadReports() async {
    try {
      final students = await ApiService.getStudents();
      final paid = students.where((s) => s['status'] == 'succeed').toList();
      paid.sort((a, b) {
        final aDate = DateTime.tryParse(a['lastUpdated']?.toString() ?? '') ?? DateTime(0);
        final bDate = DateTime.tryParse(b['lastUpdated']?.toString() ?? '') ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
      setState(() { _reports = paid; _loadingReports = false; });
    } catch (_) {
      setState(() => _loadingReports = false);
    }
  }

  Future<void> _submit() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final amt = double.tryParse(_amountCtrl.text.trim()) ?? 0;
      final now = DateTime.now().toIso8601String();
      await ApiService.addStudent({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameCtrl.text.trim(),
        'studentClass': _classCtrl.text.trim(),
        'rollNo': _rollCtrl.text.trim(),
        'parentName': _parentCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'amountPaid': amt, 'totalDue': 0,
        'phone': _phoneCtrl.text.trim(),
        'email': '', 'address': '', 'dob': '',
        'status': 'succeed', 'lastUpdated': now,
        'payments': [],
        'locationHistory': [
          {'location': _locationCtrl.text.trim(), 'date': now, 'amount': amt}
        ],
      });
      await ApiService.saveReport({
        'phone':        _phoneCtrl.text.trim(),
        'name':         _nameCtrl.text.trim(),
        'rollNo':       _rollCtrl.text.trim(),
        'studentClass': _classCtrl.text.trim(),
        'parentName':   _parentCtrl.text.trim(),
        'address': '', 'location': _locationCtrl.text.trim(), 'dob': '',
        'totalDue': 0, 'amountPaid': amt, 'status': 'succeed',
        'paymentId':   'ADMIN-${DateTime.now().millisecondsSinceEpoch}',
        'paymentDate': now, 'generatedAt': now,
      });
      _nameCtrl.clear(); _classCtrl.clear(); _rollCtrl.clear();
      _parentCtrl.clear(); _locationCtrl.clear();
      _amountCtrl.clear(); _phoneCtrl.clear();
      setState(() => _selectedLocation = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully!'), backgroundColor: Color(0xFF10B981)));
        await _loadReports();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _input(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _ts, fontSize: 13),
    prefixIcon: Icon(icon, color: _accent.withOpacity(0.7), size: 18),
    filled: true,
    fillColor: Colors.white.withOpacity(0.05),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: _accent, width: 1.5)),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, TextInputType type, {bool digitsOnly = false}) =>
    TextField(
      controller: ctrl, keyboardType: type,
      inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: const TextStyle(color: _tp, fontSize: 14),
      decoration: _input(label, icon),
    );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Student Report Entry',
                        style: TextStyle(color: _tp, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
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
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [_bg, Color(0xFF0C0D2E), Color(0xFF080F22), Color(0xFF040810)],
            stops: [0.0, 0.3, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Form ──
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(children: [
                        _field(_nameCtrl,   'Name',            Icons.person_rounded,          TextInputType.name),
                        const SizedBox(height: 12),
                        _field(_classCtrl,  'Class / Section', Icons.school_rounded,           TextInputType.text),
                        const SizedBox(height: 12),
                        _field(_rollCtrl,   'Roll No',         Icons.tag_rounded,              TextInputType.text),
                        const SizedBox(height: 12),
                        _field(_parentCtrl, 'Parent Name',     Icons.family_restroom_rounded,  TextInputType.name),
                        const SizedBox(height: 12),

                        // ── Location dropdown ──
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Row(children: [
                            Icon(Icons.location_on_rounded, color: _accent.withOpacity(0.7), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1A1A2E),
                                  hint: const Text('Select Location', style: TextStyle(color: _ts, fontSize: 13)),
                                  value: _selectedLocation,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
                                  items: _locations.map<DropdownMenuItem<String>>((loc) {
                                    final name = loc['name']?.toString() ?? '';
                                    final fee  = loc['fee']?.toString() ?? '0';
                                    return DropdownMenuItem(
                                      value: name,
                                      child: Text('$name  —  ₹$fee',
                                        style: const TextStyle(color: _tp, fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    final loc = _locations.firstWhere(
                                      (l) => l['name']?.toString() == val, orElse: () => null);
                                    setState(() {
                                      _selectedLocation = val;
                                      _locationCtrl.text = val;
                                      if (loc != null) _amountCtrl.text = loc['fee']?.toString() ?? '';
                                    });
                                  },
                                ),
                              ),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 12),
                        _field(_amountCtrl, 'Amount Paid',  Icons.currency_rupee_rounded, TextInputType.number, digitsOnly: true),
                        const SizedBox(height: 12),
                        _field(_phoneCtrl,  'Phone Number', Icons.phone_rounded,           TextInputType.phone),
                        const SizedBox(height: 20),

                        // ── Submit ──
                        GestureDetector(
                          onTap: _isSubmitting ? null : _submit,
                          child: Container(
                            width: double.infinity, height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                                begin: Alignment.centerLeft, end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: _green.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
                            ),
                            child: _isSubmitting
                                ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                  ]),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Reports header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  const Icon(Icons.receipt_long_rounded, color: _accent, size: 16),
                  const SizedBox(width: 8),
                  Text('Submitted Reports (${_reports.length})',
                    style: const TextStyle(color: _tp, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 8),

              // ── Reports list ──
              Expanded(
                child: _loadingReports
                    ? const Center(child: CircularProgressIndicator(color: _accent))
                    : _reports.isEmpty
                        ? Center(child: Text('No reports yet',
                            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _reports.length,
                            itemBuilder: (context, i) {
                              final s = _reports[i];
                              final name  = s['name']?.toString() ?? '';
                              final cls   = s['studentClass']?.toString() ?? '';
                              final phone = s['phone']?.toString() ?? '';
                              final amt   = s['amountPaid'] ?? 0;
                              final colors = [
                                const Color(0xFF6C00FF), const Color(0xFF0EA5E9), _green,
                                const Color(0xFFF59E0B), const Color(0xFFEC4899), const Color(0xFF8B5CF6),
                              ];
                              final c = colors[i % colors.length];
                              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: c.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: c.withOpacity(0.25)),
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      color: c.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: c.withOpacity(0.35)),
                                    ),
                                    child: Center(child: Text(initial,
                                      style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.w800))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name.isNotEmpty ? name : phone,
                                        style: const TextStyle(color: _tp, fontWeight: FontWeight.w700, fontSize: 13)),
                                      const SizedBox(height: 3),
                                      Text(cls.isNotEmpty ? cls : phone,
                                        style: const TextStyle(color: _ts, fontSize: 11)),
                                    ],
                                  )),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _green.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _green.withOpacity(0.3)),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.currency_rupee_rounded, color: _green, size: 11),
                                      Text('$amt', style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w800)),
                                    ]),
                                  ),
                                ]),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
