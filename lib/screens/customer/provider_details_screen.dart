import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../services/service_api.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/info_row.dart';
import 'create_booking_screen.dart';
import '../shared/chat_screen.dart';

class ProviderDetailsScreen extends ConsumerStatefulWidget {
  final String providerId;

  const ProviderDetailsScreen({super.key, required this.providerId});

  @override
  ConsumerState<ProviderDetailsScreen> createState() =>
      _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends ConsumerState<ProviderDetailsScreen> {
  final _api = ServiceApi();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stateProvider = providerDetailsStateProvider(widget.providerId).notifier;
    try {
      final provider = await _api.getProvider(widget.providerId);
      final reviews = await _api.getReviews(widget.providerId);
      ref.read(stateProvider).state = ProviderDetailsUiState(
        provider: provider,
        reviews: reviews,
        isLoading: false,
      );
    } catch (e) {
      ref.read(stateProvider).state = ProviderDetailsUiState(
        isLoading: false,
        error: cleanError(e),
      );
    }
  }

  Future<void> _startChat(BuildContext context, dynamic provider, user) async {
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to message providers')),
        );
      }
      return;
    }

    try {
      // Get or create conversation with the provider
      await ref.read(chatProvider.notifier).getOrCreateConversation(
        customerId: user.id,
        customerName: user.name,
        customerProfileImage: user.profileImage,
        providerId: provider.id,
        providerName: provider.name,
        providerProfileImage: provider.profileImage,
      );

      // Navigate to chat screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversation: ref.read(chatProvider).currentConversation,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: ${cleanError(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final details = ref.watch(providerDetailsStateProvider(widget.providerId));
    final provider = details.provider;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: Column(
          children: [
            AppBar(title: const Text('Provider')),
            Expanded(
              child: details.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : details.error != null || provider == null
                      ? Center(child: Text(details.error ?? 'Provider not found'))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                    Center(child: userAvatar(provider.profileImage, radius: 50)),
                    const SizedBox(height: 16),
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
                        children: [
                          Text(
                            provider.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CategoryIcon(
                                category: provider.category,
                                size: 16,
                                useContainer: false,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                provider.category.isEmpty
                                    ? 'Service provider'
                                    : provider.category,
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          InfoRow(
                            icon: Icons.phone,
                            label: 'Phone',
                            value: provider.phone,
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.attach_money,
                            label: 'Starting price',
                            value: 'Rs ${provider.priceStarting.toStringAsFixed(0)}',
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.work_history,
                            label: 'Experience',
                            value: '${provider.experienceYears} years',
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.star,
                            label: 'Rating',
                            value: '${provider.rating}',
                            isRating: true,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                provider.isAvailable
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: provider.isAvailable
                                    ? Colors.green
                                    : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                provider.isAvailable
                                    ? 'Available now'
                                    : 'Not available',
                                style: TextStyle(
                                  color: provider.isAvailable
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (user?.isProvider == true)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Login as a customer to book this provider.',
                                style: TextStyle(color: Colors.orange[700]),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreateBookingScreen(provider: provider),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'Book now',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => _startChat(context, provider, user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'Message',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),
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
                              Icon(Icons.reviews, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              const Text(
                                'Reviews',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (details.reviews.isEmpty)
                            Center(
                              child: Text(
                                'No reviews yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          else
                            SizedBox(
                              height: 145,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: details.reviews.length,
                                itemBuilder: (context, index) {
                                  final review = details.reviews[index];
                                  return Container(
                                    width: 280,
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.person, size: 16),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                review.customerName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    size: 14,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${review.rating}/5',
                                                    style: const TextStyle(
                                                      color: Colors.amber,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Expanded(
                                          child: Text(
                                            review.comment.isEmpty
                                                ? 'No comment'
                                                : review.comment,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
      ),
    );
  }
}
