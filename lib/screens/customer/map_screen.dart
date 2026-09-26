import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/user_model.dart';
import '../../providers/service_provider.dart';
import '../../services/location_service.dart';
import '../../utils/app_colors.dart';
import 'provider_details_screen.dart';

/// Professional Map Screen for Location-based Provider Search
/// Shows nearby providers on an interactive map with distance calculation
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  
  LatLng? _currentLocation;
  double _searchRadius = 5.0; // Default 5km radius
  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> _nearbyProviders = [];

  @override
  void initState() {
    super.initState();
    _initializeLocationAndLoadProviders();
  }

  /// Initialize location services and load nearby providers
  Future<void> _initializeLocationAndLoadProviders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request location permission
      final permissionGranted = await _locationService.requestLocationPermission();
      if (!permissionGranted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permission is required to show nearby providers';
        });
        return;
      }

      // Get current location
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to get your current location';
        });
        return;
      }

      setState(() {
        _currentLocation = location;
      });

      // Move map to current location if controller is ready
      try {
        _mapController.move(location, 15.0);
      } catch (_) {}

      // Load providers and filter by distance
      await _loadNearbyProviders(location);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error initializing location: ${e.toString()}';
      });
    }
  }

  /// Load providers and filter by distance from current location
  Future<void> _loadNearbyProviders(LatLng centerLocation) async {
    try {
      // Load all providers from backend
      await ref.read(serviceListProvider.notifier).load();
      
      final allProviders = ref.read(serviceListProvider).providers;
      debugPrint('🔍 Loaded ${allProviders.length} total providers from backend');
      for (var p in allProviders) {
        debugPrint('👤 Provider: ${p.name}, lat: ${p.latitude}, lng: ${p.longitude}');
      }
      
      // Filter providers within search radius
      final nearby = allProviders.where((provider) {
        if (provider.latitude == null || provider.longitude == null) {
          debugPrint('⚠️ Provider ${provider.name} skipped: null lat/lng');
          return false; // Skip providers without location data
        }
        
        final providerLocation = LatLng(provider.latitude!, provider.longitude!);
        final distance = _locationService.calculateDistance(centerLocation, providerLocation);
        debugPrint('📏 Provider ${provider.name} distance: ${distance.toStringAsFixed(2)} km (Radius: $_searchRadius km)');
        
        return distance <= _searchRadius;
      }).toList();

      // Sort by distance (nearest first)
      nearby.sort((a, b) {
        final distanceA = _locationService.calculateDistance(
          centerLocation,
          LatLng(a.latitude!, a.longitude!),
        );
        final distanceB = _locationService.calculateDistance(
          centerLocation,
          LatLng(b.latitude!, b.longitude!),
        );
        return distanceA.compareTo(distanceB);
      });

      setState(() {
        _nearbyProviders = nearby;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading nearby providers: ${e.toString()}';
      });
    }
  }

  /// Update search radius and reload providers
  Future<void> _updateSearchRadius(double newRadius) async {
    if (_currentLocation == null) return;

    setState(() {
      _searchRadius = newRadius;
      _isLoading = true;
    });

    await _loadNearbyProviders(_currentLocation!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Providers'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _initializeLocationAndLoadProviders,
            tooltip: 'Center on my location',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final currentLocation = _currentLocation;
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Finding nearby providers...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeLocationAndLoadProviders,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (currentLocation == null) {
      return const Center(
        child: Text('Location not available'),
      );
    }

    return Column(
      children: [
        // Map view
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: 15.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // OpenStreetMap tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.local_services_app',
              ),

              // Current location marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLocation,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              // Provider markers
              MarkerLayer(
                markers: _nearbyProviders.map((provider) {
                  if (provider.latitude == null || provider.longitude == null) {
                    return null;
                  }

                  final providerLocation = LatLng(provider.latitude!, provider.longitude!);

                  return Marker(
                    point: providerLocation,
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _showProviderDetails(provider),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: provider.isAvailable
                                ? AppColors.success
                                : Colors.grey,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: provider.profileImage.isNotEmpty
                              ? Image.network(
                                  provider.profileImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person, size: 20);
                                  },
                                )
                              : const Icon(Icons.person, size: 20),
                        ),
                      ),
                    ),
                  );
                }).whereType<Marker>().toList(),
              ),

              // Search radius circle
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: currentLocation,
                    radius: _searchRadius * 1000, // Convert km to meters
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderColor: AppColors.primary,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bottom panel with provider list and radius control
        _buildBottomPanel(),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search radius control
          Row(
            children: [
              const Icon(Icons.adjust, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text('Search Radius:'),
              const Spacer(),
              Text('${_searchRadius.toStringAsFixed(1)} km'),
              const SizedBox(width: 8),
              Slider(
                value: _searchRadius,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                onChanged: (value) => _updateSearchRadius(value),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          // Nearby providers list
          Row(
            children: [
              Text(
                '${_nearbyProviders.length} Nearby Providers',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_nearbyProviders.isNotEmpty)
                TextButton(
                  onPressed: () => _showProvidersList(),
                  child: const Text('View All'),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Horizontal scroll of nearby providers
          if (_nearbyProviders.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _nearbyProviders.length > 5 ? 5 : _nearbyProviders.length,
                itemBuilder: (context, index) {
                  final provider = _nearbyProviders[index];
                  final distance = _locationService.calculateDistance(
                    _currentLocation!,
                    LatLng(provider.latitude!, provider.longitude!),
                  );
                  
                  return _buildProviderCard(provider, distance);
                },
              ),
            )
          else
            const Text('No providers found in your area'),
        ],
      ),
    );
  }

  Widget _buildProviderCard(UserModel provider, double distance) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderDetailsScreen(providerId: provider.id),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: provider.profileImage.isNotEmpty
                        ? Image.network(
                            provider.profileImage,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, size: 20);
                            },
                          )
                        : const Icon(Icons.person, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          provider.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    _locationService.getFormattedDistance(
                      _currentLocation!,
                      LatLng(provider.latitude!, provider.longitude!),
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show provider details in a bottom sheet
  void _showProviderDetails(UserModel provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  child: provider.profileImage.isNotEmpty
                      ? Image.network(
                          provider.profileImage,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 30);
                          },
                        )
                      : const Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        provider.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.latitude != null && provider.longitude != null)
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    _locationService.getFormattedDistance(
                      _currentLocation!,
                      LatLng(provider.latitude!, provider.longitude!),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  '${provider.rating.toStringAsFixed(1)} rating',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.attach_money, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Rs ${provider.priceStarting.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderDetailsScreen(providerId: provider.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('View Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show full list of nearby providers
  void _showProvidersList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NearbyProvidersList(
          providers: _nearbyProviders,
          currentLocation: _currentLocation!,
          locationService: _locationService,
        ),
      ),
    );
  }
}

/// Screen showing full list of nearby providers
class _NearbyProvidersList extends StatelessWidget {
  final List<UserModel> providers;
  final LatLng currentLocation;
  final LocationService locationService;

  const _NearbyProvidersList({
    required this.providers,
    required this.currentLocation,
    required this.locationService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Providers'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: providers.isEmpty
            ? const Center(
                child: Text('No providers found in your area'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: providers.length,
                itemBuilder: (context, index) {
                  final provider = providers[index];
                  final distance = locationService.calculateDistance(
                    currentLocation,
                    LatLng(provider.latitude!, provider.longitude!),
                  );
                  
                  return _ProviderListItem(
                    provider: provider,
                    distance: distance,
                    locationService: locationService,
                    currentLocation: currentLocation,
                  );
                },
              ),
      ),
    );
  }
}

/// Individual provider list item with distance info
class _ProviderListItem extends StatelessWidget {
  final UserModel provider;
  final double distance;
  final LocationService locationService;
  final LatLng currentLocation;

  const _ProviderListItem({
    required this.provider,
    required this.distance,
    required this.locationService,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderDetailsScreen(providerId: provider.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: ClipOval(
            child: provider.profileImage.isNotEmpty
                ? Image.network(
                    provider.profileImage,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 25);
                    },
                  )
                : const Icon(Icons.person, size: 25),
          ),
          title: Text(
            provider.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider.category),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    locationService.getFormattedDistance(
                      currentLocation,
                      LatLng(provider.latitude!, provider.longitude!),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    provider.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Rs ${provider.priceStarting.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}