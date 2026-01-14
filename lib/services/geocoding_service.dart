import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class GeocodingService {
  /// Geocode an address to get latitude and longitude
  /// Returns null if geocoding fails
  static Future<({double latitude, double longitude})?> geocodeAddress(
    String address,
  ) async {
    try {
      // Build full address with city and state for better accuracy
      final fullAddress = address.contains('Belo Horizonte')
          ? address
          : '$address, Belo Horizonte, MG, Brasil';

      // Geocode the address
      final locations = await locationFromAddress(fullAddress);

      if (locations.isNotEmpty) {
        final location = locations.first;
        return (latitude: location.latitude, longitude: location.longitude);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Geocoding error for "$address": $e');
      }
      // Try with just the address if full address fails
      try {
        final locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          final location = locations.first;
          return (latitude: location.latitude, longitude: location.longitude);
        }
      } catch (e2) {
        if (kDebugMode) {
          print('Geocoding retry error: $e2');
        }
      }
    }
    return null;
  }

  /// Geocode multiple addresses with rate limiting
  /// Returns a map of address -> (latitude, longitude)
  static Future<Map<String, ({double latitude, double longitude})>>
  geocodeAddresses(
    List<String> addresses, {
    int delayMs = 200, // Delay between requests to avoid rate limiting
  }) async {
    final Map<String, ({double latitude, double longitude})> results = {};

    for (final address in addresses) {
      final result = await geocodeAddress(address);
      if (result != null) {
        results[address] = result;
      }

      // Add delay to avoid rate limiting
      if (delayMs > 0) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    return results;
  }
}
