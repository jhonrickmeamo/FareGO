import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Map<String, dynamic>>> _tripHistoryFuture;

  @override
  void initState() {
    super.initState();
    _tripHistoryFuture = _fetchTrips();
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id ?? "unknown_android";
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "unknown_ios";
    } else {
      return "unknown_device";
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTrips() async {
    final deviceId = await _getDeviceId();
    final tripCollection = FirebaseFirestore.instance
        .collection("User")
        .doc(deviceId)
        .collection("Trips"); // ✅ capital T

    final snapshot =
        await tripCollection.orderBy('timestamp', descending: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        "title": data["start_location"] ?? "Unknown Start",
        "address": data["end_location"] ?? "Unknown End",
        "date": data["date"] ?? "",
        "payment": data["payment_method"] ?? "",
        "amount": data["total"] != null ? "₱${data["total"]}" : "",
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1DD3C6),
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
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Trip list
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _tripHistoryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final trips = snapshot.data ?? [];

                  if (trips.isEmpty) {
                    return const Center(child: Text("No trip history found"));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: trips.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.teal, thickness: 0.5),
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
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
                                ),
                                if (trip["date"]!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    trip["date"]!,
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 12),
                                  ),
                                ],
                                if (trip["payment"]!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.account_balance_wallet,
                                              size: 16,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              trip["payment"]!,
                                              style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 12),
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
