class FareCalculator {
  static double calculate(
    double totalDistanceKm, {
    String discountType = 'None',
  }) {
    double baseFare = 11.0;
    double perKm = 2.0;

    // 🚍 Apply discounts based on your client's fare chart
    switch (discountType.toLowerCase()) {
      case 'student':
      case 'pwd':
      case 'senior':
      case 'elderly':
      case 'pregnant':
        baseFare = 9.0;
        perKm = 1.60;
        break;
      default:
        baseFare = 11.0;
        perKm = 2.0;
        break;
    }

    if (totalDistanceKm <= 4.0) return baseFare;

    final extraKm = (totalDistanceKm - 4.0).ceil();
    return baseFare + (extraKm * perKm);
  }
}
