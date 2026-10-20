import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/api_constants.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'reset_password_screen.dart';

class PasswordResetOtpScreen extends StatefulWidget {
  final String email;
  const PasswordResetOtpScreen({super.key, required this.email});

  @override
  State<PasswordResetOtpScreen> createState() => _PasswordResetOtpScreenState();
}

class _PasswordResetOtpScreenState extends State<PasswordResetOtpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _api = ApiService();
  late final AnimationController _animation;
  Timer? _timer;
  int _seconds = 300;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds == 0) {
        timer.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _resend() async {
    if (_seconds > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await _api.post(ApiConstants.forgotPassword, {'email': widget.email});
      _startTimer();
    } catch (error) {
      if (mounted) setState(() => _error = cleanError(error));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(
          email: widget.email,
          otp: _otpController.text.trim(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animation.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return _AuthAnimatedPage(
      animation: _animation,
      title: 'Verify Your Account',
      subtitle: 'Enter the 6-digit code sent to ${widget.email}.',
      icon: Icons.mark_email_read_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_error != null) _ErrorMessage(message: _error!),
            CustomTextField(
              controller: _otpController,
              label: '6-Digit OTP Code',
              hint: '123456',
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final code = value?.trim() ?? '';
                if (!RegExp(r'^\d{6}$').hasMatch(code)) return 'Enter a valid 6-digit code';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              _seconds == 0 ? 'Code expired' : 'Code expires in $minutes:$seconds',
              style: TextStyle(color: _seconds == 0 ? AppColors.error : AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            CustomButton(text: 'Verify OTP', onPressed: _continue),
            TextButton(
              onPressed: _resend,
              child: _resending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_seconds == 0 ? 'Resend OTP' : 'Resend available after timer'),
            ),
          ],
        ),
      ),
    );
  }
}

// Kept local to this flow so each step has the same responsive animation.
class _AuthAnimatedPage extends StatelessWidget {
  final Animation<double> animation;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  const _AuthAnimatedPage({required this.animation, required this.title, required this.subtitle, required this.icon, required this.child});

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
                          Center(child: CircleAvatar(radius: 38, backgroundColor: AppColors.primary.withValues(alpha: .12), child: Icon(icon, size: 42, color: AppColors.primary))),
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
  Widget build(BuildContext context) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(12)), child: Text(message, style: const TextStyle(color: AppColors.errorDark, fontSize: 13)));
}
