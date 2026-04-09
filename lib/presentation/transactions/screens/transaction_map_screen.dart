/*
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
      const radius = 2500;
      final query = '''
      setState(() {
        _nearbyPlaces = [];
    node["amenity"~"restaurant|cafe|fast_food|bar|pub|marketplace|supermarket|food_court|bakery"](around:$radius,${center.latitude},${center.longitude});
    way["amenity"~"restaurant|cafe|fast_food|bar|pub|marketplace|supermarket|food_court|bakery"](around:$radius,${center.latitude},${center.longitude});
    relation["amenity"~"restaurant|cafe|fast_food|bar|pub|marketplace|supermarket|food_court|bakery"](around:$radius,${center.latitude},${center.longitude});

    node["shop"](around:$radius,${center.latitude},${center.longitude});
    way["shop"](around:$radius,${center.latitude},${center.longitude});
    relation["shop"](around:$radius,${center.latitude},${center.longitude});
    } finally {
  out center 120;
        setState(() {
          _loadingPlaces = false;
        });
        final endpoints = <String>[
          'https://overpass-api.de/api/interpreter',
          'https://overpass.kumi.systems/api/interpreter',
        ];

        List elements = const [];
        Object? lastError;

        for (final endpoint in endpoints) {
          try {
            final response = await http
                .post(
                  Uri.parse(endpoint),
                  headers: const {
                    'User-Agent': 'appchitieu/1.0 (nearby places)',
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                  },
                  body: {'data': query},
                )
                .timeout(const Duration(seconds: 18));

            if (response.statusCode != 200) {
              throw Exception('Overpass ${response.statusCode} at $endpoint');
            }

            final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
            elements = (jsonData['elements'] as List?) ?? const [];
            if (elements.isNotEmpty) {
              break;
            }
          } catch (e) {
            lastError = e;
          }
        }

        final places = elements.map<Map<String, dynamic>>((e) {
          final map = (e as Map).cast<String, dynamic>();
          final tags = (map['tags'] as Map?)?.cast<String, dynamic>() ?? {};

          final hasNodeLatLon = map['lat'] != null && map['lon'] != null;
          final centerMap = (map['center'] as Map?)?.cast<String, dynamic>();
          final hasCenterLatLon = centerMap?['lat'] != null && centerMap?['lon'] != null;

          final lat = hasNodeLatLon
              ? (map['lat'] as num).toDouble()
              : (centerMap!['lat'] as num).toDouble();
          final lon = hasNodeLatLon
              ? (map['lon'] as num).toDouble()
              : (centerMap!['lon'] as num).toDouble();

          final amenity = (tags['amenity'] ?? '').toString();
          final shop = (tags['shop'] ?? '').toString();
          final type = amenity.isNotEmpty ? amenity : (shop.isNotEmpty ? 'shop:$shop' : 'place');

          final name = (tags['name'] as String?)?.trim();
          final displayName = (name != null && name.isNotEmpty)
              ? name
              : (shop.isNotEmpty ? 'Cửa hàng' : 'Quán ăn/cửa hàng');

          return {
            'lat': lat,
            'lon': lon,
            'name': displayName,
            'type': type,
          };
        }).where((p) {
          final lat = p['lat'] as double;
          final lon = p['lon'] as double;
          return _isVietnamCoordinate(lat, lon);
        }).toList();
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
          if (places.isEmpty && lastError != null) {
            _locationError = 'Không tải được quán ăn/cửa hàng gần đây.';
          }
        appBar: AppBar(title: const Text('🗺️ Transaction Map')),
        body: const Center(child: Text('Vui lòng đăng nhập')),
      );
    }

          _locationError = 'Không tải được quán ăn/cửa hàng gần đây.';
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

*/

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

class _TransactionMapScreenState extends State<TransactionMapScreen>
    with WidgetsBindingObserver {
  final MapController _mapController = MapController();

  static const LatLng _defaultCenter = LatLng(10.7769, 106.7009);

  // ----- Realtime location state -----
  LatLng _currentCenter = _defaultCenter;
  Position? _currentPosition;
  bool _mapMovedToUser = false;
  bool _followMyLocation = true;

  // ----- Loading & status state -----
  bool _loadingPlaces = false;
  bool _loadingRoute = false;
  String? _locationError;
  String _currentAddress = 'Đang xác định vị trí...';

  // ----- Nearby places + search state -----
  List<Map<String, dynamic>> _nearbyPlaces = [];
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastNearbyFetchAt;
  LatLng? _lastNearbyFetchCenter;
  final TextEditingController _storeSearchController = TextEditingController();
  final FocusNode _storeSearchFocusNode = FocusNode();
  String _storeSearchQuery = '';
  bool _isSearchingStore = false;
  List<Map<String, dynamic>> _searchResults = [];

  // ----- Routing state -----
  LatLng? _selectedDestination;
  String? _selectedDestinationLabel;
  List<LatLng> _routePoints = [];
  double? _routeDistanceKm;
  int? _routeDurationMin;
  bool _autoRerouteEnabled = true;
  DateTime? _lastRouteRecalcAt;
  LatLng? _lastRouteRecalcFrom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initRealtimeLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateCurrentLocation(moveMap: true);
    }
  }

  Future<void> _initRealtimeLocation() async {
    // Lấy vị trí ban đầu và di chuyển map tới user.
    await _updateCurrentLocation(moveMap: true);

    // Mở stream vị trí để cập nhật realtime khi user di chuyển.
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _updateCurrentLocation(moveMap: _followMyLocation, incoming: position);
    });
  }

  Future<void> _updateCurrentLocation({
    required bool moveMap,
    Position? incoming,
  }) async {
    try {
      // Kiểm tra GPS + quyền trước khi đọc vị trí.
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

      final position = incoming ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
      final newCenter = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _locationError = null;
        _currentCenter = newCenter;
        _currentPosition = position;
      });

      if (moveMap || !_mapMovedToUser) {
        _mapController.move(newCenter, 15);
        _mapMovedToUser = true;
      }

      // Cập nhật địa chỉ hiện tại + POI lân cận + route realtime.
      await _updateCurrentAddress(newCenter);
      await _fetchNearbySpendingPlaces(newCenter);
      await _maybeRealtimeReroute(newCenter);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationError = 'Không lấy được vị trí hiện tại';
        });
      }
    }
  }

  Future<void> _updateCurrentAddress(LatLng center) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${center.latitude}&lon=${center.longitude}&zoom=17&accept-language=vi',
      );

      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'appchitieu/1.0 (location feature)',
        },
      );

      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final displayName = (data['display_name'] as String?)?.trim();
      if (!mounted || displayName == null || displayName.isEmpty) return;

      setState(() {
        _currentAddress = displayName;
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _fetchNearbySpendingPlaces(LatLng center) async {
    if (_loadingPlaces) return;

    // Chống gọi API quá dày: chỉ fetch lại khi đủ thời gian hoặc user di chuyển đủ xa.
    final now = DateTime.now();
    if (_lastNearbyFetchAt != null && _lastNearbyFetchCenter != null) {
      final seconds = now.difference(_lastNearbyFetchAt!).inSeconds;
      final movedMeters = const Distance().as(
        LengthUnit.Meter,
        _lastNearbyFetchCenter!,
        center,
      );
      if (seconds < 10 && movedMeters < 60) return;
    }

    setState(() {
      _loadingPlaces = true;
    });

    const radius = 2500;
    // Query quán ăn/cafe/shop theo bán kính quanh user hiện tại.
    final query = '''
[out:json][timeout:18];
(
  node["amenity"~"restaurant|cafe|fast_food|bar|pub|marketplace|supermarket|food_court|bakery"](around:$radius,${center.latitude},${center.longitude});
  way["amenity"~"restaurant|cafe|fast_food|bar|pub|marketplace|supermarket|food_court|bakery"](around:$radius,${center.latitude},${center.longitude});
  relation["amenity"~"restaurant|cafe|fast_food|bar|pub|marketplace|supermarket|food_court|bakery"](around:$radius,${center.latitude},${center.longitude});

  node["shop"](around:$radius,${center.latitude},${center.longitude});
  way["shop"](around:$radius,${center.latitude},${center.longitude});
  relation["shop"](around:$radius,${center.latitude},${center.longitude});
);
out center 120;
''';

    try {
      // Dùng 2 endpoint để tăng độ ổn định (fallback khi endpoint chính lỗi/quá tải).
      final endpoints = <String>[
        'https://overpass-api.de/api/interpreter',
        'https://overpass.kumi.systems/api/interpreter',
      ];

      List elements = const [];
      Object? lastError;

      for (final endpoint in endpoints) {
        try {
          final response = await http
              .post(
                Uri.parse(endpoint),
                headers: const {
                  'User-Agent': 'appchitieu/1.0 (nearby places)',
                  'Content-Type':
                      'application/x-www-form-urlencoded; charset=UTF-8',
                },
                body: {'data': query},
              )
              .timeout(const Duration(seconds: 20));

          if (response.statusCode != 200) {
            throw Exception('Overpass ${response.statusCode} at $endpoint');
          }

          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          elements = (jsonData['elements'] as List?) ?? const [];
          if (elements.isNotEmpty) break;
        } catch (e) {
          lastError = e;
        }
      }

      final places = elements.map<Map<String, dynamic>>((e) {
        final map = (e as Map).cast<String, dynamic>();
        final tags = (map['tags'] as Map?)?.cast<String, dynamic>() ?? {};

        final hasNodeLatLon = map['lat'] != null && map['lon'] != null;
        final centerMap = (map['center'] as Map?)?.cast<String, dynamic>();
        final hasCenterLatLon =
            centerMap?['lat'] != null && centerMap?['lon'] != null;

        if (!hasNodeLatLon && !hasCenterLatLon) {
          return {
            'lat': _currentCenter.latitude,
            'lon': _currentCenter.longitude,
            'name': 'Điểm chi tiêu',
            'type': 'place',
          };
        }

        final lat = hasNodeLatLon
            ? (map['lat'] as num).toDouble()
            : (centerMap!['lat'] as num).toDouble();
        final lon = hasNodeLatLon
            ? (map['lon'] as num).toDouble()
            : (centerMap!['lon'] as num).toDouble();

        final amenity = (tags['amenity'] ?? '').toString();
        final shop = (tags['shop'] ?? '').toString();
        final type = amenity.isNotEmpty
            ? amenity
            : (shop.isNotEmpty ? 'shop:$shop' : 'place');

        final name = (tags['name'] as String?)?.trim();
        final displayName = (name != null && name.isNotEmpty)
            ? name
            : (shop.isNotEmpty ? 'Cửa hàng' : 'Quán ăn/cửa hàng');

        return {
          'lat': lat,
          'lon': lon,
          'name': displayName,
          'type': type,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _nearbyPlaces = places;
        _lastNearbyFetchAt = now;
        _lastNearbyFetchCenter = center;
        if (places.isEmpty && lastError != null) {
          _locationError = 'Không tải được quán ăn/cửa hàng gần đây.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nearbyPlaces = [];
        _locationError = 'Không tải được quán ăn/cửa hàng gần đây.';
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

  Future<void> _buildRouteToDestination({
    required LatLng destination,
    required String label,
  }) async {
    // Reset route cũ và bật trạng thái loading route.
    setState(() {
      _selectedDestination = destination;
      _selectedDestinationLabel = label;
      _loadingRoute = true;
      _routePoints = [];
      _routeDistanceKm = null;
      _routeDurationMin = null;
    });

    try {
      // Dùng OSRM public API để tính route lái xe.
      final from = _currentCenter;
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(uri, headers: const {
        'User-Agent': 'appchitieu/1.0 (routing feature)',
      });

      if (response.statusCode != 200) {
        throw Exception('OSRM ${response.statusCode}');
      }

      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = (map['routes'] as List?) ?? const [];
      if (routes.isEmpty) {
        throw Exception('No route');
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = (geometry['coordinates'] as List?) ?? const [];

      final points = coordinates
          .whereType<List>()
          .where((c) => c.length >= 2)
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      if (!mounted) return;
      setState(() {
        _routePoints = points;
        _routeDistanceKm =
            ((route['distance'] as num?)?.toDouble() ?? 0) / 1000;
        _routeDurationMin =
            (((route['duration'] as num?)?.toDouble() ?? 0) / 60).round();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Không tìm được tuyến đường. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingRoute = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _filteredNearbyPlacesByQuery() {
    // Lọc nhanh trên dữ liệu nearby hiện có.
    final query = _storeSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return _nearbyPlaces;

    return _nearbyPlaces.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final type = (p['type'] ?? '').toString().toLowerCase();
      return name.contains(query) || type.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> _visiblePlaces() {
    // Merge kết quả local + remote, đồng thời loại duplicate.
    final base = _filteredNearbyPlacesByQuery();
    if (_searchResults.isEmpty) return base;

    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];

    for (final p in [..._searchResults, ...base]) {
      final key =
          '${(p['lat'] as num).toDouble().toStringAsFixed(6)}:${(p['lon'] as num).toDouble().toStringAsFixed(6)}:${p['name']}';
      if (seen.add(key)) {
        merged.add(p);
      }
    }

    return merged;
  }

  Future<void> _searchStoresRemotely() async {
    // Search theo tên cửa hàng/quán ăn trên Overpass trong bán kính lớn hơn nearby.
    final query = _storeSearchQuery.trim();
    if (query.isEmpty || _isSearchingStore) return;

    setState(() {
      _isSearchingStore = true;
      _searchResults = [];
    });

    final safeQuery = query.replaceAll('"', ' ').replaceAll('\\', ' ').trim();
    if (safeQuery.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isSearchingStore = false;
      });
      return;
    }

    const radius = 10000;
    final overpassQuery = '''
[out:json][timeout:18];
(
  node["name"~"(?i).*${safeQuery}.*"]["amenity"~"restaurant|cafe|fast_food|bar|pub|marketplace|supermarket|food_court|bakery"](around:$radius,${_currentCenter.latitude},${_currentCenter.longitude});
  way["name"~"(?i).*${safeQuery}.*"]["amenity"~"restaurant|cafe|fast_food|bar|pub|marketplace|supermarket|food_court|bakery"](around:$radius,${_currentCenter.latitude},${_currentCenter.longitude});
  relation["name"~"(?i).*${safeQuery}.*"]["amenity"~"restaurant|cafe|fast_food|bar|pub|marketplace|supermarket|food_court|bakery"](around:$radius,${_currentCenter.latitude},${_currentCenter.longitude});

  node["name"~"(?i).*${safeQuery}.*"]["shop"](around:$radius,${_currentCenter.latitude},${_currentCenter.longitude});
  way["name"~"(?i).*${safeQuery}.*"]["shop"](around:$radius,${_currentCenter.latitude},${_currentCenter.longitude});
  relation["name"~"(?i).*${safeQuery}.*"]["shop"](around:$radius,${_currentCenter.latitude},${_currentCenter.longitude});
);
out center 80;
''';

    try {
      final endpoints = <String>[
        'https://overpass-api.de/api/interpreter',
        'https://overpass.kumi.systems/api/interpreter',
      ];

      List elements = const [];
      for (final endpoint in endpoints) {
        try {
          final response = await http
              .post(
                Uri.parse(endpoint),
                headers: const {
                  'User-Agent': 'appchitieu/1.0 (store search)',
                  'Content-Type':
                      'application/x-www-form-urlencoded; charset=UTF-8',
                },
                body: {'data': overpassQuery},
              )
              .timeout(const Duration(seconds: 20));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            elements = (data['elements'] as List?) ?? const [];
            if (elements.isNotEmpty) break;
          }
        } catch (_) {
          // try next endpoint
        }
      }

      final places = elements.map<Map<String, dynamic>>((e) {
        final map = (e as Map).cast<String, dynamic>();
        final tags = (map['tags'] as Map?)?.cast<String, dynamic>() ?? {};

        final hasNodeLatLon = map['lat'] != null && map['lon'] != null;
        final centerMap = (map['center'] as Map?)?.cast<String, dynamic>();
        final hasCenterLatLon =
            centerMap?['lat'] != null && centerMap?['lon'] != null;

        if (!hasNodeLatLon && !hasCenterLatLon) {
          return {
            'lat': _currentCenter.latitude,
            'lon': _currentCenter.longitude,
            'name': 'Điểm chi tiêu',
            'type': 'place',
          };
        }

        final lat = hasNodeLatLon
            ? (map['lat'] as num).toDouble()
            : (centerMap!['lat'] as num).toDouble();
        final lon = hasNodeLatLon
            ? (map['lon'] as num).toDouble()
            : (centerMap!['lon'] as num).toDouble();

        final amenity = (tags['amenity'] ?? '').toString();
        final shop = (tags['shop'] ?? '').toString();

        return {
          'lat': lat,
          'lon': lon,
          'name': ((tags['name'] as String?)?.trim().isNotEmpty ?? false)
              ? tags['name']
              : (shop.isNotEmpty ? 'Cửa hàng' : 'Quán ăn/cửa hàng'),
          'type': amenity.isNotEmpty
              ? amenity
              : (shop.isNotEmpty ? 'shop:$shop' : 'place'),
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _searchResults = places;
        if (places.isEmpty) {
          _locationError = 'Không tìm thấy cửa hàng phù hợp.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Tìm kiếm cửa hàng thất bại. Vui lòng thử lại.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSearchingStore = false;
      });
    }
  }

  Future<void> _maybeRealtimeReroute(LatLng currentPosition) async {
    // Chỉ reroute khi đã có điểm đến, đang bật auto reroute, và thỏa điều kiện throttle.
    if (!_autoRerouteEnabled || _selectedDestination == null || _loadingRoute) {
      return;
    }

    final now = DateTime.now();
    if (_lastRouteRecalcAt != null && _lastRouteRecalcFrom != null) {
      final seconds = now.difference(_lastRouteRecalcAt!).inSeconds;
      final movedMeters = const Distance().as(
        LengthUnit.Meter,
        _lastRouteRecalcFrom!,
        currentPosition,
      );
      if (seconds < 6 && movedMeters < 20) return;
    }

    _lastRouteRecalcAt = now;
    _lastRouteRecalcFrom = currentPosition;

    await _buildRouteToDestination(
      destination: _selectedDestination!,
      label: _selectedDestinationLabel ?? 'Điểm đến',
    );
  }

  void _clearRoute() {
    // Xóa toàn bộ trạng thái route để quay về chế độ xem bản đồ bình thường.
    setState(() {
      _selectedDestination = null;
      _selectedDestinationLabel = null;
      _routePoints = [];
      _routeDistanceKm = null;
      _routeDurationMin = null;
      _lastRouteRecalcAt = null;
      _lastRouteRecalcFrom = null;
    });
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
          final visiblePlaces = _visiblePlaces();

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
                child: GestureDetector(
                  onTap: () => _buildRouteToDestination(
                    destination: LatLng(tx['lat'] as double, tx['lon'] as double),
                    label:
                        '${tx['category']} • ${(tx['amount'] as double).toStringAsFixed(0)}đ',
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            ),
            ...visiblePlaces.map(
              (p) => Marker(
                point: LatLng(p['lat'] as double, p['lon'] as double),
                width: 120,
                height: 36,
                child: GestureDetector(
                  onTap: () => _buildRouteToDestination(
                    destination: LatLng(p['lat'] as double, p['lon'] as double),
                    label: p['name'] as String,
                  ),
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
                  onLongPress: (_, point) {
                    _buildRouteToDestination(
                      destination: point,
                      label: 'Điểm đã chọn',
                    );
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.appchitieu',
                  ),
                  if (_currentPosition != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _currentCenter,
                          radius: (_currentPosition!.accuracy < 5
                                  ? 5
                                  : _currentPosition!.accuracy)
                              .toDouble(),
                          useRadiusInMeter: true,
                          color: Colors.blue.withOpacity(0.15),
                          borderColor: Colors.blue.withOpacity(0.6),
                          borderStrokeWidth: 1,
                        ),
                      ],
                    ),
                  if (_routePoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 5,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6)
                        ],
                      ),
                      child: TextField(
                        controller: _storeSearchController,
                        focusNode: _storeSearchFocusNode,
                        textInputAction: TextInputAction.search,
                        onChanged: (value) {
                          setState(() {
                            _storeSearchQuery = value;
                            _searchResults = [];
                          });
                        },
                        onSubmitted: (_) => _searchStoresRemotely(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Tìm quán ăn / cửa hàng...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _isSearchingStore
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : IconButton(
                                  onPressed: _storeSearchQuery.trim().isEmpty
                                      ? null
                                      : _searchStoresRemotely,
                                  icon: const Icon(Icons.travel_explore),
                                  tooltip: 'Tìm kiếm cửa hàng',
                                ),
                        ),
                      ),
                    ),
                    if (_storeSearchQuery.trim().isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6)
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: visiblePlaces.length > 8 ? 8 : visiblePlaces.length,
                          itemBuilder: (context, index) {
                            final p = visiblePlaces[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.storefront,
                                color: Colors.orange,
                                size: 18,
                              ),
                              title: Text(
                                (p['name'] ?? 'Cửa hàng').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                (p['type'] ?? 'place').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                final point =
                                    LatLng(p['lat'] as double, p['lon'] as double);
                                _mapController.move(point, 16);
                                _buildRouteToDestination(
                                  destination: point,
                                  label: (p['name'] ?? 'Điểm đến').toString(),
                                );
                                _storeSearchFocusNode.unfocus();
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: _storeSearchQuery.trim().isEmpty ? 72 : 260,
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
                        : 'GPS realtime • ${txLocations.length} giao dịch • ${_nearbyPlaces.length} quán ăn/cửa hàng gần đây\n${_currentAddress.length > 80 ? '${_currentAddress.substring(0, 80)}...' : _currentAddress}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (_loadingPlaces)
                const Positioned(
                  bottom: 24,
                  right: 24,
                  child: CircularProgressIndicator(),
                ),
              if (_loadingRoute)
                const Positioned(
                  bottom: 90,
                  right: 24,
                  child: CircularProgressIndicator(),
                ),
              if (_selectedDestination != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedDestinationLabel ?? 'Điểm đến',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _routeDistanceKm != null && _routeDurationMin != null
                              ? 'Quãng đường: ${_routeDistanceKm!.toStringAsFixed(2)} km • Ước tính: $_routeDurationMin phút'
                              : 'Đang tính đường...',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _autoRerouteEnabled
                              ? 'Cập nhật lộ trình realtime: BẬT'
                              : 'Cập nhật lộ trình realtime: TẮT',
                          style: TextStyle(
                            fontSize: 11,
                            color: _autoRerouteEnabled
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _clearRoute,
                                icon: const Icon(Icons.close),
                                label: const Text('Xóa tuyến'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _autoRerouteEnabled = !_autoRerouteEnabled;
                                  });
                                },
                                icon: Icon(
                                  _autoRerouteEnabled
                                      ? Icons.route
                                      : Icons.route_outlined,
                                ),
                                label: Text(
                                  _autoRerouteEnabled
                                      ? 'Realtime ON'
                                      : 'Realtime OFF',
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'follow_toggle',
            mini: true,
            backgroundColor: _followMyLocation ? Colors.green : null,
            onPressed: () {
              setState(() {
                _followMyLocation = !_followMyLocation;
              });
            },
            child: Icon(
              _followMyLocation ? Icons.my_location : Icons.location_searching,
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'gps_refresh',
            onPressed: () async {
              await _updateCurrentLocation(moveMap: true);
            },
            child: const Icon(Icons.gps_fixed),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Cleanup tài nguyên liên quan stream/input.
    _positionSubscription?.cancel();
    _storeSearchController.dispose();
    _storeSearchFocusNode.dispose();
    super.dispose();
  }
}

