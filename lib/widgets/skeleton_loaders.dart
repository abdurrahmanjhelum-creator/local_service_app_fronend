import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Professional Skeleton Loader Widgets
/// Clean architecture for consistent loading states across the app
class SkeletonLoaders {
  SkeletonLoaders._();

  /// Provider card skeleton
  static Widget providerCard() {
    return ShimmerWrapper(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            _circleSkeleton(size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _textSkeleton(width: 120, height: 16),
                  const SizedBox(height: 8),
                  _textSkeleton(width: 80, height: 12),
                  const SizedBox(height: 4),
                  _textSkeleton(width: 100, height: 12),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _iconSkeleton(),
          ],
        ),
      ),
    );
  }

  /// Booking card skeleton
  static Widget bookingCard() {
    return ShimmerWrapper(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _circleSkeleton(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _textSkeleton(width: 100, height: 14),
                      const SizedBox(height: 4),
                      _textSkeleton(width: 60, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _textSkeleton(width: double.infinity, height: 12),
            const SizedBox(height: 8),
            _textSkeleton(width: 150, height: 12),
            const SizedBox(height: 12),
            Row(
              children: [
                _statusSkeleton(),
                const SizedBox(width: 8),
                _textSkeleton(width: 80, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Profile header skeleton
  static Widget profileHeader() {
    return ShimmerWrapper(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Column(
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: _circleSkeleton(size: 100),
                  ),
                ),
                const SizedBox(height: 16),
                _textSkeleton(width: 120, height: 22),
                const SizedBox(height: 8),
                _textSkeleton(width: 80, height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Info card skeleton
  static Widget infoCard() {
    return ShimmerWrapper(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _circleSkeleton(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _textSkeleton(width: 60, height: 12),
                  const SizedBox(height: 8),
                  _textSkeleton(width: 100, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Notification skeleton
  static Widget notification() {
    return ShimmerWrapper(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _circleSkeleton(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _textSkeleton(width: 120, height: 14),
                  const SizedBox(height: 8),
                  _textSkeleton(width: double.infinity, height: 12),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _textSkeleton(width: 40, height: 12),
          ],
        ),
      ),
    );
  }

  /// Home card skeleton
  static Widget homeCard() {
    return ShimmerWrapper(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _circleSkeleton(size: 40),
              const SizedBox(height: 12),
              _textSkeleton(width: 80, height: 14),
              const SizedBox(height: 4),
              _textSkeleton(width: 60, height: 11),
            ],
          ),
        ),
      ),
    );
  }

  /// Category chip skeleton
  static Widget categoryChip() {
    return ShimmerWrapper(
      child: Container(
        width: 80,
        height: 32,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // Private helper methods
  static Widget _circleSkeleton({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget _textSkeleton({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  static Widget _iconSkeleton() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  static Widget _statusSkeleton() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Animated Shimmer Wrapper
class ShimmerWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerWrapper> createState() => _ShimmerWrapperState();
}

class _ShimmerWrapperState extends State<ShimmerWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_animation.value, -0.3),
              end: Alignment(_animation.value + 1, 0.3),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Loading Screen Skeleton
class LoadingScreenSkeleton extends StatelessWidget {
  const LoadingScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SkeletonLoaders.profileHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SkeletonLoaders.infoCard(),
                SkeletonLoaders.infoCard(),
                SkeletonLoaders.infoCard(),
                SkeletonLoaders.infoCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
