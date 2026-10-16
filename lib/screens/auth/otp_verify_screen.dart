import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../services/api_service.dart';
import '../../utils/api_constants.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'email_verify_screen.dart';

final otpVerifyLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);
final otpVerifyErrorProvider = StateProvider.autoDispose<String?>((ref) => null);

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String email;
  final String selectedRole;

  const OtpVerifyScreen({
    super.key,
    required this.email,
    required this.selectedRole,
  });

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _apiService = ApiService();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty || code.length != 6) {
      ref.read(otpVerifyErrorProvider.notifier).state =
          'Please enter a valid 6-digit code';
      return;
    }

    ref.read(otpVerifyLoadingProvider.notifier).state = true;
    ref.read(otpVerifyErrorProvider.notifier).state = null;

    try {
      await _apiService.post('${ApiConstants.baseUrl}/auth/verify-otp', {
        'email': widget.email,
        'otp': code,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterScreen(
            verifiedEmail: widget.email,
            selectedRole: widget.selectedRole,
          ),
        ),
      );
    } catch (e) {
      ref.read(otpVerifyErrorProvider.notifier).state = cleanError(e);
    } finally {
      ref.read(otpVerifyLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(otpVerifyLoadingProvider);
    final errorMessage = ref.watch(otpVerifyErrorProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EmailVerifyScreen(selectedRole: widget.selectedRole),
              ),
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
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Enter Verification Code',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We have sent a 6-digit OTP code to your email:\n${widget.email}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
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
                        style: const TextStyle(
                          color: AppColors.errorDark,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  CustomTextField(
                    controller: _otpController,
                    label: '6-Digit OTP Code',
                    hint: '123456',
                    icon: Icons.lock_clock_outlined,
                    keyboardType: TextInputType.number,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'OTP code is required';
                      }
                      if (value.trim().length != 6) {
                        return 'OTP must be exactly 6 digits';
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return 'Please enter numbers only';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Verify & Proceed',
                    isLoading: isLoading,
                    onPressed: _verifyOtp,
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
