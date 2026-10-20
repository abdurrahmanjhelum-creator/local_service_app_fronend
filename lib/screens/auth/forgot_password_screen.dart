import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/api_constants.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/input_validation.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'password_reset_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _api = ApiService();
  late final AnimationController _animation;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  @override
  void dispose() {
    _animation.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.post(ApiConstants.forgotPassword, {
        'email': _emailController.text.trim().toLowerCase(),
      });
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PasswordResetOtpScreen(
            email: _emailController.text.trim().toLowerCase(),
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = cleanError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthAnimatedPage(
      animation: _animation,
      title: 'Forgot Password?',
      subtitle: 'Enter your registered email and we will send you a verification code.',
      icon: Icons.lock_reset_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_error != null) _ErrorMessage(message: _error!),
            CustomTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'you@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: InputValidator.validateEmail,
            ),
            const SizedBox(height: 14),
            CustomButton(
              text: 'Send OTP',
              isLoading: _loading,
              onPressed: _sendCode,
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Remember your password? Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthAnimatedPage extends StatelessWidget {
  final Animation<double> animation;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _AuthAnimatedPage({
    required this.animation,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

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
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .08),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: CircleAvatar(
                                radius: 38,
                                backgroundColor: AppColors.primary.withValues(alpha: .12),
                                child: Icon(icon, size: 42, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 8),
                            Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.45)),
                            const SizedBox(height: 26),
                            child,
                          ],
                        ),
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

class _ErrorMessage extends StatelessWidget {
  final String message;
  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.errorDark, fontSize: 13)),
    );
  }
}
