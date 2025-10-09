import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;
import 'package:farego/directions_repository.dart';
import 'package:flutter/material.dart';

class RouteService {
  final DirectionsRepository _directionsRepo = DirectionsRepository();

  /// Returns start and end locations (for display)
  Map<String, String> getRouteLocations(List<gmf.LatLng> stops) {
    if (stops.isEmpty) return {'start': 'Unknown', 'end': 'Unknown'};

    final start = "Start: ${stops.first.latitude.toStringAsFixed(5)}, ${stops.first.longitude.toStringAsFixed(5)}";
    final end = "End: ${stops.last.latitude.toStringAsFixed(5)}, ${stops.last.longitude.toStringAsFixed(5)}";

    return {'start': start, 'end': end};
  }

  /// Fetch polylines between route stops
  Future<List<gmf.Polyline>> getRoutePolylines(List<gmf.LatLng> stops) async {
    final List<gmf.Polyline> polylines = [];

    for (int i = 0; i < stops.length - 1; i++) {
      final polylinePoints = await _directionsRepo.getRoutePolyline(
        origin: stops[i],
        destination: stops[i + 1],
      );

      if (polylinePoints != null && polylinePoints.isNotEmpty) {
        polylines.add(
          gmf.Polyline(
            polylineId: gmf.PolylineId('segment$i'),
            color: _segmentColor(i),
            width: 5,
            points: polylinePoints,
          ),
        );
      }
    }

    return polylines;
  }

  /// Only start & end markers
  Set<gmf.Marker> getRouteMarkers(List<gmf.LatLng> stops) {
    final markers = <gmf.Marker>{};

    if (stops.isEmpty) return markers;

    markers.add(
      gmf.Marker(
        markerId: const gmf.MarkerId('start'),
        position: stops.first,
        icon: gmf.BitmapDescriptor.defaultMarkerWithHue(gmf.BitmapDescriptor.hueRed),
      ),
    );

    markers.add(
      gmf.Marker(
        markerId: const gmf.MarkerId('end'),
        position: stops.last,
        icon: gmf.BitmapDescriptor.defaultMarkerWithHue(gmf.BitmapDescriptor.hueGreen),
      ),
    );

    return markers;
  }

  /// Cycle colors for polylines
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
}

 