import 'package:cloud_firestore/cloud_firestore.dart';

class FareCalculator {
  static double baseFare = 11.0;
  static double perKm = 2.0;
  static double discountedBaseFare = 9.0;
  static double discountedPerKm = 1.6;
  static bool isLoaded = false;

  /// 🔹 Fetch fare rates from Firestore
  static Future<void> loadFareRates() async {
    try {
      // Expecting a collection where at least one document contains the fare rates.
      // Use a query and take the first document to support collections without a fixed doc id.
      final snapshot = await FirebaseFirestore.instance
          .collection('basefare')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();

        // Safely parse numeric fields which could be int or double in Firestore
        double parseNum(dynamic v, double fallback) {
          if (v == null) return fallback;
          if (v is num) return v.toDouble();
          if (v is String) return double.tryParse(v) ?? fallback;
          return fallback;
        }

        baseFare = parseNum(data['baseFare'] ?? data['base_fare'], 11.0);
        perKm = parseNum(data['perKm'] ?? data['per_km'] ?? data['perKM'], 2.0);
        discountedBaseFare = parseNum(data['discountedBaseFare'] ?? data['discounted_base_fare'], 9.0);
        discountedPerKm = parseNum(data['discountedPerKm'] ?? data['discounted_per_km'], 1.6);
        isLoaded = true;
        print("✅ Fare rates loaded from Firestore (collection/basefare)");
      } else {
        print("⚠️ No fare documents found in 'basefare' collection; using defaults.");
      }
    } catch (e) {
      print("❌ Error loading fare rates: $e");
    }
  }

  /// Force refresh rates from Firestore (useful for admin changes)
  static Future<void> refreshRates() async {
    isLoaded = false;
    await loadFareRates();
  }

  /// 💰 Calculate fare dynamically
  static double calculate(
    double totalDistanceKm, {
    String discountType = 'None',
  }) {
    double fareBase = baseFare;
    double farePerKm = perKm;

    // 🚍 Apply discounts based on the loaded Firestore data
    switch (discountType.toLowerCase()) {
      case 'student':
      case 'pwd':
      case 'senior':
      case 'elderly':
      case 'pregnant':
        fareBase = discountedBaseFare;
        farePerKm = discountedPerKm;
        break;
      default:
        fareBase = baseFare;
        farePerKm = perKm;
        break;
    }

    if (totalDistanceKm <= 4.0) return fareBase;

    final extraKm = (totalDistanceKm - 4.0).ceil();
    return fareBase + (extraKm * farePerKm);
  }
}
