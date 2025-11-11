import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:farego/afterRide/ridecomplete.dart';
import 'package:farego/servicesforLivetracking/fareCalculation.dart';
import 'package:farego/servicesforLivetracking/route_service.dart';
import 'package:farego/servicesforLivetracking/trip_info.dart';

class LiveTracking extends StatefulWidget {
  final String jeepneyID;
  final String paymentMethod;
  final String discount; // e.g. "student", "pwd", "none"
  final String jeepneyNumber;
  final String driverName;
  final bool demoMode; // ✅ Toggle for simulation

  const LiveTracking({
    super.key,
    required this.jeepneyID,
    required this.paymentMethod,
    required this.discount,
    required this.jeepneyNumber,
    required this.driverName,
    this.demoMode = false,
  });

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
  StreamSubscription<gmf.LatLng>? _positionStream;

  final RouteService _routeService = RouteService();
  bool _isDemoMode = false;

  List<gmf.LatLng> _demoRoutePoints = [];

  @override
  void initState() {
    super.initState();
    _isDemoMode = widget.demoMode;
    _initTripInfo();
    _getRoute();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }

  void _initTripInfo() {
    final now = DateTime.now();
    _tripInfo = TripInfo(
      totalDistance: 0.0,
      startLocation: 'Loading...',
      endLocation: 'Loading...',
      tripDate: "${now.day} ${TripInfo.monthName(now.month)} ${now.year}",
      paymentMethod: widget.paymentMethod,
    );
  }

  Future<String> _getAddressFromLatLng(gmf.LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return "${p.name ?? ''}, ${p.locality ?? ''}";
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
    }
    return "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
  }

  // ✅ Loop over the demo route points continuously
  Stream<gmf.LatLng> _simulateRouteLoop({int intervalMs = 1000}) async* {
    if (_demoRoutePoints.isEmpty) return;
    while (true) {
      for (var point in _demoRoutePoints) {
        await Future.delayed(Duration(milliseconds: intervalMs));
        yield point;
      }
    }
  }

  void _toggleDemoMode() {
    setState(() {
      _isDemoMode = !_isDemoMode;
    });

    _positionStream?.cancel();
    _previousLocation = null;
    _totalDistance = 0.0;

    // Remove moving marker only, keep stops
    _markers.removeWhere((m) => m.markerId.value == 'jeepney_marker');

    _initTripInfo();
    _startLocationTracking();
  }

  void _startLocationTracking() async {
    bool isStartCaptured = false;
    Stream<gmf.LatLng> locationStream;

    if (_isDemoMode) {
      locationStream = _simulateRouteLoop(intervalMs: 800);
    } else {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      );
      locationStream = Geolocator.getPositionStream(
              locationSettings: locationSettings)
          .map((pos) => gmf.LatLng(pos.latitude, pos.longitude));
    }

    _positionStream = locationStream.listen((newLocation) async {
      // Distance calculation
      if (_previousLocation != null) {
        if (_isDemoMode) {
          _totalDistance += 0.15; // 150m per tick for demo
        } else {
          final distance = Geolocator.distanceBetween(
            _previousLocation!.latitude,
            _previousLocation!.longitude,
            newLocation.latitude,
            newLocation.longitude,
          );
          if (distance < 2) return;
          _totalDistance += distance / 1000;
        }
      }

      // Capture start location
      if (!isStartCaptured) {
        final startAddress = await _getAddressFromLatLng(newLocation);
        _tripInfo.startLocation = startAddress;
        _markers.add(
          gmf.Marker(
            markerId: const gmf.MarkerId('start'),
            position: newLocation,
            icon: gmf.BitmapDescriptor.defaultMarkerWithHue(
                gmf.BitmapDescriptor.hueGreen),
            infoWindow: gmf.InfoWindow(title: "Start", snippet: startAddress),
          ),
        );
        isStartCaptured = true;
      }

      // Moving jeepney marker
      const movingMarkerId = gmf.MarkerId('jeepney_marker');
      _markers.removeWhere((m) => m.markerId == movingMarkerId);
      _markers.add(
        gmf.Marker(
          markerId: movingMarkerId,
          position: newLocation,
          icon: gmf.BitmapDescriptor.defaultMarkerWithHue(
              gmf.BitmapDescriptor.hueAzure),
          infoWindow: const gmf.InfoWindow(title: "Jeepney"),
        ),
      );

      _previousLocation = newLocation;
      _googleMapController?.animateCamera(
        gmf.CameraUpdate.newCameraPosition(
          gmf.CameraPosition(target: newLocation, zoom: 16),
        ),
      );

      setState(() {});
    });
  }

  Future<void> _getRoute() async {
    final stops = [
      gmf.LatLng(14.525358661730701, 121.02747872520852),
      gmf.LatLng(14.544995228139575, 121.04581609472868),
      gmf.LatLng(14.549281023919875, 121.05519585826289),
      gmf.LatLng(14.555759576543378, 121.05840030437734),
      gmf.LatLng(14.564169106132724, 121.04529109452648),
    ];

    final polylines = await _routeService.getRoutePolylines(stops);

    // Flatten polylines into demo points
    _demoRoutePoints.clear();
    for (var polyline in polylines) {
      _demoRoutePoints.addAll(polyline.points);
    }

    for (int i = 0; i < stops.length; i++) {
      final address = await _getAddressFromLatLng(stops[i]);
      _markers.add(
        gmf.Marker(
          markerId: gmf.MarkerId('stop_$i'),
          position: stops[i],
          icon: gmf.BitmapDescriptor.defaultMarker,
          infoWindow: gmf.InfoWindow(title: "Stop ${i + 1}", snippet: address),
        ),
      );
    }

    setState(() {
      _polylines.addAll(polylines);
    });

    // Start tracking after route is ready
    _startLocationTracking();
  }

  void _endTrip() async {
    _positionStream?.cancel();

    final endLatLng = _previousLocation ??
        gmf.LatLng(14.525746, 121.027396); // fallback if no GPS
    final endAddress = await _getAddressFromLatLng(endLatLng);

    _tripInfo.endLocation = endAddress;
    _tripInfo.totalDistance = _totalDistance;

    final fare = FareCalculator.calculate(_totalDistance,
        discountType: widget.discount);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentCompletedPage(
          date: _tripInfo.tripDate,
          startLocation: _tripInfo.startLocation,
          endLocation: _tripInfo.endLocation,
          fare: fare.toStringAsFixed(2),
          paymentMethod: widget.paymentMethod,
          jeepneyNumber: widget.jeepneyNumber,
          driverName: widget.driverName,
          jeepneyID: widget.jeepneyID,
          discount: widget.discount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFare = FareCalculator.calculate(_totalDistance,
            discountType: widget.discount)
        .toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF05D1B6),
        title: Column(
          children: [
            const Text('FareGO',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
            Text('Jeepney #${widget.jeepneyNumber}',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isDemoMode ? Icons.play_arrow : Icons.gps_fixed),
            tooltip:
                _isDemoMode ? "Switch to Real GPS" : "Switch to Demo Mode",
            onPressed: _toggleDemoMode,
          ),
        ],
      ),
      body: Stack(
        children: [
          gmf.GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            initialCameraPosition: _initialCameraPosition,
            polylines: _polylines,
            markers: _markers,
            onMapCreated: (controller) => _googleMapController = controller,
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildInfoBar(currentFare)),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF05D1B6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _endTrip,
                icon: const Icon(Icons.flag),
                label: const Text('End Trip', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBar(String currentFare) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF05D1B6),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _infoColumn('Distance Traveled', '${_totalDistance.toStringAsFixed(2)} km'),
          _infoColumn('Current Fare', '₱$currentFare', alignRight: true),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value, {bool alignRight = false}) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
