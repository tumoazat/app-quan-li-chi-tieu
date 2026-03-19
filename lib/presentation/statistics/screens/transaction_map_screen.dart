import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/geo_location_service.dart';
import '../../../providers/auth_provider.dart';

class TransactionMapScreen extends ConsumerStatefulWidget {
  const TransactionMapScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TransactionMapScreen> createState() =>
      _TransactionMapScreenState();
}

class _TransactionMapScreenState extends ConsumerState<TransactionMapScreen> {
  late GeoLocationService _geoLocationService;
  late MapController _mapController;
  List<Marker> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _geoLocationService = GeoLocationService();
    _mapController = MapController();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final heatmapData = await _geoLocationService.getHeatmapData(user.uid);
    
    final markers = <Marker>[];
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;

    for (final data in heatmapData) {
      final lat = data['latitude'] as double;
      final lng = data['longitude'] as double;
      final amount = data['amount'] as num;
      final category = data['category'] as String;

      // Update bounds
      minLat = minLat > lat ? lat : minLat;
      maxLat = maxLat < lat ? lat : maxLat;
      minLng = minLng > lng ? lng : minLng;
      maxLng = maxLng < lng ? lng : maxLng;

      // Size marker based on amount
      final size = (amount as num).toDouble() / 1000;
      final clampedSize = (size > 50 ? 50 : size < 20 ? 20 : size).toDouble();

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: clampedSize,
          height: clampedSize,
          child: GestureDetector(
            onTap: () => _showLocationDetails(data),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getCategoryColor(category).withOpacity(0.7),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _getCategoryColor(category),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${(amount / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Calculate initial camera position
    LatLng initialCenter = const LatLng(21.0285, 105.8542); // Hanoi default
    double zoom = 12;

    if (markers.isNotEmpty) {
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      initialCenter = LatLng(centerLat, centerLng);

      // Calculate zoom to fit all markers
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      zoom = _calculateZoom(latDiff, lngDiff);
    }

    setState(() {
      _markers = markers;
      _isLoading = false;
    });

    // Animate to position
    _mapController.move(initialCenter, zoom);
  }

  double _calculateZoom(double latDiff, double lngDiff) {
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    if (maxDiff < 0.01) return 15;
    if (maxDiff < 0.1) return 13;
    if (maxDiff < 1) return 11;
    if (maxDiff < 5) return 9;
    return 7;
  }

  Color _getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('ăn') || lower.contains('food')) return Colors.orange;
    if (lower.contains('transport') || lower.contains('xe')) return Colors.blue;
    if (lower.contains('shopping') || lower.contains('mua')) return Colors.pink;
    if (lower.contains('entertainment')) return Colors.purple;
    if (lower.contains('bills') || lower.contains('hóa')) return Colors.red;
    if (lower.contains('health')) return Colors.green;
    return Colors.grey;
  }

  void _showLocationDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Category', data['category'] ?? 'Unknown'),
            _buildDetailRow('Amount', '${data['amount']}đ'),
            _buildDetailRow(
              'Location',
              '${(data['latitude'] as double).toStringAsFixed(4)}, ${(data['longitude'] as double).toStringAsFixed(4)}',
            ),
            if (data['address'] != null)
              _buildDetailRow('Address', data['address']),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Map')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Transaction Map'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _markers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions with location yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(21.0285, 105.8542), // Hanoi
                    initialZoom: 12,
                    minZoom: 3,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.appchitieu',
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        mini: true,
                        onPressed: () => _mapController.move(
                          const LatLng(21.0285, 105.8542),
                          12,
                        ),
                        tooltip: 'Reset to Hanoi',
                        child: const Icon(Icons.home),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        mini: true,
                        onPressed: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        ),
                        tooltip: 'Zoom in',
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        mini: true,
                        onPressed: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        ),
                        tooltip: 'Zoom out',
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
