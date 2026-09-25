import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/socket_event_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/app_colors.dart';
import '../shared/edit_profile_screen.dart';

class ProviderHomeScreen extends ConsumerWidget {
  final void Function(int index)? onOpenTab;

  const ProviderHomeScreen({super.key, this.onOpenTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep socket event controller alive for real-time updates
    ref.watch(socketEventProvider);
    
    final authState = ref.watch(authProvider);
    final user = authState.user;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final bookingState = ref.watch(bookingProvider);
    final bookings = bookingState.bookings;

    final pendingJobs = bookings
        .where((b) => b.status.toLowerCase() == 'pending')
        .length;
    final activeJobs = bookings
        .where((b) => b.status.toLowerCase() == 'accepted')
        .length;
    final completedJobs = bookings
        .where((b) => b.status.toLowerCase() == 'completed')
        .length;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.appBackgroundGradient,
      ),
      child: RefreshIndicator(
        onRefresh: () => ref.read(bookingProvider.notifier).loadBookings(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        userAvatar(user.profileImage, radius: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.infoLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  user.category.isEmpty
                                      ? 'General Provider'
                                      : user.category,
                                  style: TextStyle(
                                    color: AppColors.infoDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.warning,
                              size: 28,
                            ),
                            Text(
                              user.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      title: const Text(
                        'Live Availability Status',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        user.isAvailable
                            ? 'You are active & visible to new customers'
                            : 'You are offline & hidden from search results',
                        style: TextStyle(
                          fontSize: 12,
                          color: user.isAvailable
                              ? AppColors.successDark
                              : AppColors.errorDark,
                        ),
                      ),
                      value: user.isAvailable,
                      activeTrackColor: AppColors.success,
                      onChanged: (bool value) async {
                        await ref
                            .read(authProvider.notifier)
                            .updateProfile(isAvailable: value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Job Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 380 ? 2 : 3;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: columns == 2 ? 1.45 : 1.1,
                  children: [
                    _buildStatCard(
                      'Pending Requests',
                      pendingJobs.toString(),
                      AppColors.warning,
                      Icons.hourglass_empty,
                    ),
                    _buildStatCard(
                      'Active Jobs',
                      activeJobs.toString(),
                      AppColors.info,
                      Icons.run_circle_outlined,
                    ),
                    _buildStatCard(
                      'Completed',
                      completedJobs.toString(),
                      AppColors.success,
                      Icons.check_circle_outline,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Service Rates & Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.attach_money,
                    label: 'Starting Rate',
                    value: 'Rs ${user.priceStarting.toStringAsFixed(0)}',
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.work_history_outlined,
                    label: 'Experience',
                    value: '${user.experienceYears} Years',
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Business Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _HomeCard(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Manage Bookings',
                  subtitle: 'Accept or update jobs',
                  color: AppColors.error,
                  onTap: () => onOpenTab?.call(1),
                ),
                _HomeCard(
                  icon: Icons.edit_note_outlined,
                  title: 'Update Profile',
                  subtitle: 'Edit service rates & info',
                  color: AppColors.primaryLight,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 1,
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.gray800,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray500.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                radius: 20,
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.gray600, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
