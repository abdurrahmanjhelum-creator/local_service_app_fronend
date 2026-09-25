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
    await ref.read(serviceListProvider.notifier).load(category: category);
  }

  List<dynamic> _filtered(List<dynamic> providers, String query) {
    if (query.trim().isEmpty) return providers;
    return providers.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();
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
              TextField(
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
