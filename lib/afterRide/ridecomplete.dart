import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:farego/xendit_payment.dart';
import 'package:farego/webview_payment_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PaymentCompletedPage extends StatelessWidget {
  final String date;
  final String startLocation;
  final String endLocation;
  final String fare;
  final String paymentMethod;
  final String jeepneyID;

  const PaymentCompletedPage({
    super.key,
    required this.date,
    required this.startLocation,
    required this.endLocation,
    required this.fare,
    required this.paymentMethod,
    required this.jeepneyID,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00D2A0), Color(0xFF3EE7C9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF00D2A0),
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaction details',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Date', date),
                      const SizedBox(height: 12),
                      _buildDetailRow('Payment Method', paymentMethod),
                      const SizedBox(height: 12),
                      _buildDetailRow('Jeepney ID', jeepneyID),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.circle_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              startLocation,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              endLocation,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Total', '₱$fare'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Builder(
                  builder: (context) {
                    return SlideAction(
                      outerColor: const Color(0xFF00D2A0),
                      innerColor: Colors.white,
                      text: "Slide to Confirm",
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      sliderButtonIcon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF00D2A0),
                      ),
                      onSubmit: () async {
                        try {
                          // 1️⃣ Get device unique ID
                          final deviceInfo = DeviceInfoPlugin();
                          String deviceId = "unknown_device";

                          if (Platform.isAndroid) {
                            final androidInfo = await deviceInfo.androidInfo;
                            deviceId = androidInfo.id ?? "unknown_android";
                          } else if (Platform.isIOS) {
                            final iosInfo = await deviceInfo.iosInfo;
                            deviceId =
                                iosInfo.identifierForVendor ?? "unknown_ios";
                          }

                          // 2️⃣ Create Xendit invoice
                          final checkoutUrl = await createXenditInvoice(
                            double.parse(fare),
                            "Fare Payment from $startLocation to $endLocation on $date",
                          );

                          // 3️⃣ Open WebView for payment
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WebViewPaymentPage(paymentUrl: checkoutUrl),
                            ),
                          );

                          // 4️⃣ Handle payment result
                          if (result == true) {
                            // 5️⃣ Save trip details to Firebase
                            await FirebaseFirestore.instance
                                .collection("User")
                                .doc(deviceId)
                                .collection("Trips")
                                .add({
                                  "date": date,
                                  "payment_method": paymentMethod,
                                  "start_location": startLocation,
                                  "end_location": endLocation,
                                  "total": fare,
                                  "jeepneyID": jeepneyID, // ✅ Save jeepneyID
                                  "timestamp": FieldValue.serverTimestamp(),
                                });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Payment successful & saved to Firebase!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment failed or cancelled.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
