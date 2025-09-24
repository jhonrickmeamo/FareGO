import 'package:flutter/material.dart';

class PaymentPopup {
  /// Returns a map with keys: "payment" (non-null String) and "discount" (nullable String).
  static Future<Map<String, String?>?> showPaymentDialog(
    BuildContext context,
  ) async {
    String? selectedDiscount;
    String selectedPayment = 'Cash'; // default

    return showDialog<Map<String, String?>?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero, // remove default padding
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

                        // ---- Dropdown (discount) ----
                        DropdownButtonFormField<String>(
                          initialValue: selectedDiscount,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          hint: const Text(
                            "Select Discount (optional)",
                            style: TextStyle(color: Colors.black),
                          ),
                          items:
                              <String>[
                                "No Discount",
                                "Student",
                                "Elderly",
                                "PWD",
                                "Pregnant Woman",
                              ].map((label) {
                                return DropdownMenuItem<String>(
                                  value: label,
                                  child: Text(
                                    label,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDiscount = value == "No Discount"
                                  ? null
                                  : value;
                            });
                          },
                        ),

                        const SizedBox(height: 14),

                        // ---- Radio buttons (payment) below the dropdown ----
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
                            onPressed: () {
                              Navigator.pop(context, {
                                "payment": selectedPayment,
                                "discount": selectedDiscount,
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

                        // optional Cancel
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
