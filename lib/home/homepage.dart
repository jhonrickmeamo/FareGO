import 'package:farego/home/QRScanner.dart';
import 'package:farego/home/pop_up.dart';
import 'package:farego/home/profile.dart';
import 'package:farego/home/history.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  GoogleMapController? mapController;
  LatLng? _center;
  bool _isLoading = true;

  final Color mainGreen = const Color(0xFF05D1B6); // Updated theme color

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location services are disabled. Please enable GPS."),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied.")),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Permissions are permanently denied. Enable them in settings.",
          ),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      setState(() {
        _center = LatLng(initialPosition.latitude, initialPosition.longitude);
        _isLoading = false;
      });

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_center!, 18.0),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get initial location: $e")),
      );
      setState(() => _isLoading = false);
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      if (position.accuracy > 20) {
        print("Ignored low accuracy update: ${position.accuracy}m");
        return;
      }

      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });

      if (mapController != null && _center != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(_center!));
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_center != null && !_isLoading) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(_center!, 18.0));
    }
  }

  Future<void> _onItemTapped(int index) async {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserProfilePage()),
        );
        break;

      case 1:
        final result = await PaymentPopup.showPaymentDialog(context);
        if (result != null) {
          final paymentMethod = result['paymentMethod'] as String;
          final discount = result['discount'] as String;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QRScanner(paymentMethod: paymentMethod, discount: discount),
            ),
          );
        }
        break;

      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistoryPage()),
        );
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
            Icon(icon, color: Colors.white),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading || _center == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center!,
                zoom: 18.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              compassEnabled: true,
            ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF05D1B6), // Green bottom navigation bar
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _buildNavItem(Icons.person_4_sharp, "Profile", 0),
            const SizedBox(width: 40),
            _buildNavItem(Icons.location_history_sharp, "History", 2),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF05D1B6),
        shape: const CircleBorder(),
        onPressed: () => _onItemTapped(1),
        key: const ValueKey("Scan"),
        child: const Icon(Icons.qr_code_scanner_sharp, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
