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

  /// Start live location updates using Geolocator stream
  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update only if moved >10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final newLocation = gmf.LatLng(position.latitude, position.longitude);

      if (_previousLocation != null) {
        final distance = Geolocator.distanceBetween(
          _previousLocation!.latitude,
          _previousLocation!.longitude,
          newLocation.latitude,
          newLocation.longitude,
        );
        if (distance > 10) {
          setState(() => _totalDistance += distance / 1000);
        }
      }
      _previousLocation = newLocation;

      // Smooth camera follow
      _googleMapController?.animateCamera(
        gmf.CameraUpdate.newLatLng(newLocation),
      );
    });
  }

  
  double _calculateFare() {
    const baseFare = 11.0;
    if (_totalDistance <= 4.0) return baseFare;
    return baseFare + (_totalDistance - 4.0).ceil();
  }

  /// Get route polylines
  Future<void> _getRoute() async {
    final directionsRepo = DirectionsRepository();

    const stops = [
      gmf.LatLng(14.525358661730701, 121.02747872520852),
      gmf.LatLng(14.549410474098346, 121.05522594853191),
      gmf.LatLng(14.55276679479669, 121.05723779785644),
      gmf.LatLng(14.555759576543378, 121.05840030437734),
      gmf.LatLng(14.558254711584864, 121.05785975110224),
      gmf.LatLng(14.558636336509108, 121.05553695811646), //38th street dexterton corporation BGC
      gmf.LatLng(14.562038463249534, 121.05410781758737),
      gmf.LatLng(14.562418448516608, 121.05361517175132),
    ];

    if (stops.length < 2) return;

    final List<gmf.Polyline> newPolylines = [];

    for (int i = 0; i < stops.length - 1; i++) {
      final polylinePoints = await directionsRepo.getRoutePolyline(
        origin: stops[i],
        destination: stops[i + 1],
      );

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
      Colors.purple
    ];
    return colors[index % colors.length];
  }

  /// Add stop markers
  void _addLineMarkers(List<gmf.LatLng> stops) {
    final markers = <gmf.Marker>{};
    for (int i = 0; i < stops.length; i++) {
      markers.add(
        gmf.Marker(
          markerId: gmf.MarkerId('stop$i'),
          position: stops[i],
          infoWindow: gmf.InfoWindow(
            title: 'Stop $i',
            snippet: 'Part of the route',
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
                onPressed: () => _positionStream?.cancel(),
                icon: const Icon(Icons.stop, color: Colors.white),
                label: const Text('End Trip', style: TextStyle(color: Colors.white)),
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
              myLocationEnabled: true,
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
          _infoColumn('Distance Traveled',
              '${_totalDistance.toStringAsFixed(2)} km'),
          _infoColumn('Current Fare', '₱${_calculateFare().toStringAsFixed(0)}',
              alignRight: true),
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
