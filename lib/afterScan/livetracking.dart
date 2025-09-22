import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LiveTracking extends StatefulWidget {
  const LiveTracking({super.key});

  @override
  State<LiveTracking> createState() => _LiveTrackingState();
}

class _LiveTrackingState extends State<LiveTracking> {
  GoogleMapController? mapController;
  LatLng? _userLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Timer? _locationTimer;

  // Update the _predefinedRoute with coordinates following actual roads from Gate 3 to Market Market
  List<LatLng> _predefinedRoute = [
    LatLng(14.525336, 121.027521), // Gate 3 Plaza starting point
    LatLng(14.54942889777792, 121.05532477953722),  // Market Market
    LatLng(14.565360197149923, 121.04567400005504), // Guadalupe
    LatLng(14.547574308157351, 121.0555250147929), // Back to market market
    LatLng(14.525336, 121.027521), // Gate 3 Plaza ending point
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _createRoute();
    // Start periodic location updates
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
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
      _markers = {
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _userLocation!,
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      };
    });

    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(_userLocation!),
      );
    }
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    await _updateUserLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_userLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(_userLocation!),
      );
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
            Text(label, style: TextStyle(color: Colors.green[700], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _createRoute() {
    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('predefined_route'),
          points: _predefinedRoute,
          color: Colors.blue,
          width: 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );

      // Add markers for start and end points
      _markers.addAll({
        Marker(
          markerId: const MarkerId('startPoint'),
          position: _predefinedRoute.first,
          infoWindow: const InfoWindow(title: 'Gate 3 Plaza'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('endPoint'),
          position: _predefinedRoute.last,
          infoWindow: const InfoWindow(title: 'Market Market'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
      ),
      body: _userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _userLocation!,
                zoom: 16.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines, // Add this line to show the route
            ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            _buildNavItem(Icons.location_on, "STOP", 1),
          ],
        ),
      ),
    );
  }
}