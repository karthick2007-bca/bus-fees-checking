import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../models/location.dart' as location_model;
import 'package:razorpay_flutter/razorpay_flutter.dart';

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

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await ApiService.updateStudent(widget.phone, {
      'location': newLocation!.name,
      'amountPaid': newLocation!.fee,
    });
    
    await ApiService.saveTransaction({
      'paymentId': response.paymentId,
      'orderId': response.orderId,
      'studentId': widget.phone,
      'amount': totalAmount,
      'status': 'success',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location updated successfully'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void handlePay() {
    if (newLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select new location')),
      );
      return;
    }

    _paymentService.openCheckout(
      amount: totalAmount,
      name: 'Location Change',
      phone: widget.phone,
      email: '${widget.phone}@student.com',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Old Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<location_model.Route>(
              value: oldLocation,
              decoration: const InputDecoration(
                labelText: 'Current Location',
                prefixIcon: Icon(Icons.location_on),
              ),
              items: locations.map((r) {
                return DropdownMenuItem<location_model.Route>(
                  value: r,
                  child: Text('${r.name} (₹${r.fee})'),
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
            const Text('New Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<location_model.Route>(
              value: newLocation,
              decoration: const InputDecoration(
                labelText: 'Select New Location',
                prefixIcon: Icon(Icons.location_on),
              ),
              items: locations.map((r) {
                return DropdownMenuItem<location_model.Route>(
                  value: r,
                  child: Text('${r.name} (₹${r.fee})'),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Old Location Fee:'),
                          Text('₹${oldLocation!.fee}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('New Location Fee:'),
                          Text('₹${newLocation!.fee}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount to Pay:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('₹$totalAmount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: handlePay,
                  child: const Text('Pay'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
