import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/info_row.dart';
import '../../widgets/micro_interactions.dart';
import '../../widgets/skeleton_loaders.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? iconBackgroundColor,
  }) {
    return Container(
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
      child: InfoRow(
        icon: icon,
        label: label,
        value: value,
        iconBackgroundColor: iconBackgroundColor ?? Colors.blue.withValues(alpha: 0.1),
        iconColor: iconColor ?? Colors.blue[700],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete account?'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ref.read(authProvider.notifier).deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (authState.isCheckingAuth || user == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.appBackgroundGradient,
          ),
          child: const LoadingScreenSkeleton(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: MicroInteractions.fadeIn(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: userAvatar(user.profileImage, radius: 50),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.isProvider ? 'Service Provider' : 'Customer',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    MicroInteractions.staggeredList(
                      index: 0,
                      child: _infoCard(
                        icon: Icons.person,
                        label: 'Name',
                        value: user.name,
                      ),
                    ),
                    const SizedBox(height: 16),
                    MicroInteractions.staggeredList(
                      index: 1,
                      child: _infoCard(
                        icon: Icons.email,
                        label: 'Email',
                        value: user.email,
                      ),
                    ),
                    const SizedBox(height: 16),
                    MicroInteractions.staggeredList(
                      index: 2,
                      child: _infoCard(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: user.phone,
                      ),
                    ),
                    const SizedBox(height: 16),
                    MicroInteractions.staggeredList(
                      index: 3,
                      child: _infoCard(
                        icon: Icons.badge,
                        label: 'Role',
                        value: user.isProvider ? 'Provider' : 'Customer',
                      ),
                    ),
                    if (user.isProvider) ...[
                      const SizedBox(height: 16),
                      MicroInteractions.staggeredList(
                        index: 4,
                        child: _infoCard(
                          icon: Icons.category,
                          label: 'Category',
                          value: user.category,
                        ),
                      ),
                      const SizedBox(height: 16),
                      MicroInteractions.staggeredList(
                        index: 5,
                        child: _infoCard(
                          icon: Icons.attach_money,
                          label: 'Starting price',
                          value: 'Rs ${user.priceStarting.toStringAsFixed(0)}',
                        ),
                      ),
                      const SizedBox(height: 16),
                      MicroInteractions.staggeredList(
                        index: 6,
                        child: _infoCard(
                          icon: Icons.work_history,
                          label: 'Experience',
                          value: '${user.experienceYears} years',
                        ),
                      ),
                      const SizedBox(height: 16),
                      MicroInteractions.staggeredList(
                        index: 7,
                        child: _infoCard(
                          icon: Icons.check_circle,
                          label: 'Available',
                          value: user.isAvailable ? 'Yes' : 'No',
                          iconBackgroundColor: user.isAvailable
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          iconColor: user.isAvailable ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: AnimatedButton(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                              (route) => false,
                            );
                          }
                        },
                        backgroundColor: Colors.red[700],
                        child: const Text('Logout'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    MicroInteractions.rippleEffect(
                      onTap: () => _confirmDelete(context, ref),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_forever),
                            const SizedBox(width: 8),
                            Text(
                              'Delete account',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
