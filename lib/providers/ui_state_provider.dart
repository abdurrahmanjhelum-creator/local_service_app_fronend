import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';

import '../models/review_model.dart';
import '../models/user_model.dart';

// Riverpod stores transient screen values that were previously changed with setState.
final registerRoleProvider = StateProvider.autoDispose.family<String, String>(
  (ref, key) => 'customer',
);
final registerCategoryProvider = StateProvider.autoDispose.family<String?, String>(
  (ref, key) => null,
);
final registerImageProvider = StateProvider.autoDispose.family<XFile?, String>(
  (ref, key) => null,
);

final editCategoryProvider = StateProvider.autoDispose.family<String?, String>(
  (ref, key) => null,
);
final editImageProvider = StateProvider.autoDispose.family<XFile?, String>(
  (ref, key) => null,
);
final editAvailabilityProvider = StateProvider.autoDispose.family<bool, String>(
  (ref, key) => true,
);

final bookingDateProvider = StateProvider.autoDispose.family<DateTime, String>(
  (ref, key) => DateTime.now().add(const Duration(hours: 2)),
);

final servicesSearchProvider = StateProvider.autoDispose.family<String, String>(
  (ref, key) => '',
);
final servicesCategoryProvider = StateProvider.autoDispose.family<String?, String>(
  (ref, key) => null,
);

class ProviderDetailsUiState {
  final UserModel? provider;
  final List<ReviewModel> reviews;
  final bool isLoading;
  final String? error;

  const ProviderDetailsUiState({
    this.provider,
    this.reviews = const [],
    this.isLoading = true,
    this.error,
  });
}

final providerDetailsStateProvider =
    StateProvider.autoDispose.family<ProviderDetailsUiState, String>(
  (ref, providerId) => const ProviderDetailsUiState(),
);

final selectedTabProvider = StateProvider.autoDispose.family<int, String>(
  (ref, key) => 0,
);
final reviewRatingProvider = StateProvider.autoDispose.family<int, String>(
  (ref, key) => 5,
);
final passwordVisibilityProvider = StateProvider.autoDispose.family<bool, String>(
  (ref, key) => true,
);
