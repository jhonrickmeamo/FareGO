class TripInfo {
  final double totalDistance;
  final String startLocation;
  final String endLocation;
  final String tripDate;

  TripInfo({
    required this.totalDistance,
    required this.startLocation,
    required this.endLocation,
    required this.tripDate,
  });

  static String monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
