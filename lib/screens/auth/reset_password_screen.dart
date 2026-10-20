import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/api_constants.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/input_validation.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;
  const ResetPasswordScreen({super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _api = ApiService();
  late final AnimationController _animation;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.post(ApiConstants.resetPassword, {
        'email': widget.email,
        'otp': widget.otp,
        'newPassword': _passwordController.text,
      });
      if (!mounted) return;
      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PasswordResetSuccessScreen()),
        (route) => false,
      );
    } catch (error) {
      if (mounted) setState(() => _error = cleanError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ResetAnimatedPage(
      animation: _animation,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) _ErrorMessage(message: _error!),
            CustomTextField(
              controller: _passwordController,
              label: 'New Password',
              hint: 'Create a strong password',
              icon: Icons.lock_outline,
              isPassword: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: InputValidator.validatePassword,
            ),
            CustomTextField(
              controller: _confirmController,
              label: 'Confirm Password',
              hint: 'Repeat your new password',
              icon: Icons.lock_reset_outlined,
              isPassword: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 8),
            const Text('Password must contain 8+ characters, uppercase, lowercase, and number.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
            const SizedBox(height: 18),
            CustomButton(text: 'Reset Password', isLoading: _loading, onPressed: _reset),
          ],
        ),
      ),
    );
  }
}

class _ResetAnimatedPage extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _ResetAnimatedPage({required this.animation, required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.appBackgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth > 520 ? 480.0 : constraints.maxWidth - 32;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width),
                    child: FadeTransition(
                      opacity: animation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)),
                          const SizedBox(height: 18),
                          const Center(child: CircleAvatar(radius: 38, backgroundColor: Color(0x1F0D9488), child: Icon(Icons.password_rounded, size: 42, color: AppColors.primary))),
                          const SizedBox(height: 24),
                          const Text('Create New Password', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          const Text('Set a strong password for your LocalServe account.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.45)),
                          const SizedBox(height: 26),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.appBackgroundGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(radius: 44, backgroundColor: Color(0x1F16A34A), child: Icon(Icons.check_rounded, size: 52, color: AppColors.success)),
                const SizedBox(height: 22),
                const Text('Password Reset Successful', textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                const Text('Your password has been changed. You can now log in with your new password.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, height: 1.45)),
                const SizedBox(height: 28),
                SizedBox(width: 360, child: CustomButton(text: 'Go to Login', onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  const _ErrorMessage({required this.message});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(12)), child: Text(message, style: const TextStyle(color: AppColors.errorDark, fontSize: 13)));
}
