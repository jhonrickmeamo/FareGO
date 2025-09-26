import 'package:flutter/material.dart';
import 'package:farego/services/paymongo_service.dart';
import 'package:farego/home/payment.dart';
import 'package:farego/home/pop_up.dart';
import 'dart:async';
import 'package:farego/afterRide/fareDialog.dart'
    as _calculateFare; // ✅ fixed alias
import 'package:farego/afterScan/livetracking.dart';

double calculateFare(double distanceKm, String passengerType) {
  double baseFare = 40.0;
  double perKmRate = 12.0;

  double fare = baseFare + (distanceKm * perKmRate);

  if (passengerType == "Student" ||
      passengerType == "Senior" ||
      passengerType == "PWD" ||
      passengerType == "Pregnant") {
    fare = 9.00;
  }

  return fare;
}

Future<void> _showFareDialog(BuildContext context, double distanceKm) async {
  final result = await PaymentPopup.showPaymentDialog(context);

  if (result != null) {
    String paymentMethod = result["payment"]!;
    String passengerType = result["discount"]!;

    // ✅ Now this will work because calculateFare exists in fareDialog.dart
    double fare = _calculateFare.calculateFare(distanceKm, passengerType);

    if (paymentMethod == "Cash") {
      // ✅ Show fare only
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Passenger: $passengerType\n"
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Payment failed: $e")));
      }
    }
  }
}
