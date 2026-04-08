import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/geo_location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class LocationMapScreen extends StatefulWidget {
  final String title;
  final LatLng? initialLocation;

  const LocationMapScreen({
    super.key,
    this.title = 'Vị trí của tôi',
    this.initialLocation,
  });

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  late GoogleMapController _mapController;
  LatLng? _currentLocation;
  bool _isLoading = true;
  String? _errorMessage;
  final _geoLocationService = GeoLocationService();

  // Default: Ha Noi
  static const LatLng _defaultVietnamLocation = LatLng(21.0285, 105.8542);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Yêu cầu quyền trước
      await _geoLocationService.requestLocationPermissions();

      // Lấy vị trí hiện tại
      final position = await _geoLocationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        // Zoom camera tới vị trí hiện tại
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 16.0),
        );
      } else {
        // Fallback: mặc định Sài Gòn
        setState(() {
          _currentLocation = _defaultVietnamLocation;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: $e';
        _currentLocation = _defaultVietnamLocation;
        _isLoading = false;
      });
    }
  }

  void _centerCurrentLocation() async {
    _mapController.animateCamera(
      CameraUpdate.newLatLng(_defaultVietnamLocation),
    );
    _mapController.animateCamera(
      CameraUpdate.zoomTo(16.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTypography.headlineMedium(context),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              // Luôn focus vào Hà Nội ngay lập tức
              Future.delayed(const Duration(milliseconds: 500), () {
                _mapController.animateCamera(
                  CameraUpdate.newLatLng(_defaultVietnamLocation),
                );
                _mapController.animateCamera(
                  CameraUpdate.zoomTo(16.0),
                );
              });
            },
            initialCameraPosition: CameraPosition(
              target: _defaultVietnamLocation, // Luôn Hà Nội
              zoom: 16.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            markers: _currentLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('current_location'),
                      position: _currentLocation!,
                      infoWindow: const InfoWindow(title: '📍 Vị trí của tôi'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                    ),
                  }
                : {},
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đang xác định vị trí...',
                      style: AppTypography.bodyMedium(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error message
          if (_errorMessage != null && !_isLoading)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.bodySmall(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Center button
          Positioned(
            bottom: 32,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _centerCurrentLocation,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Location info card
          if (_currentLocation != null && !_isLoading)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vị trí hiện tại',
                            style: AppTypography.bodyMedium(context).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tọa độ: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}',
                      style: AppTypography.bodySmall(context),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, _currentLocation),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Chọn vị trí này'),
                      ),
                    ),
                  ],
                ),
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
