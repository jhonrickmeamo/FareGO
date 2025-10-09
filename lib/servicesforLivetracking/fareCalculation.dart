class FareCalculator {
  static double calculate(double totalDistanceKm) {
    const baseFare = 11.0;

    if (totalDistanceKm <= 4.0) return baseFare;

    final extraKm = (totalDistanceKm - 4.0).ceil();
    return baseFare + (extraKm * 2);
  }
}
