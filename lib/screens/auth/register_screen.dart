import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../utils/app_colors.dart';
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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceController = TextEditingController();

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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim(),
            role: ref.read(registerRoleProvider('register')),
            imageFile: ref.read(registerImageProvider('register')),
            category: ref.read(registerRoleProvider('register')) == 'provider'
              ? ref.read(registerCategoryProvider('register'))
              : null,
            priceStarting: ref.read(registerRoleProvider('register')) == 'provider'
              ? double.tryParse(_priceController.text.trim())
              : null,
          experienceYears: ref.read(registerRoleProvider('register')) == 'provider'
              ? int.tryParse(_experienceController.text.trim())
              : null,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
      // 🔥 Success hone par direct NavigationBarScreen par jayein aur stack clear karein
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
    final categories = categoryState.categories.map((item) => item.name).toList();

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
