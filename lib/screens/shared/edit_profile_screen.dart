import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/category_dropdown.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _experienceController;
  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _categoryController = TextEditingController(text: user?.category ?? '');
    _priceController = TextEditingController(
      text: user?.priceStarting.toStringAsFixed(0) ?? '0',
    );
    _experienceController = TextEditingController(
      text: '${user?.experienceYears ?? 0}',
    );
    Future.microtask(() {
      ref.read(editAvailabilityProvider('edit-profile').notifier).state =
          user?.isAvailable ?? true;
      ref.read(editCategoryProvider('edit-profile').notifier).state =
          user?.category;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _categoryController.dispose();
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
      ref.read(editImageProvider('edit-profile').notifier).state = picked;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider).user;

    final success = await ref
        .read(authProvider.notifier)
        .updateProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          category: user?.isProvider == true
              ? _categoryController.text.trim()
              : null,
          priceStarting: user?.isProvider == true
              ? double.tryParse(_priceController.text.trim())
              : null,
          experienceYears: user?.isProvider == true
              ? int.tryParse(_experienceController.text.trim())
              : null,
          isAvailable: user?.isProvider == true
              ? ref.read(editAvailabilityProvider('edit-profile'))
              : null,
          imageFile: ref.read(editImageProvider('edit-profile')),
        );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final image = ref.watch(editImageProvider('edit-profile'));
    final isAvailable = ref.watch(editAvailabilityProvider('edit-profile'));
    final selectedCategory = ref.watch(editCategoryProvider('edit-profile'));
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
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppBar(title: const Text('Edit profile')),
                  if (user == null)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: image != null
                              ? CircleAvatar(
                                  radius: 45,
                                  backgroundImage: kIsWeb
                                      ? NetworkImage(image.path)
                                      : FileImage(File(image.path))
                                          as ImageProvider,
                                )
                              : userAvatar(user.profileImage, radius: 45),
                        ),
                        const SizedBox(height: 8),
                        const Text('Tap to change photo'),
                        if (auth.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              auth.errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        CustomTextField(
                          controller: _nameController,
                          label: 'Name',
                          hint: 'your name',
                          icon: Icons.person_outline,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Name required' : null,
                        ),
                        CustomTextField(
                          controller: _phoneController,
                          label: 'Phone',
                          hint: 'phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Phone required' : null,
                        ),
                        if (user.isProvider) ...[
                          CategoryDropdown(
                            value: selectedCategory,
                            items: categories,
                            onChanged: (value) {
                              _categoryController.text = value ?? '';
                              ref
                                      .read(
                                        editCategoryProvider(
                                          'edit-profile',
                                        ).notifier,
                                      )
                                      .state =
                                  value;
                            },
                          ),
                          CustomTextField(
                            controller: _priceController,
                            label: 'Starting price',
                            hint: '500',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                          ),
                          CustomTextField(
                            controller: _experienceController,
                            label: 'Experience years',
                            hint: '3',
                            icon: Icons.work_outline,
                            keyboardType: TextInputType.number,
                          ),
                          SwitchListTile(
                            title: const Text('Available for bookings'),
                            value: isAvailable,
                            onChanged: (value) =>
                                ref
                                        .read(
                                          editAvailabilityProvider(
                                            'edit-profile',
                                          ).notifier,
                                        )
                                        .state =
                                    value,
                          ),
                        ],
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Save',
                          isLoading: auth.isLoading,
                          onPressed: _save,
                        ),
                      ],
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
