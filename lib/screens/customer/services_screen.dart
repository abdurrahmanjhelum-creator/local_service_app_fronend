import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/micro_interactions.dart';
import '../../widgets/provider_card.dart';
import 'provider_details_screen.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String providerKey;
  const ServicesScreen({super.key, this.initialCategory, this.providerKey = 'main_services'});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  final _searchController = TextEditingController();
  
  // Filter states
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  double _distanceKm = 25;
  bool _isAvailable = false;
  bool _isVerified = false;
  String _sortBy = 'rating_desc';
  
  bool get hasActiveFilters => 
      _minPrice != null || 
      _maxPrice != null || 
      _minRating != null || 
      _distanceKm < 25 ||
      _isAvailable || 
      _isVerified;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (widget.initialCategory != null) {
        ref.read(servicesCategoryProvider(widget.providerKey).notifier).state = widget.initialCategory;
      }
      final currentCategory = ref.read(servicesCategoryProvider(widget.providerKey));
      ref.read(serviceListProvider.notifier).load(category: currentCategory);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load(String key, {String? category}) async {
    // Update category state
    ref.read(servicesCategoryProvider(key).notifier).state = category;
    // Only refresh provider list, not full screen
    await ref.read(serviceListProvider.notifier).load(
      category: category,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      isAvailable: _isAvailable ? true : null,
      isVerified: _isVerified ? true : null,
      sortBy: _sortBy,
      distanceKm: _distanceKm,
    );
  }

  List<dynamic> _filtered(List<dynamic> providers, String query) {
    if (query.trim().isEmpty) return providers;
    return providers.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _minRating = null;
      _distanceKm = 25;
      _isAvailable = false;
      _isVerified = false;
      _sortBy = 'rating_desc';
    });
    _load(widget.providerKey, category: ref.read(servicesCategoryProvider(widget.providerKey)));
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Advanced Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Price Range
              const Text('Price Range', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Min Price',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _minPrice = double.tryParse(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Max Price',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _maxPrice = double.tryParse(value);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Rating
              const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Slider(
                value: _minRating ?? 0,
                min: 0,
                max: 5,
                divisions: 10,
                label: (_minRating ?? 0).toStringAsFixed(1),
                onChanged: (value) {
                  setModalState(() {
                    _minRating = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),

              // Distance
              const Text('Maximum Distance', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('0 km'),
                  Text('${_distanceKm.toStringAsFixed(0)} km'),
                  const Text('50 km'),
                ],
              ),
              Slider(
                value: _distanceKm,
                min: 0,
                max: 50,
                divisions: 50,
                label: '${_distanceKm.toStringAsFixed(0)} km',
                onChanged: (value) {
                  setModalState(() {
                    _distanceKm = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Availability
              SwitchListTile(
                title: const Text('Available Now'),
                subtitle: const Text('Show only available providers'),
                value: _isAvailable,
                onChanged: (value) {
                  setModalState(() {
                    _isAvailable = value;
                  });
                },
              ),
              
              const SizedBox(height: 8),
              
              // Verification
              SwitchListTile(
                title: const Text('Verified Only'),
                subtitle: const Text('Show only verified providers'),
                value: _isVerified,
                onChanged: (value) {
                  setModalState(() {
                    _isVerified = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Sort By
              const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _sortBy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'rating_desc', child: Text('Highest Rated')),
                  DropdownMenuItem(value: 'rating_asc', child: Text('Lowest Rated')),
                  DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                  DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                  DropdownMenuItem(value: 'distance', child: Text('Nearest First')),
                  DropdownMenuItem(value: 'experience_desc', child: Text('Most Experienced')),
                  DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                ],
                onChanged: (value) {
                  setModalState(() {
                    _sortBy = value ?? 'rating_desc';
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    _load(widget.providerKey, category: ref.read(servicesCategoryProvider(widget.providerKey)));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final key = widget.providerKey;
    final serviceState = ref.watch(serviceListProvider);
    final categoryState = ref.watch(categoryProvider);
    final selectedCategory = ref.watch(servicesCategoryProvider(key));
    final query = ref.watch(servicesSearchProvider(key));
    final list = _filtered(serviceState.providers, query.toLowerCase());
    final categories = categoryState.categories.map((item) => item.name).toList();

    return Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () => _load(key, category: selectedCategory),
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or category',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => ref.read(servicesSearchProvider(key).notifier).state = value,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: hasActiveFilters
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: hasActiveFilters
                            ? Colors.white
                            : AppColors.primary,
                      ),
                      onPressed: _showFilterBottomSheet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip('All', selectedCategory == null, () => _load(key)),
                    ...categories.map(
                      (name) => _chip(
                        name,
                        selectedCategory == name,
                        () => _load(key, category: name),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (serviceState.isLoading && serviceState.providers.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Loading providers...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              else if (serviceState.error != null)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        serviceState.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _load(key, category: selectedCategory),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No providers found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...list.asMap().map((index, provider) {
                  return MapEntry(
                    index,
                    ProviderCard(
                      provider: provider,
                      currentUserId: currentUser?.id,
                      index: index,
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageTransition(
                            child: ProviderDetailsScreen(
                              providerId: provider.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).values,
            ],
          ),
        ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : Colors.grey[700],
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
