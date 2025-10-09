import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;
import 'package:geolocator/geolocator.dart';
import 'package:farego/afterRide/ridecomplete.dart';
import 'package:farego/servicesforLivetracking/fareCalculation.dart';
import 'package:farego/servicesforLivetracking/route_service.dart';
import 'package:farego/servicesforLivetracking/trip_info.dart';

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
  double _totalDistance = 0.0;
  gmf.LatLng? _previousLocation;

  late TripInfo _tripInfo;
  StreamSubscription<Position>? _positionStream;

  final RouteService _routeService = RouteService();

  @override
  void initState() {
    super.initState();
    _initTripInfo();
    _getRoute(); // only for polylines/markers
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }

  /// Initialize trip info with placeholder end location
  void _initTripInfo() {
    final now = DateTime.now();
    _tripInfo = TripInfo(
      totalDistance: 0.0,
      startLocation: 'Loading...',
      endLocation: 'Loading...',
      tripDate: "${now.day} ${TripInfo.monthName(now.month)} ${now.year}",
    );
  }

  /// Track user location and calculate distance
  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
    );

    bool isStartCaptured = false;

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
      if (position.accuracy > 30) return;

      final newLocation = gmf.LatLng(position.latitude, position.longitude);

      // Capture start location once
      if (!isStartCaptured) {
        _tripInfo = TripInfo(
          totalDistance: _totalDistance,
          startLocation:
              "Start: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}",
          endLocation: _tripInfo.endLocation,
          tripDate: _tripInfo.tripDate,
        );
        isStartCaptured = true;
      }

      // Calculate distance
      if (_previousLocation != null) {
        final distance = Geolocator.distanceBetween(
          _previousLocation!.latitude,
          _previousLocation!.longitude,
          newLocation.latitude,
          newLocation.longitude,
        );
        if (distance > 2) _totalDistance += distance / 1000;
      }

      _previousLocation = newLocation;

      // Move camera
      _googleMapController?.animateCamera(
        gmf.CameraUpdate.newCameraPosition(
          gmf.CameraPosition(target: newLocation, zoom: 16),
        ),
      );

      setState(() {}); // Refresh UI
    });
  }

  /// Load route polylines and markers using RouteService
  Future<void> _getRoute() async {
    final stops = [
      gmf.LatLng(14.525358661730701, 121.02747872520852),
      gmf.LatLng(14.544995228139575, 121.04581609472868),
      gmf.LatLng(14.549281023919875, 121.05519585826289),
      gmf.LatLng(14.55276679479669, 121.05723779785644),
      gmf.LatLng(14.555759576543378, 121.05840030437734),
      gmf.LatLng(14.558254711584864, 121.05785975110224),
      gmf.LatLng(14.558636336509108, 121.05553695811646),
      gmf.LatLng(14.562038463249534, 121.05410781758737),
      gmf.LatLng(14.562418448516608, 121.05361517175132),
      gmf.LatLng(14.5591640250085, 121.0461692474),
      gmf.LatLng(14.564169106132724, 121.04529109452648),
    ];

    final polylines = await _routeService.getRoutePolylines(stops);
    final markers = _routeService.getRouteMarkers(stops);

    setState(() {
      _polylines.addAll(polylines);
      _markers.addAll(markers);
    });
  }

  /// End trip and navigate to PaymentCompletedPage
  void _endTrip() async {
    _positionStream?.cancel();

    // Get current GPS for end location
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);

    _tripInfo = TripInfo(
      totalDistance: _totalDistance,
      startLocation: _tripInfo.startLocation,
      endLocation:
          "End: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}",
      tripDate: _tripInfo.tripDate,
    );

    final fare = FareCalculator.calculate(_totalDistance).toStringAsFixed(2);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentCompletedPage(
          date: _tripInfo.tripDate,
          startLocation: _tripInfo.startLocation,
          endLocation: _tripInfo.endLocation,
          fare: fare,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              initialCameraPosition: _initialCameraPosition,
              polylines: _polylines,
              markers: _markers,
              onMapCreated: (controller) => _googleMapController = controller,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
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
                onPressed: _endTrip,
                icon: const Icon(Icons.flag),
                label: const Text(
                  'End Trip',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top info bar showing distance and fare
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
          _infoColumn('Distance Traveled', '${_totalDistance.toStringAsFixed(2)} km'),
          _infoColumn(
            'Current Fare',
            '₱${FareCalculator.calculate(_totalDistance).toStringAsFixed(0)}',
            alignRight: true,
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value, {bool alignRight = false}) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
}
