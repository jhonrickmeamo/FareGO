class TripInfo {
  late final double totalDistance;
   String startLocation;
   String endLocation;
  final String tripDate;
  final String paymentMethod;

  TripInfo({
    required this.totalDistance,
    required this.startLocation,
    required this.endLocation,
    required this.tripDate,
    this.paymentMethod = 'cash',
  });

  static String monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
