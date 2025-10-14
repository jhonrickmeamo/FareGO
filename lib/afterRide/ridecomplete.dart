import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentCompletedPage extends StatelessWidget {
  final String date;
  final String startLocation;
  final String endLocation;
  final String fare;
  final String paymentMethod;
  final String jeepneyID; // ✅ Added jeepneyID field

  const PaymentCompletedPage({
    super.key,
    required this.date,
    required this.startLocation,
    required this.endLocation,
    required this.fare,
    required this.paymentMethod,
    required this.jeepneyID, // ✅ Added to constructor
  });

  // ✅ Save trip data to Firestore including jeepneyID
  Future<void> saveTripToFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('payments').add({
        'date': date,
        'startLocation': startLocation,
        'endLocation': endLocation,
        'fare': fare,
        'paymentMethod': paymentMethod,
        'jeepneyID': jeepneyID, // ✅ Include jeepneyID in database
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Payment saved successfully for $jeepneyID");
    } catch (e) {
      debugPrint("❌ Error saving payment: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Save the trip automatically when the page opens
    saveTripToFirestore();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF05D1B6),
        elevation: 0,
        title: const Text(
          'Trip Completed',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF05D1B6),
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment Completed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Date: $date',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Divider(height: 30, thickness: 1),
                  _infoRow('Start Location:', startLocation),
                  _infoRow('End Location:', endLocation),
                  _infoRow('Jeepney ID:', jeepneyID), // ✅ Show jeepneyID
                  const Divider(height: 30, thickness: 1),
                  Text(
                    '₱$fare',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF05D1B6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
