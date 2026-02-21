import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class StudentReport extends StatefulWidget {
  final String phone;
  final String dob;
  final VoidCallback? onLogout;

  const StudentReport({super.key, required this.phone, required this.dob, this.onLogout});

  @override
  State<StudentReport> createState() => _StudentReportState();
}

class _StudentReportState extends State<StudentReport> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onWallet: () => print('Wallet selected'),
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Success: ${response.paymentId}'), backgroundColor: Colors.green),
    );
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void _makePayment() {
    if (studentData != null) {
      _paymentService.openCheckout(
        amount: (studentData!['totalDue'] ?? 0).toDouble(),
        name: studentData!['name'] ?? '',
        phone: studentData!['phone'] ?? '',
        email: '${studentData!['rollNo']}@student.com',
      );
    }
  }

  Future<void> _loadStudentData() async {
    try {
      final students = await ApiService.getStudents();
      final student = students.firstWhere(
        (s) => s['phone'] == widget.phone && s['dob']?.toString().split('T')[0] == widget.dob,
        orElse: () => {},
      );

      setState(() {
        studentData = student.isNotEmpty ? student : null;
        isLoading = false;
      });

      // Save report to database
      if (studentData != null) {
        await ApiService.saveReport({
          'studentId': studentData!['id'],
          'phone': studentData!['phone'],
          'name': studentData!['name'],
          'rollNo': studentData!['rollNo'],
          'studentClass': studentData!['studentClass'],
          'parentName': studentData!['parentName'],
          'address': studentData!['address'],
          'location': studentData!['location'],
          'totalDue': studentData!['totalDue'],
          'amountPaid': studentData!['amountPaid'],
          'status': studentData!['status'],
          'dob': studentData!['dob']?.toString().split('T')[0],
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading student: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {},
            tooltip: 'Print Report',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              print('Logout button clicked');
              if (widget.onLogout != null) {
                print('Calling onLogout');
                widget.onLogout!();
              } else {
                print('onLogout is null');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : studentData == null
              ? const Center(child: Text('No data found'))
              : Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'STUDENT REPORT',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 3,
                                width: 200,
                                color: const Color(0xFF4F46E5),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        
                        _buildSectionTitle('PERSONAL INFORMATION'),
                        _buildInfoRow('Name', studentData!['name'] ?? 'N/A'),
                        _buildInfoRow('Roll No', studentData!['rollNo'] ?? 'N/A'),
                        _buildInfoRow('Class', studentData!['studentClass'] ?? 'N/A'),
                        _buildInfoRow('Date of Birth', studentData!['dob']?.toString().split('T')[0] ?? 'N/A'),
                        _buildInfoRow('Phone', studentData!['phone'] ?? 'N/A'),
                        
                        const SizedBox(height: 32),
                        
                        _buildSectionTitle('PARENT INFORMATION'),
                        _buildInfoRow('Parent Name', studentData!['parentName'] ?? 'N/A'),
                        _buildInfoRow('Address', studentData!['address'] ?? 'N/A'),
                        
                        const SizedBox(height: 32),
                        
                        _buildSectionTitle('FEE INFORMATION'),
                        _buildInfoRow('Location', studentData!['location'] ?? 'N/A'),
                        _buildInfoRow('Total Due', '₹${studentData!['totalDue'] ?? 0}'),
                        _buildInfoRow('Amount Paid', '₹${studentData!['amountPaid'] ?? 0}'),
                        _buildInfoRow('Status', (studentData!['status'] ?? 'N/A').toString().toUpperCase()),
                        if (studentData!['registrationDate'] != null)
                          _buildInfoRow('Registration Date', 
                            DateTime.parse(studentData!['registrationDate']).toString().split('.')[0]),
                        
                        if ((studentData!['totalDue'] ?? 0) > 0) ...[
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _makePayment,
                              icon: const Icon(Icons.payment),
                              label: Text('Pay Now ₹${studentData!['totalDue']}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 48),
                        
                        const Divider(thickness: 2),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Generated: ${DateTime.now().toString().split('.')[0]}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const Text(
                              'Authorized Signature: __________',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4F46E5),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
