import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PaymentCompletedPage extends StatelessWidget {
  final String date;
  final String startLocation;
  final String endLocation;
  final String fare; // 👈 already discounted (from livetracking.dart)
  final String paymentMethod;
  final String discount;
  final String jeepneyID;
  final String driverName;
  final String jeepneyNumber;

  const PaymentCompletedPage({
    super.key,
    required this.date,
    required this.startLocation,
    required this.endLocation,
    required this.fare,
    required this.paymentMethod,
    required this.discount,
    required this.jeepneyID,
    required this.driverName,
    required this.jeepneyNumber,
  });

  // ✅ Reliable GCash launcher (tested method)
  Future<void> _openGCashApp(BuildContext context) async {
    const gcashUri = 'gcash://';
    const gcashPlayStoreUrl =
        'https://play.google.com/store/apps/details?id=com.globe.gcash.android';

    try {
      final gcashApp = Uri.parse(gcashUri);
      final gcashStore = Uri.parse(gcashPlayStoreUrl);

      bool launched = false;

      // ✅ Try to open GCash via its URL scheme
      if (await canLaunchUrl(gcashApp)) {
        launched = await launchUrl(
          gcashApp,
          mode: LaunchMode.externalApplication,
        );
      }

      // ❌ If GCash not installed or fails, open Play Store
      if (!launched) {
        await launchUrl(gcashStore, mode: LaunchMode.externalApplication);
      }

      // ✅ Save trip info to Firestore
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = "unknown_device";

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id ?? "unknown_android";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? "unknown_ios";
      }

      await FirebaseFirestore.instance
          .collection("User")
          .doc(deviceId)
          .collection("Trips")
          .add({
            "date": date,
            "payment_method": paymentMethod,
            "discount": discount,
            "start_location": startLocation,
            "end_location": endLocation,
            "total": fare,
            "jeepneyID": jeepneyID,
            "driverName": driverName,
            "jeepneyNumber": jeepneyNumber,
            "timestamp": FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip saved! Redirecting to GCash app...'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching GCash: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3ADDBC), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ✅ Transaction Details
                Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "🧾 Transaction Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow("Date", date),
                    _buildDetailRow("Start Location", startLocation),
                    _buildDetailRow("End Location", endLocation),
                    _buildDetailRow("Payment Method", paymentMethod),
                    _buildDetailRow("Discount", discount),
                    _buildDetailRow("Jeepney Number", jeepneyNumber),
                    _buildDetailRow("Driver Name", driverName),
                    const Divider(thickness: 1.5),
                    _buildDetailRow("Total Fare", "₱$fare", isHighlight: true),
                  ],
                ),

                // ✅ Slide Action for GCash (bottom)
                if (paymentMethod == "GCash")
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: SlideAction(
                      text: 'Slide to Pay via GCash',
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      innerColor: Colors.white.withOpacity(0.2),
                      outerColor: Colors.green,
                      borderRadius: 16,
                      elevation: 4,
                      onSubmit: () async {
                        await _openGCashApp(context);
                      },
                    ),
                  )
                else
                  Column(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 80),
                      SizedBox(height: 10),
                      Text(
                        "Payment Successful!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: isHighlight ? Colors.green[700] : Colors.black87,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
