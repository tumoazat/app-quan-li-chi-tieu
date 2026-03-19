import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/geo_location_service.dart';
import '../../../providers/auth_provider.dart';

class GeoLocationAnalyticsScreen extends ConsumerStatefulWidget {
  const GeoLocationAnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GeoLocationAnalyticsScreen> createState() =>
      _GeoLocationAnalyticsScreenState();
}

class _GeoLocationAnalyticsScreenState
    extends ConsumerState<GeoLocationAnalyticsScreen> {
  late GeoLocationService _geoLocationService;
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _geoLocationService = GeoLocationService();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final analytics = await _geoLocationService.getLocationAnalytics(user.uid);
    setState(() {
      _analytics = analytics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Location Analytics')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final topLocations = _analytics['topLocations'] as List? ?? [];
    final totalLocations = _analytics['totalLocations'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Where You Spend Most'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Locations Visited',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalLocations',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Top Locations
          Text(
            'Top Spending Locations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (topLocations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No location data yet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topLocations.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final location =
                    topLocations[index] as MapEntry<String, double>;
                final rank = index + 1;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('$rank'),
                  ),
                  title: Text(location.key),
                  trailing: Text(
                    '${location.value.toStringAsFixed(0)}đ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
