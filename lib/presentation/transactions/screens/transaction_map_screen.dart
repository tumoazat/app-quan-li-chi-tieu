import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class TransactionMapScreen extends StatefulWidget {
  const TransactionMapScreen({super.key});

  @override
  State<TransactionMapScreen> createState() => _TransactionMapScreenState();
}

class _TransactionMapScreenState extends State<TransactionMapScreen> {
  final MapController _mapController = MapController();

  static const LatLng _defaultCenter = LatLng(10.7769, 106.7009);
  LatLng _currentCenter = _defaultCenter;
  bool _mapMovedToUser = false;
  bool _loadingPlaces = false;
  String? _locationError;

  List<Map<String, dynamic>> _nearbyPlaces = [];
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _initRealtimeLocation();
  }

  Future<void> _initRealtimeLocation() async {
    await _updateCurrentLocation(moveMap: true);
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _updateCurrentLocation(moveMap: false),
    );
  }

  Future<void> _updateCurrentLocation({required bool moveMap}) async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        if (mounted) {
          setState(() {
            _locationError = 'Vui lòng bật GPS';
          });
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationError = 'Chưa có quyền vị trí';
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final newCenter = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _locationError = null;
        _currentCenter = newCenter;
      });

      if (moveMap || !_mapMovedToUser) {
        _mapController.move(newCenter, 15);
        _mapMovedToUser = true;
      }

      await _fetchNearbySpendingPlaces(newCenter);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationError = 'Không lấy được vị trí hiện tại';
        });
      }
    }
  }

  Future<void> _fetchNearbySpendingPlaces(LatLng center) async {
    if (_loadingPlaces) return;

    setState(() {
      _loadingPlaces = true;
    });

    const radius = 1500;
    final query = '''
[out:json][timeout:15];
(
  node["amenity"~"restaurant|cafe|fast_food|bar|pub|marketplace|supermarket"](around:$radius,${center.latitude},${center.longitude});
);
out body 40;
''';

    try {
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: {'data': query},
      );

      if (response.statusCode != 200) {
        throw Exception('Overpass ${response.statusCode}');
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = (jsonData['elements'] as List? ?? []);

      final places = elements.map<Map<String, dynamic>>((e) {
        final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
        return {
          'lat': (e['lat'] as num).toDouble(),
          'lon': (e['lon'] as num).toDouble(),
          'name': (tags['name'] as String?)?.trim().isNotEmpty == true
              ? tags['name']
              : 'Điểm chi tiêu',
          'type': tags['amenity'] ?? 'place',
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _nearbyPlaces = places;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nearbyPlaces = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingPlaces = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _extractTransactionLocations(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          final point = data['location'];
          if (point is! GeoPoint) return null;
          return {
            'id': doc.id,
            'lat': point.latitude,
            'lon': point.longitude,
            'amount': (data['amount'] as num?)?.toDouble() ?? 0,
            'category': data['category'] ?? 'Khác',
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('🗺️ Transaction Map')),
        body: const Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Transaction Map (Realtime)'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .where('location', isNotEqualTo: null)
            .snapshots(),
        builder: (context, snapshot) {
          final txLocations = snapshot.hasData
              ? _extractTransactionLocations(snapshot.data!)
              : <Map<String, dynamic>>[];

          final markers = <Marker>[
            Marker(
              point: _currentCenter,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 30,
              ),
            ),
            ...txLocations.map(
              (tx) => Marker(
                point: LatLng(tx['lat'] as double, tx['lon'] as double),
                width: 120,
                height: 50,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(blurRadius: 4, color: Colors.black26)
                        ],
                      ),
                      child: Text(
                        '${tx['category']} • ${(tx['amount'] as double).toStringAsFixed(0)}đ',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.location_on, color: Colors.red, size: 30),
                  ],
                ),
              ),
            ),
            ..._nearbyPlaces.map(
              (p) => Marker(
                point: LatLng(p['lat'] as double, p['lon'] as double),
                width: 100,
                height: 36,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront, color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentCenter,
                  initialZoom: 14,
                  minZoom: 3,
                  maxZoom: 19,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.appchitieu',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6)
                    ],
                  ),
                  child: Text(
                    _locationError != null
                        ? '⚠️ $_locationError'
                        : 'GPS realtime • ${txLocations.length} giao dịch • ${_nearbyPlaces.length} quán ăn/cửa hàng gần đây',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (_loadingPlaces)
                const Positioned(
                  bottom: 24,
                  right: 24,
                  child: CircularProgressIndicator(),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _updateCurrentLocation(moveMap: true);
        },
        child: const Icon(Icons.gps_fixed),
      ),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }
}

