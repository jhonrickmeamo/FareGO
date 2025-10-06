import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;
import 'package:flutter_dotenv/flutter_dotenv.dart';



class DirectionsRepository {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json?';

  final Dio _dio;

  DirectionsRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future<Map<String, dynamic>?> getDirections({
    required gmf.LatLng origin,
    required gmf.LatLng destination,
  }) async {
    final response = await _dio.get(
      _baseUrl,
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'driving',
        'key': dotenv.env['googleAPIKey'],
      },
    );

    if (response.statusCode == 200) {
      print("Google Directions API response: ${response.data}");
      return response.data;
    }
    return null;
  }

  /// ✅ Helper to return a list of LatLng for polylines
  Future<List<gmf.LatLng>?> getRoutePolyline({
    required gmf.LatLng origin,
    required gmf.LatLng destination,
  }) async {
    final data = await getDirections(origin: origin, destination: destination);
    if (data == null) return null;

    final routes = data['routes'] as List;
    if (routes.isEmpty) {
      debugPrint("❌ No routes found. Response: $data");

      return null;
    }

    final points = data['routes'][0]['overview_polyline']['points'];

    // Decode polyline string into LatLngs
    return _decodePolyline(points);
  }

  List<gmf.LatLng> _decodePolyline(String encoded) {
    List<gmf.LatLng> polylineCoordinates = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polylineCoordinates.add(gmf.LatLng(lat / 1E5, lng / 1E5));
    }
    return polylineCoordinates;
  }
}
