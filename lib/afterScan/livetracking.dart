import 'package:farego/afterRide/ridecomplete.dart';
import 'package:farego/directions_repository.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LiveTracking extends StatefulWidget {
  const LiveTracking({super.key});

  @override
  State<LiveTracking> createState() => _LiveTrackingState();
}

class _LiveTrackingState extends State<LiveTracking> {
  static const gmf.CameraPosition _initialCameraPosition = gmf.CameraPosition(
    target: gmf.LatLng(14.525746834655928, 121.02739557695888),
    zoom: 15.5,
  );

  gmf.GoogleMapController? _googleMapController;
  final Set<gmf.Polyline> _polylines = {};
  final Set<gmf.Marker> _markers = {};
  StreamSubscription<Position>? _positionStream;
  gmf.LatLng? _previousLocation;
  double _totalDistance = 0.0; // Tracked distance in km
  String? _startLocation; //new
  String? _endLocation; //new
  late String _tripDate; //new
  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1]; //new
  }

  @override
  void initState() {
    super.initState();
    _getRoute();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }

  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 1,
    );

    final List<Position> recentPositions = [];

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          if (position.accuracy > 50) {
            debugPrint("Skipped inaccurate GPS fix (${position.accuracy}m)");
            return;
          }

          recentPositions.add(position);
          if (recentPositions.length > 3) {
            recentPositions.removeAt(0);
          }

          final avgLat =
              recentPositions.map((p) => p.latitude).reduce((a, b) => a + b) /
              recentPositions.length;
          final avgLng =
              recentPositions.map((p) => p.longitude).reduce((a, b) => a + b) /
              recentPositions.length;

          final smoothed = gmf.LatLng(avgLat, avgLng);

          if (_previousLocation != null) {
            final distance = Geolocator.distanceBetween(
              _previousLocation!.latitude,
              _previousLocation!.longitude,
              smoothed.latitude,
              smoothed.longitude,
            );

            if (distance > 10) {
              setState(() => _totalDistance += distance / 1000);
            }
          }
          _previousLocation = smoothed;
          _updateGpsMarker(smoothed);

          _googleMapController?.moveCamera(
            gmf.CameraUpdate.newLatLng(smoothed),
          );
        });
  }

  double _calculateFare() {
    const baseFare = 11.0;

    if (_totalDistance <= 4.0) return baseFare;

    final extraKm = (_totalDistance - 4.0).ceil();
    return baseFare + (extraKm * 2);
  }

  Future<void> _getRoute() async {
    final directionsRepo = DirectionsRepository();

    const stops = [
      gmf.LatLng(14.525358661730701, 121.02747872520852), //gate 3
      gmf.LatLng(14.544995228139575, 121.04581609472868), //5th avenue
      gmf.LatLng(14.549281023919875, 121.05519585826289), //market market
      gmf.LatLng(14.55276679479669, 121.05723779785644),
      gmf.LatLng(14.555759576543378, 121.05840030437734),
      gmf.LatLng(14.558254711584864, 121.05785975110224),
      gmf.LatLng(
        14.558636336509108,
        121.05553695811646,
      ), //38th street dexterton corporation BGC
      gmf.LatLng(14.562038463249534, 121.05410781758737),
      gmf.LatLng(14.562418448516608, 121.05361517175132),
      gmf.LatLng(14.5591640250085, 121.0461692474), // 7-11 guadalupe
      gmf.LatLng(14.564169106132724, 121.04529109452648), // andoks guadalupe
      //pabalik ng market route
    ];

    if (stops.length < 2) return;

    final List<gmf.Polyline> newPolylines = [];

    for (int i = 0; i < stops.length - 1; i++) {
      final polylinePoints = await directionsRepo.getRoutePolyline(
        origin: stops[i],
        destination: stops[i + 1],
      );
      _tripDate =
          "${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}";
      _startLocation =
          "Start: ${stops.first.latitude.toStringAsFixed(5)}, ${stops.first.longitude.toStringAsFixed(5)}";
      _endLocation =
          "End: ${stops.last.latitude.toStringAsFixed(5)}, ${stops.last.longitude.toStringAsFixed(5)}"; //new

      if (polylinePoints != null && polylinePoints.isNotEmpty) {
        newPolylines.add(
          gmf.Polyline(
            polylineId: gmf.PolylineId('segment$i'),
            color: _segmentColor(i),
            width: 5,
            points: polylinePoints,
          ),
        );
      }
    }

    if (newPolylines.isNotEmpty) {
      setState(() => _polylines.addAll(newPolylines));
      _addLineMarkers(stops);
    }
  }

  /// Cycle segment colors
  Color _segmentColor(int index) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }

  void _addLineMarkers(List<gmf.LatLng> stops) {
    final markers = <gmf.Marker>{};

    for (int i = 0; i < stops.length; i++) {
      if (i == 0 || i == stops.length - 1 /* || i % 3 == 0 */ ) {
        final initialPos = stops[i];

        markers.add(
          gmf.Marker(
            markerId: gmf.MarkerId('stop$i'),
            position: initialPos,
            draggable: true,
            onDragEnd: (newPos) {
              final distance = Geolocator.distanceBetween(
                initialPos.latitude,
                initialPos.longitude,
                newPos.latitude,
                newPos.longitude,
              );

              setState(() {
                _totalDistance = distance / 1000; // convert to km
              });
            },
            infoWindow: gmf.InfoWindow(
              title: 'Stop $i',
              snippet: 'Drag to test distance',
            ),
            icon: gmf.BitmapDescriptor.defaultMarkerWithHue(
              i == 0
                  ? gmf.BitmapDescriptor.hueRed
                  : i == stops.length - 1
                  ? gmf.BitmapDescriptor.hueGreen
                  : gmf.BitmapDescriptor.hueBlue,
            ),
          ),
        );
      }
    }
    setState(() => _markers.addAll(markers));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _positionStream?.cancel();

                  final fare = _calculateFare().toStringAsFixed(2);
                  final start = _startLocation ?? 'Unknown';
                  final end = _endLocation ?? 'Unknown';
                  final date = _tripDate;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentCompletedPage(
                        date: date,
                        startLocation: start,
                        endLocation: end,
                        fare: fare,
                      ),
                    ),
                  );
                },
                label: const Text(
                  'End Trip',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'FareGO',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.green[700]),
      ),
      body: Column(
        children: [
          _buildInfoBar(),
          Expanded(
            child: gmf.GoogleMap(
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              initialCameraPosition: _initialCameraPosition,
              polylines: _polylines,
              markers: _markers,
              onMapCreated: (controller) => _googleMapController = controller,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_previousLocation != null) {
            _googleMapController?.animateCamera(
              gmf.CameraUpdate.newCameraPosition(
                gmf.CameraPosition(target: _previousLocation!, zoom: 15),
              ),
            );
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  /// Top info bar (distance + fare)
  Widget _buildInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _infoColumn(
            'Distance Traveled',
            '${_totalDistance.toStringAsFixed(2)} km',
          ),
          _infoColumn(
            'Current Fare',
            '₱${_calculateFare().toStringAsFixed(0)}',
            alignRight: true,
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value, {bool alignRight = false}) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.green[700],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _updateGpsMarker(gmf.LatLng newLocation) {
    final marker = gmf.Marker(
      markerId: const gmf.MarkerId('gps_marker'),
      position: newLocation,
      // 👇 default marker (no custom icon)
      icon: gmf.BitmapDescriptor.defaultMarkerWithHue(
        gmf.BitmapDescriptor.hueBlue,
      ),
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'gps_marker');
      _markers.add(marker);
    });
  }
}
