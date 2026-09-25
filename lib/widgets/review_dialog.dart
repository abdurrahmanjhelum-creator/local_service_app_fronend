import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../providers/ui_state_provider.dart';
import '../screens/navigation_bar_screen.dart';
import '../services/service_api.dart';
import '../utils/helpers.dart';

class ReviewDialog extends ConsumerStatefulWidget {
  final String providerId;
  final String bookingId; // 🔥 New parameter

  const ReviewDialog({super.key, required this.providerId, required this.bookingId});

  @override
  ConsumerState<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<ReviewDialog> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    try {
      final rating = ref.read(reviewRatingProvider(widget.providerId));
      await ServiceApi().addReview(
        provider: widget.providerId,
        rating: rating,
        comment: _commentController.text.trim(),
        bookingId: widget.bookingId, 
      );
      
      // 🔥 1. FORCED LOCAL UPDATE: Hide the button immediately by updating the current booking object in memory
      final currentBooking = ref.read(bookingProvider).currentBooking;
      if (currentBooking != null && currentBooking.id == widget.bookingId) {
        final manuallyUpdated = BookingModel(
          id: currentBooking.id,
          customerId: currentBooking.customerId,
          providerId: currentBooking.providerId,
          categoryName: currentBooking.categoryName,
          bookingDate: currentBooking.bookingDate,
          address: currentBooking.address,
          status: currentBooking.status,
          createdAt: currentBooking.createdAt,
          bookedPrice: currentBooking.bookedPrice,
          isReviewed: true, // This will hide the button instantly
          completionOtp: currentBooking.completionOtp,
          customerData: currentBooking.customerData,
          providerData: currentBooking.providerData,
        );
        ref.read(bookingProvider.notifier).setCurrentBooking(manuallyUpdated);
      }
      
      // 2. BACKGROUND SYNC: Refresh the full bookings list from server
      await ref.read(bookingProvider.notifier).loadBookings();

      if (mounted) {
        ref.read(selectedTabProvider('root').notifier).state = 0;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const NavigationBarScreen(),
          ),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cleanError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = ref.watch(reviewRatingProvider(widget.providerId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.rate_review, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Leave a review',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Rate your experience',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          ref.read(reviewRatingProvider(widget.providerId).notifier).state = index + 1;
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            size: 36,
                            color: index < rating ? Colors.amber : Colors.grey[400],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$rating star${rating != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 4,
              maxLength: 200,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Submit Review',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
