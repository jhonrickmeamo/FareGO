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
    zoom: 11.5,
  );

  gmf.GoogleMapController? _googleMapController;
  Set<gmf.Polyline> _polylines = {}; // ✅ Move inside State

  // Location tracking variables
  gmf.LatLng? _currentLocation;
  double _totalDistance = 0.0; // Tracked distance in km
  gmf.LatLng? _previousLocation;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _getRoute(); // 👈 this will draw the predefined route when the screen loads
    _startLocationTracking(); // Start live location updates
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }

  // Start periodic location updates (every 5 seconds)
  void _startLocationTracking() {
    _updateCurrentLocation(); // Initial update
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateCurrentLocation();
    });
  }

  // Update current location and calculate distance
  Future<void> _updateCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      gmf.LatLng newLocation = gmf.LatLng(position.latitude, position.longitude);

      if (_previousLocation != null) {
        double distance = Geolocator.distanceBetween(
          _previousLocation!.latitude,
          _previousLocation!.longitude,
          newLocation.latitude,
          newLocation.longitude,
        );
        if (distance > 10) { // Only add if significant movement (>10m)
          setState(() {
            _totalDistance += distance / 1000; // Convert to km
          });
        }
      }
      _previousLocation = newLocation;

      setState(() {
        _currentLocation = newLocation;
      });

      // Animate camera to current location if map is ready
      if (_googleMapController != null) {
        _googleMapController!.animateCamera(
          gmf.CameraUpdate.newLatLng(_currentLocation!),
        );
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  // Calculate fare based on distance (simple example: base 14 + 1 per extra km after 4km)
  double _calculateFare() {
    double baseFare = 14.0;
    if (_totalDistance <= 4.0) {
      return baseFare;
    }
    double additionalKm = _totalDistance - 4.0;
    return baseFare + additionalKm.ceil();
  }

  Future<void> _getRoute() async {
    final directionsRepo = DirectionsRepository();
    final polylinePoints = await directionsRepo.getRoutePolyline(
      origin: gmf.LatLng(14.5995, 120.9842), // Example: Manila
      destination: gmf.LatLng(14.6760, 121.0437), // Example: Quezon City
    );

    if (polylinePoints != null) {
      setState(() {
        _polylines.add(
          gmf.Polyline(
            polylineId: const gmf.PolylineId('route1'),
            color: Colors.blue,
            width: 5,
            points: polylinePoints,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
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
                  // End trip logic (e.g., stop tracking, show summary)
                  _locationTimer?.cancel();
                },
                icon: const Icon(Icons.stop, color: Colors.white),
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
          // ✅ New: Display bar for distance and fare (at the top, below AppBar)
          Container(
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
                // Left: Distance Traveled
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distance Traveled',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${_totalDistance.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'km',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right: Current Fare
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Current Fare',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₱',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _calculateFare().toStringAsFixed(0),
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Expanded map (takes remaining space)
          Expanded(
            child: gmf.GoogleMap(
              myLocationEnabled: true, // ✅ New: Enable built-in user location (blue GPS dot)
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              initialCameraPosition: _initialCameraPosition,
              polylines: _polylines, // ✅ Show polylines
              onMapCreated: (controller) => _googleMapController = controller,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_currentLocation != null) {
            _googleMapController?.animateCamera(
              gmf.CameraUpdate.newCameraPosition(
                gmf.CameraPosition(
                  target: _currentLocation!,
                  zoom: 14.5,
                ),
              ),
            );
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}