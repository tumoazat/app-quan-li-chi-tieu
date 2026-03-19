import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GeoLocationService {
  static final GeoLocationService _instance = GeoLocationService._internal();

  factory GeoLocationService() {
    return _instance;
  }

  GeoLocationService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Pre-request location permissions (call this at app startup)
  Future<void> requestLocationPermissions() async {
    try {
      debugPrint('📍 Pre-requesting location permissions...');
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('📍 Permissions denied, requesting...');
        await Geolocator.requestPermission();
      }
    } catch (e) {
      debugPrint('⚠️ Error requesting permissions: $e');
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      debugPrint('📍 Checking location permission...');
      final permission = await Geolocator.checkPermission();
      debugPrint('📍 Permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('📍 Requesting location permission...');
        final result = await Geolocator.requestPermission();
        debugPrint('📍 Permission request result: $result');
        if (result == LocationPermission.denied) {
          debugPrint('❌ Permission denied, using default location for testing');
          // Return a default location for testing (Ho Chi Minh City, Vietnam)
          return Position(
            latitude: 10.7769,
            longitude: 106.6869,
            timestamp: DateTime.now(),
            accuracy: 50,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Permission denied forever, using default location for testing');
        // Return a default location for testing (Ho Chi Minh City, Vietnam)
        return Position(
          latitude: 10.7769,
          longitude: 106.6869,
          timestamp: DateTime.now(),
          accuracy: 50,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      debugPrint('📍 Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint('✅ Location received: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('⚠️ Error getting location: $e, using default location');
      // Return a default location on error (Ho Chi Minh City, Vietnam)
      return Position(
        latitude: 10.7769,
        longitude: 106.6869,
        timestamp: DateTime.now(),
        accuracy: 50,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  /// Update transaction with location data
  Future<bool> updateTransactionWithLocation({
    required String transactionId,
    required double amount,
    required String category,
    required String description,
    required DateTime date,
  }) async {
    try {
      debugPrint('📌 Starting location update for transaction: $transactionId');
      final position = await getCurrentLocation();
      if (position == null) {
        debugPrint('❌ Location is null, skipping update');
        return false;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('❌ User ID is null');
        return false;
      }

      debugPrint('📌 Updating Firestore with location for user: $userId, tx: $transactionId');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .update({
        'location': GeoPoint(position.latitude, position.longitude),
        'address': await _getAddressFromCoordinates(
            position.latitude, position.longitude),
      });

      debugPrint('✅ Transaction updated with location successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating transaction with location: $e');
      return false;
    }
  }

  /// Save transaction with location (deprecated - use updateTransactionWithLocation)
  @deprecated
  Future<bool> saveTransactionWithLocation({
    required double amount,
    required String category,
    required String description,
    required DateTime date,
  }) async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return false;

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add({
        'amount': amount,
        'category': category,
        'description': description,
        'date': date,
        'location': GeoPoint(position.latitude, position.longitude),
        'address': await _getAddressFromCoordinates(
            position.latitude, position.longitude),
        'createdAt': DateTime.now(),
      });

      return true;
    } catch (e) {
      debugPrint('❌ Error saving transaction: $e');
      return false;
    }
  }

  /// Get address from coordinates
  Future<String> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      // Simple approximation: group by district
      // In production, use a geocoding service API
      return '$latitude, $longitude';
    } catch (e) {
      return 'Unknown Location';
    }
  }

  /// Get spending statistics by location
  Future<Map<String, dynamic>> getLocationAnalytics(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('location', isNotEqualTo: null)
          .get();

      final locationSpending = <String, double>{};
      for (final doc in snapshot.docs) {
        try {
          // Try to get address, fall back to coordinates
          String address = (doc.data().containsKey('address') 
              ? doc['address'] as String? 
              : null) ?? 'Unknown Location';
          
          final amount = (doc['amount'] as num?)?.toDouble() ?? 0;

          if (address == 'Unknown Location') {
            // Try to get from location GeoPoint
            final location = doc['location'];
            if (location is GeoPoint) {
              address = '${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}';
            }
          }

          locationSpending[address] = (locationSpending[address] ?? 0) + amount;
        } catch (e) {
          debugPrint('Error processing transaction: $e');
          continue;
        }
      }

      // Sort by highest spending
      final sortedLocations = locationSpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'topLocations': sortedLocations.take(5).toList(),
        'totalLocations': locationSpending.length,
        'data': locationSpending,
      };
    } catch (e) {
      debugPrint('Error getting location analytics: $e');
      return {};
    }
  }

  /// Get heatmap data for map visualization
  Future<List<Map<String, dynamic>>> getHeatmapData(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('location', isNotEqualTo: null)
          .get();

      return snapshot.docs
          .map((doc) => {
                'latitude': (doc['location'] as GeoPoint).latitude,
                'longitude': (doc['location'] as GeoPoint).longitude,
                'amount': doc['amount'],
                'category': doc['category'],
                'address': doc['address'],
                'date': doc['date'],
              })
          .toList();
    } catch (e) {
      print('Error getting heatmap data: $e');
      return [];
    }
  }
}
