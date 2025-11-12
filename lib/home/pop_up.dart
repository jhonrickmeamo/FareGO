import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class PaymentPopup {
  /// Returns a map with keys: "payment" (non-null String) and "discount" (non-null String).
  static Future<Map<String, String?>?> showPaymentDialog(
    BuildContext context,
  ) async {
    String selectedPayment = "Cash"; // default

    return showDialog<Map<String, String?>?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: StatefulBuilder(
            builder:
                (
                  BuildContext context,
                  void Function(void Function()) setState,
                ) {
                  return Container(
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3ADDBC), Color(0xFFFFFFFF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Select Payment & Discount",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 18),

                        const SizedBox(height: 6),
                        const Text(
                          'Discount (if any) will be applied automatically from your profile.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        const SizedBox(height: 10),

                        // ---- Radio buttons (payment) ----
                        RadioListTile<String>(
                          title: const Text(
                            "Cash",
                            style: TextStyle(color: Colors.black),
                          ),
                          value: "Cash",
                          groupValue: selectedPayment,
                          onChanged: (value) =>
                              setState(() => selectedPayment = value!),
                        ),
                        RadioListTile<String>(
                          title: const Text(
                            "GCash",
                            style: TextStyle(color: Colors.black),
                          ),
                          value: "GCash",
                          groupValue: selectedPayment,
                          onChanged: (value) =>
                              setState(() => selectedPayment = value!),
                        ),

                        const SizedBox(height: 18),

                        // ---- Confirm ----
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              // Fetch user's stored discount from Firestore using device id
                              String discountToSend = "No Discount";

                              try {
                                final deviceInfo = DeviceInfoPlugin();
                                String? deviceId;
                                if (Platform.isAndroid) {
                                  final androidInfo = await deviceInfo.androidInfo;
                                  deviceId = androidInfo.id;
                                } else if (Platform.isIOS) {
                                  final iosInfo = await deviceInfo.iosInfo;
                                  deviceId = iosInfo.identifierForVendor;
                                } else {
                                  deviceId = null;
                                }

                                final resolvedId = deviceId ?? 'unknown_device';

                                final doc = await FirebaseFirestore.instance.collection('User').doc(resolvedId).get();
                                if (doc.exists) {
                                  final data = doc.data();
                                  if (data != null) {
                                    final String? storedType = (data['discountType'] as String?)?.trim();
                                    final String? status = (data['discountStatus'] as String?)?.toLowerCase();

                                    // Only apply the stored discount if the user's discountStatus
                                    // has been verified/approved. Treat 'verified' or 'approved'
                                    // as positive; everything else defaults to no discount.
                                    if (storedType != null && storedType.isNotEmpty && (status == 'verified' || status == 'approved')) {
                                      discountToSend = storedType;
                                    } else {
                                      discountToSend = 'No Discount';
                                    }
                                  }
                                }
                              } catch (e) {
                                // If any error occurs, default to No Discount
                                discountToSend = "No Discount";
                              }

                              // Return the selected payment method and the user's discount
                              Navigator.pop(context, {
                                'paymentMethod': selectedPayment,
                                'discount': discountToSend,
                              });
                            },
                            child: const Text(
                              "Confirm",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  );
                },
          ),
        );
      },
    );
  }
}
