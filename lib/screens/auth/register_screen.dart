import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../services/location_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/category_dropdown.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'email_verify_screen.dart';
import '../navigation_bar_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String verifiedEmail;
  final String selectedRole; // 🔥 Locked role from previous screen

  const RegisterScreen({
    super.key,
    required this.verifiedEmail,
    required this.selectedRole,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocationService _locationService = LocationService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceController = TextEditingController();
  final _addressController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill verified email
    _emailController.text = widget.verifiedEmail;
    
    // Locking the role in the provider state
    Future.microtask(() {
      ref.read(registerRoleProvider('register').notifier).state = widget.selectedRole;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      ref.read(registerImageProvider('register').notifier).state = picked;
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    try {
      final loc = await _locationService.getCurrentLocation();
      if (loc != null) {
        _latitude = loc.latitude;
        _longitude = loc.longitude;
        final addr = await _locationService.getAddressFromCoordinates(loc);
        if (addr.isNotEmpty && addr != 'Unknown location') {
          _addressController.text = addr;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location detected successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to detect current location. Please check location permissions.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error detecting location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _openMapPicker() async {
    LatLng initialCenter = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : const LatLng(33.6844, 73.0479);

    LatLng selectedCenter = initialCenter;
    final MapController mapController = MapController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      'Pin Your Service Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: initialCenter,
                        initialZoom: 15.0,
                        onPositionChanged: (position, hasGesture) {
                          if (position.center != null) {
                            selectedCenter = position.center!;
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.local_services_app',
                        ),
                      ],
                    ),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 36),
                        child: Icon(
                          Icons.location_pin,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Text(
                          'Drag the map to position the pin at your exact service location',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() => _isLocating = true);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      try {
                        _latitude = selectedCenter.latitude;
                        _longitude = selectedCenter.longitude;
                        final addr = await _locationService.getAddressFromCoordinates(selectedCenter);
                        if (addr.isNotEmpty) {
                          _addressController.text = addr;
                        }
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Location pinned successfully!')),
                        );
                      } catch (e) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Error getting address: $e')),
                        );
                      } finally {
                        if (mounted) setState(() => _isLocating = false);
                      }
                    },
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final isProvider = ref.read(registerRoleProvider('register')) == 'provider';

    double? lat = _latitude;
    double? lng = _longitude;
    final addr = _addressController.text.trim();

    if (isProvider && addr.isNotEmpty && (lat == null || lng == null)) {
      try {
        final coords = await _locationService.getCoordinatesFromAddress(addr);
        if (coords != null) {
          lat = coords.latitude;
          lng = coords.longitude;
        }
      } catch (_) {}

      if (lat == null || lng == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find GPS coordinates for this address. Please click "Detect GPS Location".'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final success = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim(),
          role: ref.read(registerRoleProvider('register')),
          imageFile: ref.read(registerImageProvider('register')),
          category: isProvider
              ? ref.read(registerCategoryProvider('register'))
              : null,
          priceStarting: isProvider
              ? double.tryParse(_priceController.text.trim())
              : null,
          experienceYears: isProvider
              ? int.tryParse(_experienceController.text.trim())
              : null,
          address: isProvider ? addr : null,
          latitude: isProvider ? lat : null,
          longitude: isProvider ? lng : null,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
      // On success, navigate directly to NavigationBarScreen and clear stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const NavigationBarScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final role = ref.watch(registerRoleProvider('register'));
    final category = ref.watch(registerCategoryProvider('register'));
    final image = ref.watch(registerImageProvider('register'));
    final categoryState = ref.watch(categoryProvider);
    final categories = categoryState.categories.isEmpty
        ? defaultCategories
        : categoryState.categories.map((item) => item.name).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBar(
                    title: const Text('Complete Profile'),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EmailVerifyScreen(selectedRole: widget.selectedRole),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 45,
                        backgroundImage: image != null
                          ? (kIsWeb
                            ? NetworkImage(image.path)
                            : FileImage(File(image.path)) as ImageProvider)
                          : null,
                        child: image == null
                          ? const Icon(Icons.camera_alt, size: 32)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (auth.errorMessage != null)
                  Text(
                    auth.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const Text('Account Type', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Customer'),
                      selected: role == 'customer',
                      onSelected: null,
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Provider'),
                      selected: role == 'provider',
                      onSelected: null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _nameController,
                  label: 'Full name',
                  hint: 'your name',
                  icon: Icons.person_outline,
                  validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                ),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email (Verified)',
                  hint: 'you@email.com',
                  icon: Icons.verified_user_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: false,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Valid email required' : null,
                ),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  hint: 'phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Phone required' : null,
                ),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'at least 6 characters',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Password too short' : null,
                ),
                if (role == 'provider') ...[
                  const SizedBox(height: 8),
                  const Text('Work Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  CategoryDropdown(
                    value: category,
                    items: categories,
                    onChanged: (value) => ref.read(registerCategoryProvider('register').notifier).state = value,
                  ),
                  CustomTextField(
                    controller: _priceController,
                    label: 'Starting price (Rs.)',
                    hint: '500',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        role == 'provider' && (v == null || v.isEmpty)
                            ? 'Price required'
                            : null,
                  ),
                  CustomTextField(
                    controller: _experienceController,
                    label: 'Experience (years)',
                    hint: '3',
                    icon: Icons.work_outline,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        role == 'provider' && (v == null || v.isEmpty)
                            ? 'Experience required'
                            : null,
                  ),
                  CustomTextField(
                    controller: _addressController,
                    label: 'Service Address / Location (e.g. Lahore, Shamsabad)',
                    hint: 'Lahore, Shamsabad, Gulberg',
                    icon: Icons.location_on_outlined,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: _openMapPicker,
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text(
                          'Pick on Map',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _isLocating ? null : _detectLocation,
                        icon: _isLocating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, size: 16),
                        label: Text(
                          _isLocating ? 'Detecting...' : 'Detect GPS Location',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Register Account',
                  isLoading: auth.isLoading,
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
