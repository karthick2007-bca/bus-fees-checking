import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../models/location.dart' as location_model;
import 'student_report.dart';

class EditReportPage extends StatefulWidget {
  final String phone;
  final String dob;
  final String currentLocation;

  const EditReportPage({
    super.key,
    required this.phone,
    required this.dob,
    required this.currentLocation,
  });

  @override
  State<EditReportPage> createState() => _EditReportPageState();
}

class _EditReportPageState extends State<EditReportPage> {
  final PaymentService _paymentService = PaymentService();
  List<location_model.Route> locations = [];
  location_model.Route? oldLocation;
  location_model.Route? newLocation;
  double totalAmount = 0;
  bool _isProcessing = false;
  bool _isLoading = true;

  // Design constants — same as registration page
  static const _bg       = Color(0xFF0F0F1A);
  static const _card     = Color(0xFF1A1A2E);
  static const _accent   = Color(0xFF6C63FF);
  static const _accent2  = Color(0xFF00D4AA);
  static const _warn     = Color(0xFFF59E0B);
  static const _textPrimary   = Color(0xFFEEEEFF);
  static const _textSecondary = Color(0xFF8888AA);
  static const _fieldBg  = Color(0xFF22223A);
  static const _border   = Color(0xFF2E2E4A);

  @override
  void initState() {
    super.initState();
    loadLocations();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onWallet: () {},
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> loadLocations() async {
    try {
      final data = await ApiService.getLocations();
      setState(() {
        locations = data.map((loc) => location_model.Route(
          id: loc['id'] ?? '',
          name: loc['name'] ?? '',
          fee: (loc['fee'] as num).toDouble(),
        )).toList();
        oldLocation = locations.firstWhere(
          (loc) => loc.name == widget.currentLocation,
          orElse: () => locations.isNotEmpty ? locations.first : location_model.Route(id: '', name: '', fee: 0),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void calculateAmount() {
    if (oldLocation != null && newLocation != null) {
      setState(() => totalAmount = (newLocation!.fee - oldLocation!.fee).abs());
    }
  }

  void _handlePaymentSuccess(dynamic response) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      // Fetch full student data — try phone+dob first, fallback to phone only
      final students = await ApiService.getStudents();

      Map<String, dynamic> existing = students.firstWhere(
        (s) =>
            s['phone']?.toString() == widget.phone &&
            s['dob']?.toString().split('T')[0] == widget.dob,
        orElse: () => <String, dynamic>{},
      );

      // Fallback: match by phone alone if dob match failed or returned empty
      if (existing.isEmpty || (existing['name']?.toString() ?? '').isEmpty) {
        existing = students.firstWhere(
          (s) => s['phone']?.toString() == widget.phone,
          orElse: () => <String, dynamic>{},
        );
      }

      // Merge — only overwrite location/payment fields, keep all personal details
      final updatedData = Map<String, dynamic>.from(existing);
      updatedData['location']    = newLocation!.name;
      updatedData['amountPaid']  = newLocation!.fee;
      updatedData['totalDue']    = 0;
      updatedData['status']      = 'succeed';
      updatedData['lastUpdated'] = DateTime.now().toIso8601String();

      await ApiService.updateStudent(widget.phone, updatedData);

      final paymentId = response['paymentId']?.toString() ?? '';
      final now = DateTime.now().toIso8601String();

      await ApiService.saveTransaction({
        'paymentId':   paymentId,
        'orderId':     response['orderId']?.toString() ?? '',
        'studentId':   widget.phone,
        'studentName': updatedData['name'] ?? '',
        'amount':      totalAmount,
        'status':      'success',
        'type':        'location_change',
        'timestamp':   now,
      });

      // Save report — explicitly pull every personal field from updatedData
      await ApiService.saveReport({
        'phone':        updatedData['phone']        ?? widget.phone,
        'name':         updatedData['name']         ?? '',
        'rollNo':       updatedData['rollNo']       ?? '',
        'studentClass': updatedData['studentClass'] ?? '',
        'parentName':   updatedData['parentName']   ?? '',
        'address':      updatedData['address']      ?? '',
        'location':     newLocation!.name,
        'dob':          updatedData['dob']?.toString().split('T')[0] ?? widget.dob,
        'totalDue':     0,
        'amountPaid':   newLocation!.fee,
        'status':       'succeed',
        'paymentId':    paymentId,
        'paymentDate':  now,
        'generatedAt':  now,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully! ✅'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentReport(
            phone: widget.phone,
            dob: widget.dob,
            onLogout: () => Navigator.pop(context),
            initialData: updatedData,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentFailure(dynamic response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response['message'] ?? 'Unknown error'}'),
          backgroundColor: Colors.red));
  }

  void handlePay() {
    if (newLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select new location'), backgroundColor: Colors.orange));
      return;
    }
    if (oldLocation?.id == newLocation?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New location must be different'), backgroundColor: Colors.orange));
      return;
    }
    // Same fee — no payment needed, update directly
    if (totalAmount == 0) {
      _updateLocationWithoutPayment();
      return;
    }
    _paymentService.openCheckout(
      amount: totalAmount, name: 'Location Change', phone: widget.phone, email: '');
  }

  Future<void> _updateLocationWithoutPayment() async {
    setState(() => _isProcessing = true);
    try {
      final students = await ApiService.getStudents();
      Map<String, dynamic> existing = students.firstWhere(
        (s) =>
            s['phone']?.toString() == widget.phone &&
            s['dob']?.toString().split('T')[0] == widget.dob,
        orElse: () => <String, dynamic>{},
      );
      if (existing.isEmpty || (existing['name']?.toString() ?? '').isEmpty) {
        existing = students.firstWhere(
          (s) => s['phone']?.toString() == widget.phone,
          orElse: () => <String, dynamic>{},
        );
      }

      final updatedData = Map<String, dynamic>.from(existing);
      updatedData['location']    = newLocation!.name;
      updatedData['lastUpdated'] = DateTime.now().toIso8601String();

      await ApiService.updateStudent(widget.phone, updatedData);

      final now = DateTime.now().toIso8601String();
      await ApiService.saveReport({
        'phone':        updatedData['phone']        ?? widget.phone,
        'name':         updatedData['name']         ?? '',
        'rollNo':       updatedData['rollNo']       ?? '',
        'studentClass': updatedData['studentClass'] ?? '',
        'parentName':   updatedData['parentName']   ?? '',
        'address':      updatedData['address']      ?? '',
        'location':     newLocation!.name,
        'dob':          updatedData['dob']?.toString().split('T')[0] ?? widget.dob,
        'totalDue':     0,
        'amountPaid':   updatedData['amountPaid'] ?? 0,
        'status':       updatedData['status'] ?? 'succeed',
        'paymentId':    updatedData['lastPaymentId'] ?? '',
        'paymentDate':  updatedData['lastPaymentDate'] ?? now,
        'generatedAt':  now,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated successfully! ✅'),
            backgroundColor: Colors.green, duration: Duration(seconds: 2)));
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentReport(
            phone: widget.phone,
            dob: widget.dob,
            onLogout: () => Navigator.pop(context),
            initialData: updatedData,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  InputDecoration _dropdownDec(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _textSecondary, fontSize: 13),
    prefixIcon: const Icon(Icons.location_on_rounded, color: _accent, size: 20),
    filled: true,
    fillColor: _fieldBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.8)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_accent, Color(0xFF9C63FF)]),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.edit_location_alt_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          const Text('Change Location',
              style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Student info badge ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _accent.withOpacity(0.25)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.phone_rounded, color: _accent, size: 16),
                          const SizedBox(width: 8),
                          Text('Student: ${widget.phone}',
                              style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      const SizedBox(height: 28),

                      // ── Current location ──
                      _sectionLabel('Current Location', Icons.location_on_rounded),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<location_model.Route>(
                        value: oldLocation,
                        dropdownColor: const Color(0xFF1E1E32),
                        style: const TextStyle(color: _textPrimary, fontSize: 14),
                        iconEnabledColor: _accent,
                        decoration: _dropdownDec('Current Stop'),
                        items: locations.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text('${r.name}  ·  ₹${r.fee.toStringAsFixed(0)}',
                              style: const TextStyle(color: _textPrimary, fontSize: 13)),
                        )).toList(),
                        onChanged: (r) => setState(() { oldLocation = r; calculateAmount(); }),
                      ),
                      const SizedBox(height: 24),

                      // ── New location ──
                      _sectionLabel('New Location', Icons.edit_location_alt_rounded),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<location_model.Route>(
                        value: newLocation,
                        dropdownColor: const Color(0xFF1E1E32),
                        style: const TextStyle(color: _textPrimary, fontSize: 14),
                        iconEnabledColor: _accent,
                        decoration: _dropdownDec('Select New Stop'),
                        hint: const Text('Choose new stop',
                            style: TextStyle(color: _textSecondary, fontSize: 13)),
                        items: locations.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text('${r.name}  ·  ₹${r.fee.toStringAsFixed(0)}',
                              style: const TextStyle(color: _textPrimary, fontSize: 13)),
                        )).toList(),
                        onChanged: (r) => setState(() { newLocation = r; calculateAmount(); }),
                      ),

                      // ── Fee summary card ──
                      if (oldLocation != null && newLocation != null) ...[
                        const SizedBox(height: 28),
                        _sectionLabel('Fee Summary', Icons.receipt_long_rounded),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border),
                          ),
                          child: Column(children: [
                            _feeRow('Current Fee', '₹${oldLocation!.fee.toStringAsFixed(0)}', _textSecondary),
                            const SizedBox(height: 12),
                            _feeRow('New Fee', '₹${newLocation!.fee.toStringAsFixed(0)}', _accent2),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Container(height: 1, color: _border),
                            ),
                            _feeRow('Amount to Pay', '₹${totalAmount.toStringAsFixed(0)}', _accent,
                                large: true),
                          ]),
                        ),

                        // ── Same fee notice ──
                        if (totalAmount == 0) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _warn.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _warn.withOpacity(0.3)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.info_outline_rounded, color: _warn, size: 18),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text('Both locations have the same fee — no payment needed.',
                                    style: TextStyle(color: _warn, fontSize: 12, fontWeight: FontWeight.w500)),
                              ),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // ── Pay button ──
                        SizedBox(
                          width: double.infinity, height: 54,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : handlePay,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              disabledBackgroundColor: _border,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isProcessing
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      totalAmount > 0 ? 'Pay  ₹${totalAmount.toStringAsFixed(0)}' : 'Update Location',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                  ]),
                          ),
                        ),

                        if (totalAmount > 0) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: Text('Payment will update your location & generate report',
                                style: TextStyle(color: _textSecondary.withOpacity(0.7), fontSize: 11)),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                // ── Processing overlay ──
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _border),
                        ),
                        child: const Column(mainAxisSize: MainAxisSize.min, children: [
                          CircularProgressIndicator(color: _accent),
                          SizedBox(height: 16),
                          Text('Updating location...', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: _accent, size: 16),
      const SizedBox(width: 7),
      Text(title.toUpperCase(),
          style: const TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1, color: _border)),
    ]);
  }

  Widget _feeRow(String label, String value, Color valueColor, {bool large = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(
          color: _textSecondary, fontSize: large ? 14 : 13, fontWeight: FontWeight.w500)),
      Text(value, style: TextStyle(
          color: valueColor, fontSize: large ? 20 : 14, fontWeight: FontWeight.w800)),
    ]);
  }
}
