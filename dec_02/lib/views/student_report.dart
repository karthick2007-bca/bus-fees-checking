import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import 'edit_report_page.dart';

class StudentReport extends StatefulWidget {
  final String phone;
  final String dob;
  final VoidCallback? onLogout;
  final Map<String, dynamic>? initialData;

  const StudentReport({
    super.key,
    required this.phone,
    required this.dob,
    this.onLogout,
    this.initialData,
  });

  @override
  State<StudentReport> createState() => _StudentReportState();
}

class _StudentReportState extends State<StudentReport> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;
  bool _isFrameOpen = false;
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _loadStudentData();
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

  Future<void> _loadStudentData() async {
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      final data = Map<String, dynamic>.from(widget.initialData!);
      data.forEach((key, value) {
        if (value == null) data[key] = '';
      });
      setState(() {
        studentData = data;
        isLoading = false;
      });
      return;
    }
    try {
      final students = await ApiService.getStudents();
      final student = students.firstWhere(
        (s) =>
            s['phone']?.toString() == widget.phone &&
            s['dob']?.toString().split('T')[0] == widget.dob,
        orElse: () => {},
      );
      setState(() {
        studentData = student.isNotEmpty ? Map<String, dynamic>.from(student) : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _handlePaymentSuccess(dynamic response) async {
    final paymentId = response['paymentId'];
    final amountPaid = (studentData!['totalDue'] ?? 0).toDouble();
    final now = DateTime.now().toIso8601String();

    await ApiService.updateStudent(studentData!['phone'], {
      'amountPaid': amountPaid,
      'totalDue': 0,
      'status': 'succeed',
      'lastPaymentId': paymentId,
      'lastPaymentDate': now,
    });

    await ApiService.saveTransaction({
      'studentId': studentData!['_id']?.toString() ?? studentData!['id'] ?? '',
      'studentName': studentData!['name'],
      'phone': studentData!['phone'],
      'rollNo': studentData!['rollNo'],
      'amount': amountPaid,
      'paymentId': paymentId,
      'orderId': response['orderId'] ?? '',
      'timestamp': now,
    });

    await ApiService.saveReport({
      'phone': studentData!['phone'],
      'name': studentData!['name'],
      'rollNo': studentData!['rollNo'],
      'studentClass': studentData!['studentClass'],
      'parentName': studentData!['parentName'],
      'address': studentData!['address'],
      'location': studentData!['location'],
      'dob': studentData!['dob']?.toString().split('T')[0],
      'totalDue': 0,
      'amountPaid': amountPaid,
      'status': 'succeed',
      'paymentId': paymentId,
      'paymentDate': now,
      'generatedAt': now,
    });

    setState(() {
      studentData!['amountPaid'] = amountPaid;
      studentData!['totalDue'] = 0;
      studentData!['status'] = 'succeed';
      studentData!['paymentId'] = paymentId;
      studentData!['paymentDate'] = now;
    });

    // Save payment notification for admin
    try {
      await ApiService.saveNotification({
        'type': 'payment',
        'studentName': studentData!['name'] ?? 'Student',
        'phone': studentData!['phone'] ?? '',
        'amount': amountPaid,
        'location': studentData!['location'] ?? '',
        'paymentId': paymentId,
        'message': 'Payment of ₹$amountPaid received',
      });
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Successful! ID: $paymentId'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handlePaymentFailure(dynamic response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${response['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _makePayment() {
    if (studentData != null) {
      _paymentService.openCheckout(
        amount: (studentData!['totalDue'] ?? 0).toDouble(),
        name: studentData!['name'] ?? '',
        phone: studentData!['phone'] ?? '',
        email: '',
      );
    }
  }

  void _showFeedbackDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.feedback_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 10),
            Text('Feedback', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Write your feedback here...',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final msg = ctrl.text.trim();
              Navigator.pop(ctx);
              if (msg.isNotEmpty) {
                try {
                  await ApiService.saveFeedback({
                    'studentName': studentData?['name'] ?? 'Student',
                    'phone': widget.phone,
                    'message': msg,
                  });
                } catch (_) {}
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feedback submitted! Thank you.'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _frameItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        title: const Text('Payment Receipt',
            style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () => setState(() => _isFrameOpen = !_isFrameOpen),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '>>>',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (widget.onLogout != null) widget.onLogout!();
                      },
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Main content ──
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : studentData == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No report found',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 8),
                          const Text('You have not made any payment yet.',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              if (widget.onLogout != null) widget.onLogout!();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Center(
                                    child: Column(
                                      children: [
                                        Image.network(
                                          'https://www.lingaschool.org/img/linga.png',
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4F46E5),
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                          child: const Icon(Icons.receipt_long,
                                              color: Colors.white, size: 40),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'PAYMENT RECEIPT',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                            color: Color(0xFF4F46E5),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Bus Fee Payment Confirmation',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                            height: 2,
                                            width: 200,
                                            color: const Color(0xFF4F46E5)),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // Payment Status Badge
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: (studentData!['status'] ==
                                                'succeed')
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: (studentData!['status'] ==
                                                  'succeed')
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            studentData!['status'] == 'succeed'
                                                ? Icons.check_circle
                                                : Icons.pending,
                                            color:
                                                studentData!['status'] ==
                                                        'succeed'
                                                    ? Colors.green
                                                    : Colors.orange,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            studentData!['status'] == 'succeed'
                                                ? 'PAYMENT SUCCESSFUL'
                                                : 'PAYMENT PENDING',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: studentData!['status'] ==
                                                      'succeed'
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  _sectionTitle(
                                      'PERSONAL INFORMATION', Icons.person),
                                  const SizedBox(height: 12),
                                  _infoRow('Student Name',
                                      studentData!['name'] ?? 'N/A'),
                                  _infoRow('Roll Number',
                                      studentData!['rollNo'] ?? 'N/A'),
                                  _infoRow('Class / Section',
                                      studentData!['studentClass'] ?? 'N/A'),
                                  _infoRow(
                                      'Date of Birth',
                                      studentData!['dob']
                                              ?.toString()
                                              .split('T')[0] ??
                                          'N/A'),
                                  _infoRow('Phone Number',
                                      studentData!['phone'] ?? 'N/A'),

                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 24),

                                  _sectionTitle('PARENT INFORMATION',
                                      Icons.family_restroom),
                                  const SizedBox(height: 12),
                                  _infoRow('Parent Name',
                                      studentData!['parentName'] ?? 'N/A'),
                                  _infoRow('Address',
                                      studentData!['address'] ?? 'N/A'),

                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 24),

                                  _sectionTitle(
                                      'FEE INFORMATION', Icons.currency_rupee),
                                  const SizedBox(height: 12),
                                  _infoRow('Bus Route / Location',
                                      studentData!['location'] ?? 'N/A'),
                                  _infoRow('Amount Paid',
                                      '₹${studentData!['amountPaid'] ?? 0}'),
                                  _infoRow('Balance Due',
                                      '₹${studentData!['totalDue'] ?? 0}'),
                                  if (studentData!['paymentId'] != null)
                                    _infoRow('Payment ID',
                                        studentData!['paymentId'].toString()),
                                  if (studentData!['paymentDate'] != null)
                                    _infoRow(
                                        'Payment Date',
                                        DateTime.tryParse(studentData![
                                                        'paymentDate']
                                                    .toString())
                                                ?.toString()
                                                .split('.')[0] ??
                                            studentData!['paymentDate']
                                                .toString()),

                                  if ((studentData!['totalDue'] ?? 0) > 0) ...[
                                    const SizedBox(height: 24),
                                    Center(
                                      child: ElevatedButton.icon(
                                        onPressed: _makePayment,
                                        icon: const Icon(Icons.payment),
                                        label: Text(
                                            'Pay Now ₹${studentData!['totalDue']}'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF4F46E5),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 16),
                                          textStyle: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 40),
                                  const Divider(thickness: 2),
                                  const SizedBox(height: 16),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Generated: ${DateTime.now().toString().split('.')[0]}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                      ),
                                      Text(
                                        'Authorized Signature: __________',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

          // ── Dim overlay ──
          if (_isFrameOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isFrameOpen = false),
                child: Container(color: Colors.black.withOpacity(0.35)),
              ),
            ),

          // ── Slide-in frame ──
          if (_isFrameOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 260,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 24),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Frame header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Menu',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900)),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isFrameOpen = false),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Edit Report
                      _frameItem(
                        icon: Icons.edit_note_rounded,
                        label: 'Edit Report',
                        color: const Color(0xFF4F46E5),
                        onTap: () {
                          setState(() => _isFrameOpen = false);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditReportPage(
                                phone: widget.phone,
                                dob: widget.dob,
                                currentLocation:
                                    studentData?['location'] ?? '',
                              ),
                            ),
                          );
                        },
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(height: 1),
                      ),

                      // Feedback
                      _frameItem(
                        icon: Icons.feedback_rounded,
                        label: 'Feedback',
                        color: const Color(0xFF10B981),
                        onTap: () {
                          setState(() => _isFrameOpen = false);
                          _showFeedbackDialog();
                        },
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

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F46E5),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
