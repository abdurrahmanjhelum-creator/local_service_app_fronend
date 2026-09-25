import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/socket_event_provider.dart';
import '../../utils/app_colors.dart';
import 'booking_details_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationProvider.notifier).loadNotifications());
  }

  String _formatTimeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking_created':
        return Icons.event_available;
      case 'booking_status':
        return Icons.sync_alt;
      case 'review_received':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking_created':
        return Colors.teal;
      case 'booking_status':
        return AppColors.primary;
      case 'review_received':
        return Colors.amber;
      default:
        return AppColors.secondary;
    }
  }

  void _onNotificationTap(NotificationModel item) async {
    // Mark as read first
    if (!item.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(item.id);
    }

    // Deep link to booking if bookingId is attached
    if (item.bookingId.isNotEmpty) {
      final bookingState = ref.read(bookingProvider);
      var matching = bookingState.bookings.where((b) => b.id == item.bookingId);
      if (matching.isEmpty) {
        await ref.read(bookingProvider.notifier).loadBookings();
        matching = ref.read(bookingProvider).bookings.where((b) => b.id == item.bookingId);
      }
      if (matching.isEmpty || !mounted) return;

      ref.read(bookingProvider.notifier).setCurrentBooking(matching.first);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingDetailsScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep socket event controller alive for real-time updates
    ref.watch(socketEventProvider);
    
    final state = ref.watch(notificationProvider);
    final notifications = state.notifications;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: const Text('Notifications'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_active),
                    onPressed: () {
                      // Test notification system
                      ref.read(notificationProvider.notifier).loadNotifications();
                    },
                    tooltip: 'Test Notifications',
                  ),
                  if (notifications.isNotEmpty)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'read_all') {
                          ref.read(notificationProvider.notifier).markAllAsRead();
                        } else if (value == 'clear') {
                          ref.read(notificationProvider.notifier).clearAll();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'read_all',
                          child: Row(
                            children: [
                              Icon(Icons.done_all, size: 20),
                              SizedBox(width: 8),
                              Text('Mark all as read'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Clear history', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No notifications yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(notificationProvider.notifier)
                                .loadNotifications(),
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final item = notifications[index];
                                final iconColor = _getNotificationColor(item.type);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: item.isRead
                                        ? Colors.white
                                        : Colors.blue.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: item.isRead
                                          ? Colors.grey[200]!
                                          : AppColors.primary.withValues(alpha: 0.3),
                                      width: item.isRead ? 1 : 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: iconColor.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getNotificationIcon(item.type),
                                        color: iconColor,
                                        size: 22,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontWeight: item.isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatTimeAgo(item.createdAt),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        item.body,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    onTap: () => _onNotificationTap(item),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
