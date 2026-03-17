import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../models/location.dart' as location_model;
import 'student_report.dart'; // Add this import

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

  @override
  void initState() {
    super.initState();
    loadLocations();
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
          orElse: () => locations.first,
        );
      });
    } catch (e) {
      print("Error loading locations: $e");
    }
  }

  void calculateAmount() {
    if (oldLocation != null && newLocation != null) {
      setState(() {
        totalAmount = (newLocation!.fee - oldLocation!.fee).abs();
      });
    }
  }

  void _handlePaymentSuccess(dynamic response) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // First update the student's location
      await ApiService.updateStudent(widget.phone, {
        'location': newLocation!.name,
        'amountPaid': newLocation!.fee,
      });
      
      // Save the transaction
      await ApiService.saveTransaction({
        'paymentId': response['paymentId']?.toString() ?? '',
        'orderId': response['orderId']?.toString() ?? '',
        'studentId': widget.phone,
        'studentName': 'Location Change', // You might want to fetch actual student name
        'amount': totalAmount,
        'status': 'success',
        'type': 'location_change',
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully! Generating report...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait a moment for the user to see the success message
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // ✅ AUTOMATICALLY GENERATE AND NAVIGATE TO REPORT
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentReport(
            phone: widget.phone,
            dob: widget.dob,
            onLogout: () {
              // Handle logout if needed
              Navigator.pop(context);
            },
          ),
        ),
      );

    } catch (e) {
      print('Error in payment success handler: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handlePaymentFailure(dynamic response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response['message'] ?? 'Unknown error'}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void handlePay() {
    if (newLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select new location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (oldLocation?.id == newLocation?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New location must be different from old location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Open payment checkout
    _paymentService.openCheckout(
      amount: totalAmount,
      name: 'Location Change',
      phone: widget.phone,
      email: '', // Optional email
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Report - Change Location'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Info Card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Student Phone: ${widget.phone}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                const Text(
                  'Old Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<location_model.Route>(
                  value: oldLocation,
                  decoration: const InputDecoration(
                    labelText: 'Current Location',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  items: locations.map((r) {
                    return DropdownMenuItem<location_model.Route>(
                      value: r,
                      child: Text('${r.name} (₹${r.fee.toStringAsFixed(0)})'),
                    );
                  }).toList(),
                  onChanged: (location_model.Route? route) {
                    setState(() {
                      oldLocation = route;
                      calculateAmount();
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'New Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<location_model.Route>(
                  value: newLocation,
                  decoration: const InputDecoration(
                    labelText: 'Select New Location',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  items: locations.map((r) {
                    return DropdownMenuItem<location_model.Route>(
                      value: r,
                      child: Text('${r.name} (₹${r.fee.toStringAsFixed(0)})'),
                    );
                  }).toList(),
                  onChanged: (location_model.Route? route) {
                    setState(() {
                      newLocation = route;
                      calculateAmount();
                    });
                  },
                ),
                
                const SizedBox(height: 32),
                
                if (oldLocation != null && newLocation != null) ...[
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Old Location Fee:', style: TextStyle(fontSize: 16)),
                              Text(
                                '₹${oldLocation!.fee.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('New Location Fee:', style: TextStyle(fontSize: 16)),
                              Text(
                                '₹${newLocation!.fee.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Amount to Pay:',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹$totalAmount',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          
                          if (totalAmount == 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info, color: Colors.orange, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No payment required as fees are the same',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Pay Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing || totalAmount == 0 ? null : handlePay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: totalAmount > 0 ? Colors.blue : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Processing...'),
                              ],
                            )
                          : Text(
                              totalAmount > 0 ? 'Pay ₹$totalAmount' : 'No Payment Required',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  
                  if (totalAmount > 0) ...[
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Payment will automatically generate student report',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          
          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating report...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}