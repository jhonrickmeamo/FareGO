import 'package:flutter/material.dart';
import 'package:farego/services/paymongo_service.dart';
import 'package:farego/home/payment.dart';
import 'package:farego/home/pop_up.dart';

Future<void> _showFareDialog(BuildContext context, double distanceKm) async {
  final result = await PaymentPopup.showPaymentDialog(context);

  if (result != null) {
    String paymentMethod = result["payment"]!;
    String passengerType = result["discount"]!;

    double fare = FareCalculator.calculateFare(distanceKm, passengerType);

    if (paymentMethod == "Cash") {
      // ✅ Show fare only
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Passenger: $passengerType\n
            "Payment: $paymentMethod\n"
            "Distance: ${distanceKm.toStringAsFixed(1)} km\n"
            "Fare: ₱${fare.toStringAsFixed(2)}",
          ),
        ),
      );
    } else if (paymentMethod == "GCash") {
      // ✅ Trigger PayMongo payment
      try {
        int amountInCentavos = (fare * 100).toInt();

        await PayMongoService.payWithGCash(
          amount: amountInCentavos,
          name: "", 
          email: "",
          phone: "",
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("GCash payment initiated.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: $e")),
        );
      }
    }
  }
}
