import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/socket_event_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../utils/api_constants.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/info_row.dart';
import '../../widgets/review_dialog.dart';

class BookingDetailsScreen extends ConsumerStatefulWidget {
  const BookingDetailsScreen({super.key});

  @override
  ConsumerState<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  bool _isUpdatingStatus = false; // Prevent multiple status update clicks

  // Dynamic Status updater API with custom OTP payload for completion clearances
  Future<void> _changeStatus(
    String bookingId,
    String status, {
    String? otpCode,
  }) async {
    if (_isUpdatingStatus) return; // Prevent multiple clicks

    setState(() {
      _isUpdatingStatus = true;
    });

    final ok = await ref.read(bookingProvider.notifier).updateBookingStatus(
          bookingId: bookingId,
          status: status,
          otp: otpCode, // Pass custom OTP to riverpod notifier
        );

    if (!mounted) return;

    setState(() {
      _isUpdatingStatus = false;
    });

    final error = ref.read(bookingProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Status successfully updated' : (error ?? 'Update failed'))),
    );
  }

  // 🔥 PROVIDER COMPLETION INPUT DIALOG BOX
  // Provider must enter customer 4-digit code to complete the job
  Future<void> _showOtpDialog(String bookingId) async {
    final codeController = TextEditingController();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Verify Job Completion', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please ask the customer for their 4-digit Job Clearance Code and enter it below:',
                style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '4-Digit OTP Code',
                  hintText: '1234',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final digits = codeController.text.trim();
                if (digits.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('OTP must be exactly 4 digits')),
                  );
                  return;
                }
                Navigator.pop(context);
                
                // Submit update sequence trigger directly
                _changeStatus(bookingId, 'completed', otpCode: digits);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Verify & Finish', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addReview(String providerId, String bookingId) async {
    ref.read(reviewRatingProvider(providerId).notifier).state = 5;

    await showDialog<bool>(
      context: context,
      builder: (context) => ReviewDialog(providerId: providerId, bookingId: bookingId),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep socket event controller alive for real-time updates
    ref.watch(socketEventProvider);
    
    final booking = ref.watch(bookingProvider).currentBooking;
    final loading = ref.watch(bookingProvider).isLoading;
    final isProvider = ref.watch(authProvider).user?.isProvider == true;
    final isUpdating = loading || _isUpdatingStatus; // Combined loading state

    if (booking == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Booking')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    final otherName = isProvider
        ? (booking.customerData?['name'] ?? 'Customer')
        : (booking.providerData?['name'] ?? 'Provider');
    final otherPhone = isProvider
        ? (booking.customerData?['phone'] ?? '-')
        : (booking.providerData?['phone'] ?? '-');
    final profile = isProvider
        ? (booking.customerData?['profileImage'] ?? '')
        : (booking.providerData?['profileImage'] ?? '');

    String getProfileUrl(String imageUrl) {
      if (imageUrl.isEmpty) return '';
      String url = imageUrl;
      if (!url.startsWith('http')) {
        final base = ApiConstants.socketBaseUrl;
        if (url.startsWith('/')) {
          url = '$base$url';
        } else {
          url = '$base/$url';
        }
      }
      return url;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: Column(
          children: [
            AppBar(title: const Text('Booking details')),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: profile.isNotEmpty
                                    ? Image.network(
                                        getProfileUrl(profile),
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.person, size: 20);
                                        },
                                      )
                                    : const Icon(Icons.person, size: 20),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor(booking.status).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor(booking.status).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(booking.status),
                                    size: 14,
                                    color: statusColor(booking.status),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    booking.status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor(booking.status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // 💰 PRICE SNAPSHOT INFORMATION CARD
                        InfoRow(
                          icon: Icons.payments_outlined,
                          label: 'Agreed Price (Snapshot)',
                          value: 'Rs. ${booking.bookedPrice.toStringAsFixed(0)}',
                          iconBackgroundColor: Colors.teal.withValues(alpha: 0.1),
                          iconColor: Colors.teal[700],
                        ),
                        const SizedBox(height: 16),
                        
                        InfoRow(
                          icon: Icons.category,
                          label: 'Service',
                          value: booking.categoryName,
                          iconBackgroundColor: Colors.blue.withValues(alpha: 0.1),
                          iconColor: Colors.blue[700],
                        ),
                        const SizedBox(height: 16),
                        InfoRow(
                          icon: Icons.person,
                          label: isProvider ? 'Customer' : 'Provider',
                          value: otherName,
                          iconBackgroundColor: Colors.blue.withValues(alpha: 0.1),
                          iconColor: Colors.blue[700],
                        ),
                        const SizedBox(height: 16),
                        InfoRow(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: otherPhone,
                          iconBackgroundColor: Colors.blue.withValues(alpha: 0.1),
                          iconColor: Colors.blue[700],
                        ),
                        const SizedBox(height: 16),
                        InfoRow(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: formatDate(booking.bookingDate),
                          iconBackgroundColor: Colors.blue.withValues(alpha: 0.1),
                          iconColor: Colors.blue[700],
                        ),
                        const SizedBox(height: 16),
                        InfoRow(
                          icon: Icons.location_on,
                          label: 'Address',
                          value: booking.address,
                          iconBackgroundColor: Colors.blue.withValues(alpha: 0.1),
                          iconColor: Colors.blue[700],
                        ),
                      ],
                    ),
                  ),
                  
                  // 🔒 CUSTOMER SIDE SECURE OTP DISCHARGE BOX
                  if (!isProvider && booking.status == 'accepted' && booking.completionOtp != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield_outlined, color: Colors.teal[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Secure Job Clearance Code',
                                style: TextStyle(color: Colors.teal[900], fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            booking.completionOtp!,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[800],
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '⚠️ Provider ko yeh code sirf tab dein jab aapka kaam tasallibakhsh mukammal ho jaye!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  
                  // PROVIDER CORE CONTROLS ACTION PANEL
                  if (isProvider && booking.status == 'pending') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isUpdating
                            ? null
                            : () => _changeStatus(booking.id, 'accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: isUpdating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Accept Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: isUpdating
                            ? null
                            : () => _changeStatus(booking.id, 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red[700]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isUpdating
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.red[700], strokeWidth: 2.5),
                              )
                            : const Text('Reject Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                  
                  // Provider completion hit links through security entry dialog instead of direct call
                  if (isProvider && booking.status == 'accepted')
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isUpdating
                            ? null
                            : () => _showOtpDialog(booking.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: isUpdating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Mark as Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    
                  // CUSTOMER ACTION PANEL
                  if (!isProvider && booking.status == 'pending')
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: isUpdating
                            ? null
                            : () => _changeStatus(booking.id, 'cancelled'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange[700],
                          side: BorderSide(color: Colors.orange[700]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isUpdating
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.orange[700], strokeWidth: 2.5),
                              )
                            : const Text('Cancel Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (!isProvider && booking.status == 'completed' && !booking.isReviewed)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _addReview(booking.providerId, booking.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: const Text('Leave Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  
                  if (!isProvider && booking.status == 'completed' && booking.isReviewed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stars_rounded, color: Colors.amber[800], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Thank you! Your review has been submitted.',
                            style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
