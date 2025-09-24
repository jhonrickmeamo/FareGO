import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';


class LiveTracking extends StatefulWidget {
  const LiveTracking({super.key});

  @override
  State<LiveTracking> createState() => _LiveTrackingState();
}

class _LiveTrackingState extends State<LiveTracking> {
<<<<<<< HEAD
  gmf.GoogleMapController? mapController;
  gmf.LatLng? _userLocation;
  Set<gmf.Marker> _markers = {};
  Set<gmf.Polyline> _polylines = {};
  Timer? _locationTimer;

  double _totalDistance = 0.0;
  gmf.LatLng? _previousLocation;

  List<gmf.LatLng> _predefinedRoute = [
    gmf.LatLng(14.525336, 121.027521), // Gate 3 Plaza starting point
    gmf.LatLng(14.54942889777792, 121.05532477953722),  // Market Market
    gmf.LatLng(14.565360197149923, 121.04567400005504), // Guadalupe
    gmf.LatLng(14.547574308157351, 121.0555250147929), // Back to market market
    gmf.LatLng(14.525336, 121.027521), // Gate 3 Plaza ending point
=======
  GoogleMapController? mapController;
  LatLng? _userLocation;
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Timer? _locationTimer;

  // Update the _predefinedRoute with coordinates following actual roads from Gate 3 to Market Market
  final List<LatLng> _predefinedRoute = [
    LatLng(14.525336, 121.027521), // Gate 3 Plaza starting point
    LatLng(14.54942889777792, 121.05532477953722), // Market Market
    LatLng(14.565360197149923, 121.04567400005504), // Guadalupe
    LatLng(14.547574308157351, 121.0555250147929), // Back to market market
    LatLng(14.525336, 121.027521), // Gate 3 Plaza ending point
>>>>>>> d98c60e2ad6d54bd1ddc3b6d63a902fe3c71dc2c
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _createRoute();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateUserLocation();
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
<<<<<<< HEAD
      desiredAccuracy: LocationAccuracy.high
    );
    
    gmf.LatLng newLocation = gmf.LatLng(position.latitude, position.longitude);
    
    if (_previousLocation != null) {
      double distance = Geolocator.distanceBetween(
        _previousLocation!.latitude,
        _previousLocation!.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );
      if (distance > 10) {
        setState(() {
          _totalDistance += distance / 1000;
        });
        _previousLocation = newLocation;
      }
    } else {
      _previousLocation = newLocation;
    }

=======
      desiredAccuracy: LocationAccuracy.high,
    );
>>>>>>> d98c60e2ad6d54bd1ddc3b6d63a902fe3c71dc2c
    setState(() {
      _userLocation = newLocation;
      _markers = {
        gmf.Marker(
          markerId: const gmf.MarkerId('currentLocation'),
          position: _userLocation!,
          infoWindow: const gmf.InfoWindow(title: 'Current Location'),
        ),
      };
    });

    if (mapController != null) {
<<<<<<< HEAD
      mapController!.animateCamera(
        gmf.CameraUpdate.newLatLng(_userLocation!),
      );
=======
      mapController!.animateCamera(CameraUpdate.newLatLng(_userLocation!));
>>>>>>> d98c60e2ad6d54bd1ddc3b6d63a902fe3c71dc2c
    }
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    await _updateUserLocation();
  }

  void _onMapCreated(gmf.GoogleMapController controller) {
    mapController = controller;
    if (_userLocation != null) {
<<<<<<< HEAD
      mapController!.animateCamera(
        gmf.CameraUpdate.newLatLng(_userLocation!),
      );
=======
      mapController!.animateCamera(CameraUpdate.newLatLng(_userLocation!));
>>>>>>> d98c60e2ad6d54bd1ddc3b6d63a902fe3c71dc2c
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 1:
        // Add navigation logic if needed
        break;
    }
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.green[700]),
            Text(
              label,
              style: TextStyle(color: Colors.green[700], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _createRoute() {
    setState(() {
      _polylines.add(
        gmf.Polyline(
          polylineId: const gmf.PolylineId('predefined_route'),
          points: _predefinedRoute,
          color: Colors.blue,
          width: 4,
          startCap: gmf.Cap.roundCap,
          endCap: gmf.Cap.roundCap,
          jointType: gmf.JointType.round,
        ),
      );

      _markers.addAll({
        gmf.Marker(
          markerId: const gmf.MarkerId('startPoint'),
          position: _predefinedRoute.first,
<<<<<<< HEAD
          infoWindow: const gmf.InfoWindow(title: 'Gate 3 Plaza'),
          icon: gmf.BitmapDescriptor.defaultMarkerWithHue(gmf.BitmapDescriptor.hueGreen),
=======
          infoWindow: const InfoWindow(title: 'Gate 3 Plaza'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
>>>>>>> d98c60e2ad6d54bd1ddc3b6d63a902fe3c71dc2c
        ),
        gmf.Marker(
          markerId: const gmf.MarkerId('endPoint'),
          position: _predefinedRoute.last,
          infoWindow: const gmf.InfoWindow(title: 'Market Market'),
          icon: gmf.BitmapDescriptor.defaultMarkerWithHue(gmf.BitmapDescriptor.hueRed),
        ),
      });
    });
  }

  double _calculateFare() {
    double baseFare = 14.0;
    if (_totalDistance <= 4.0) {
      return baseFare;
    }
    double additionalKm = _totalDistance - 4.0;
    return baseFare + additionalKm.ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(
        title: const Text('Live Tracking'),
      ),
      body: Stack(
        children: [
          _userLocation == null
              ? const Center(child: CircularProgressIndicator())
              : gmf.GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: gmf.CameraPosition(
                    target: _userLocation!,
                    zoom: 16.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: _markers,
                  polylines: _polylines,
                ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                            _totalDistance.toStringAsFixed(2),
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 24,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
=======
      appBar: AppBar(title: const Text('Live Tracking')),
      body: _userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _userLocation!,
                zoom: 16.0,
>>>>>>> d98c60e2ad6d54bd1ddc3b6d63a902fe3c71dc2c
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[_buildNavItem(Icons.location_on, "STOP", 1)],
        ),
      ),
    );
  }
}
