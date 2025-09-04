import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final trips = [
      {
        "title": "Housing Terminal Jeep",
        "address": "1630 C5 Service Rd, Taguig, Metro Manila",
        "date": "10 April 2025, 10:30 AM",
        "payment": "",
        "amount": ""
      },
      {
        "title": "Guadalupe-Pateros Jeepney Stop",
        "address": "H20W+4P3, J.P. Rizal St, Makati, Metro Manila",
        "date": "",
        "payment": "Gcash",
        "amount": "₱21.00"
      },
      {
        "title": "Housing Terminal Jeep",
        "address": "1630 C5 Service Rd, Taguig, Metro Manila",
        "date": "13 April 2025, 3:49 PM",
        "payment": "",
        "amount": ""
      },
      {
        "title": "Market Market C5 Waiting Shed",
        "address":
            "G3W3+HFV, Carlos P. Garcia Ave, Taguig, Metro Manila",
        "date": "",
        "payment": "Gcash",
        "amount": "₱11.00"
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1DD3C6), // teal green header
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      "History",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // balance for back icon
                ],
              ),
            ),

            // History list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: trips.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.teal, thickness: 0.5),
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline dot
                      Column(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.teal, width: 2),
                            ),
                          ),
                          if (index != trips.length - 1)
                            Container(
                              width: 2,
                              height: 50,
                              color: Colors.teal.withOpacity(0.4),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Trip details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip["title"]!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              trip["address"]!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            if (trip["date"]!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                trip["date"]!,
                                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                              ),
                            ],
                            if (trip["payment"]!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.account_balance_wallet, size: 16, color: Colors.blue),
                                        const SizedBox(width: 4),
                                        Text(
                                          trip["payment"]!,
                                          style: const TextStyle(color: Colors.blue, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    trip["amount"]!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
