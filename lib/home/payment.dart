import 'package:flutter/material.dart';
import 'package:farego/services/paymongo_service.dart';
import 'package:farego/afterRide/fareDialog.dart' as calculateFare;

class PaymentPage extends StatefulWidget {
  final double trackedKm; // distance passed from your trip tracker

  const PaymentPage({super.key, required this.trackedKm});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  Future<void> _processPayment() async {
    // Default: No Discount
    double fare = calculateFare.calculateFare(widget.trackedKm, "No Discount");
    int amountInCentavos = (fare * 100).toInt();

    await PayMongoService.payWithGCash(
      amount: amountInCentavos,
      name: "",
      email: "",
      phone: "",
    );
  }

  @override
  Widget build(BuildContext context) {
    // Default: No Discount
    double fare = calculateFare.calculateFare(widget.trackedKm, "No Discount");

    return Scaffold(
      appBar: AppBar(title: const Text("Payment Summary")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Tracked Distance: ${widget.trackedKm.toStringAsFixed(2)} km"),
            Text("Total Fare: ₱${fare.toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _processPayment,
              child: const Text("Pay with GCash"),
            ),
          ],
        ),
      ),
    );
  }
}
