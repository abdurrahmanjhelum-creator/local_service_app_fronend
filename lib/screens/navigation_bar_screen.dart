import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/service_provider.dart';
import '../providers/socket_event_provider.dart';
import '../providers/ui_state_provider.dart';
import '../services/fcm_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import 'customer/bookings_screen.dart';
import 'customer/customer_home_screen.dart';
import 'customer/services_screen.dart';
import 'provider/provider_home_screen.dart';
import 'shared/chat_list_screen.dart';
import 'shared/edit_profile_screen.dart';
import 'shared/profile_screen.dart';
import '../widgets/appbarheader.dart';

class NavigationBarScreen extends ConsumerStatefulWidget {
  const NavigationBarScreen({super.key});

  @override
  ConsumerState<NavigationBarScreen> createState() => _NavigationBarScreenState();
}

class _NavigationBarScreenState extends ConsumerState<NavigationBarScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationProvider.notifier).loadNotifications();
      // Initialize Clean Architecture Real-Time Socket Event & Notification Controller
      ref.read(socketEventProvider);
      // Load conversations for chat
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(chatProvider.notifier).loadConversations(user.id);
      }
    });
  }

  void _selectTab(int index, {String? category}) {
    if (index == 1 && category != null) {
      const servicesKey = 'main_services';
      ref.read(servicesCategoryProvider(servicesKey).notifier).state = category;
      ref.read(serviceListProvider.notifier).load(category: category);
    }
    ref.read(selectedTabProvider('root').notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    // Keep Clean Architecture SocketEventController active and listening to real-time events
    ref.watch(socketEventProvider);

    final isProvider = ref.watch(authProvider).user?.isProvider == true;
    final selectedIndex = ref.watch(selectedTabProvider('root'));
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final pages = isProvider
        ? <Widget>[
            ProviderHomeScreen(onOpenTab: (index) => _selectTab(index)),
            const ChatListScreen(),
            const BookingsScreen(),
            const ProfileScreen(),
          ]
        : <Widget>[
            CustomerHomeScreen(onOpenTab: (index, {category}) => _selectTab(index, category: category)),
            ServicesScreen(providerKey: 'main_services', initialCategory: ref.watch(servicesCategoryProvider('main_services'))),
            const ChatListScreen(),
            const BookingsScreen(),
            const ProfileScreen(),
          ];

    final titles = isProvider
        ? const ['Provider Dashboard', 'Messages', 'Bookings', 'Profile']
        : [AppConstants.appName, 'Services', 'Messages', 'Bookings', 'Profile'];

    final items = isProvider
        ? const [
            _NavItemData(icon: Icons.dashboard_rounded, label: 'Home'),
            _NavItemData(icon: Icons.chat_rounded, label: 'Messages'),
            _NavItemData(icon: Icons.calendar_month_rounded, label: 'Bookings'),
            _NavItemData(icon: Icons.person_rounded, label: 'Profile'),
          ]
        : const [
            _NavItemData(icon: Icons.grid_view_rounded, label: 'Home'),
            _NavItemData(icon: Icons.construction_rounded, label: 'Services'),
            _NavItemData(icon: Icons.chat_rounded, label: 'Messages'),
            _NavItemData(icon: Icons.calendar_month_rounded, label: 'Bookings'),
            _NavItemData(icon: Icons.person_rounded, label: 'Profile'),
          ];

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: Column(
          children: [
            AppBarHeader(
              title: titles[selectedIndex],
              actions: [
                // Test notification button
                IconButton(
                  icon: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {
                    FcmService().testMultipleNotifications();
                  },
                  tooltip: 'Test Notifications',
                ),
                if (titles[selectedIndex] == 'Profile')
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                const SizedBox(width: 8),
              ],
            ),
            Expanded(
              child: pages[selectedIndex],
            ),
            // Custom Professional Bottom Navigation Bar UI
            Container(
              height: 75 + (bottomPadding > 0 ? bottomPadding * 0.6 : 10),
              padding: EdgeInsets.only(
                bottom: bottomPadding > 0 ? bottomPadding : 10,
                left: 12,
                right: 12,
                top: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final isSelected = selectedIndex == index;
                  final item = items[index];
                  final chatState = ref.watch(chatProvider);
                  final messagesIndex = isProvider ? 1 : 2;
                  final hasUnreadMessages = chatState.hasUnreadMessages && index == messagesIndex;

                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _selectTab(index);
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: isSelected ? 48 : 0,
                                  height: isSelected ? 32 : 0,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                Icon(
                                  item.icon,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textTertiary.withValues(alpha: 0.7),
                                  size: isSelected ? 26 : 24,
                                ),
                                if (hasUnreadMessages)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textTertiary.withValues(alpha: 0.7),
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                              child: Text(item.label),
                            ),
                            const SizedBox(height: 2),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isSelected ? 4 : 0,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}
