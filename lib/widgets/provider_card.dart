import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';
import 'category_icon.dart';
import 'micro_interactions.dart';

/// Professional Provider Card Widget
/// 
/// A reusable, attractive provider card component that matches the app's
/// professional Deep Royal Navy Blue color scheme with clean architecture.
/// 
/// Features:
/// - App-consistent color scheme (Primary: #1E3A8A, Secondary: #0D9488)
/// - Professional gradient backgrounds matching app theme
/// - Hero animations for smooth transitions
/// - Status indicators with proper color coding
/// - Responsive layout with proper spacing
/// - Micro-interactions for enhanced UX
class ProviderCard extends StatelessWidget {
  final dynamic provider;
  final String? currentUserId;
  final VoidCallback? onTap;
  final int index;

  const ProviderCard({
    super.key,
    required this.provider,
    this.currentUserId,
    this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = currentUserId == provider.id;
    final isAvailable = provider.isAvailable;

    return MicroInteractions.staggeredList(
      index: index,
      child: AnimatedCard(
        onTap: isMe ? null : (onTap ?? () {}),
        borderRadius: 16,
        elevation: 2,
        child: Container(
          // Professional gradient background matching app theme
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                isAvailable 
                    ? AppColors.primary.withValues(alpha: 0.03) // Match app primary color
                    : Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAvailable 
                  ? AppColors.primary.withValues(alpha: 0.2) // Match app primary
                  : AppColors.gray200,
              width: isAvailable ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08), // Match app shadow color
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Provider Avatar with professional styling matching app theme
                Hero(
                  tag: 'provider_${provider.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAvailable 
                            ? AppColors.primary.withValues(alpha: 0.3) // Match app primary
                            : AppColors.gray300,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isAvailable 
                              ? AppColors.primary.withValues(alpha: 0.15) // Match app primary
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: userAvatar(
                        provider.profileImage,
                        radius: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Provider Information with app-consistent styling
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Provider Name with professional typography
                      Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary, // Match app text color
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Category badge with app primary color
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1), // Match app primary
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CategoryIcon(
                              category: provider.category,
                              size: 12,
                              useContainer: false,
                              color: AppColors.primary, // Match app primary
                            ),
                            const SizedBox(width: 6),
                            Text(
                              provider.category,
                              style: const TextStyle(
                                color: AppColors.primary, // Match app primary
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Price and status row with app-consistent colors
                      Row(
                        children: [
                          // Price display with app styling
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: AppColors.textSecondary, // Match app text color
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Rs ${provider.priceStarting.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary, // Match app text color
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Availability status with app-consistent colors
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAvailable 
                                  ? AppColors.success.withValues(alpha: 0.1) // Match app success
                                  : AppColors.warning.withValues(alpha: 0.1), // Match app warning
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAvailable 
                                      ? Icons.circle
                                      : Icons.schedule,
                                  size: 6,
                                  color: isAvailable 
                                      ? AppColors.success // Match app success
                                      : AppColors.warning, // Match app warning
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAvailable ? 'Available' : 'Busy',
                                  style: TextStyle(
                                    color: isAvailable 
                                        ? AppColors.success // Match app success
                                        : AppColors.warning, // Match app warning
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Navigation arrow with app secondary color
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1), // Match app secondary
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: AppColors.secondary, // Match app secondary
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact Provider Card for Home Screen
/// 
/// A minimal, space-efficient provider card variant designed for
/// tight spaces while maintaining the app's professional color scheme.
/// 
/// Features:
/// - Minimal design with essential information only
/// - App-consistent colors and styling
/// - Scale animation for professional feedback
/// - Perfect for horizontal scrolling or grid layouts
class CompactProviderCard extends StatelessWidget {
  final dynamic provider;
  final VoidCallback? onTap;

  const CompactProviderCard({
    super.key,
    required this.provider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MicroInteractions.scaleAnimation(
      onTap: onTap ?? () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05), // Match app primary shadow
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar with app-consistent border
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2), // Match app primary
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: userAvatar(provider.profileImage, radius: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name with app text color
                    Text(
                      provider.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary, // Match app text color
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Category with app primary color
                    Row(
                      children: [
                        CategoryIcon(
                          category: provider.category,
                          size: 10,
                          useContainer: false,
                          color: AppColors.primary, // Match app primary
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.category,
                          style: TextStyle(
                            color: AppColors.textSecondary, // Match app text color
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Navigation arrow with app secondary color
              Icon(
                Icons.chevron_right, 
                size: 16,
                color: AppColors.secondary, // Match app secondary
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Featured Provider Card with Premium Design
/// 
/// A premium, eye-catching provider card designed for featured sections
/// with the app's signature Deep Royal Navy Blue gradient and professional styling.
/// 
/// Features:
/// - App-consistent primary gradient (#1E3A8A to #3B82F6)
/// - Premium shadow effects with app colors
/// - Hero animations for smooth transitions
/// - Modern chip-based information display
/// - Bounce animation for attention-grabbing effect
/// - Perfect for featured providers or promotions
class FeaturedProviderCard extends StatelessWidget {
  final dynamic provider;
  final VoidCallback? onTap;

  const FeaturedProviderCard({
    super.key,
    required this.provider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MicroInteractions.bounce(
      child: GestureDetector(
        onTap: onTap ?? () {},
        child: Container(
          // App-consistent primary gradient
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient, // Use app's defined gradient
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3), // Match app primary
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'featured_${provider.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withValues(alpha: 0.3), // Match app dark
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: userAvatar(provider.profileImage, radius: 40),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CategoryIcon(
                                  category: provider.category,
                                  size: 12,
                                  useContainer: false,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  provider.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.attach_money,
                      label: 'Rs ${provider.priceStarting.toStringAsFixed(0)}',
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: provider.isAvailable ? Icons.check_circle : Icons.schedule,
                      label: provider.isAvailable ? 'Available' : 'Busy',
                      color: provider.isAvailable 
                          ? AppColors.success // Match app success
                          : AppColors.warning, // Match app warning
                    ),
                    const SizedBox(width: 8),
                    if (provider.rating != null)
                      _buildInfoChip(
                        icon: Icons.star,
                        label: provider.rating.toString(),
                        color: Colors.amber,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build professional info chip with app-consistent styling
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
