import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../services/api_service.dart';
import '../../utils/api_constants.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'otp_verify_screen.dart';
import 'role_selection_screen.dart';

// Riverpod local state providers for email verification loading and error management
final emailVerifyLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);
final emailVerifyErrorProvider = StateProvider.autoDispose<String?>((ref) => null);

class EmailVerifyScreen extends ConsumerWidget {
  final String selectedRole;

  const EmailVerifyScreen({super.key, required this.selectedRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final apiService = ApiService();
    
    final isLoading = ref.watch(emailVerifyLoadingProvider);
    final errorMessage = ref.watch(emailVerifyErrorProvider);

    Future<void> sendOtp() async {
      if (!formKey.currentState!.validate()) return;

      ref.read(emailVerifyLoadingProvider.notifier).state = true;
      ref.read(emailVerifyErrorProvider.notifier).state = null;

      final emailStr = emailController.text.trim();

      try {
        await apiService.post('${ApiConstants.baseUrl}/auth/send-otp', {
          'email': emailStr,
        });

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification OTP sent successfully to your email.')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerifyScreen(
              email: emailStr,
              selectedRole: selectedRole,
            ),
          ),
        );
      } catch (e) {
        ref.read(emailVerifyErrorProvider.notifier).state = cleanError(e);
      } finally {
        ref.read(emailVerifyLoadingProvider.notifier).state = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Signing up as ${selectedRole[0].toUpperCase()}${selectedRole.substring(1)}. Please enter your email to receive a verification code.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: AppColors.errorDark, fontSize: 13),
                      ),
                    ),

                  CustomTextField(
                    controller: emailController,
                    label: 'Email Address',
                    hint: 'example@gmail.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'Send Verification Code',
                    isLoading: isLoading,
                    onPressed: sendOtp,
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
