import 'package:flutter/material.dart';
import 'api_constants.dart';
import 'app_colors.dart';

const defaultCategories = [
  'Electrician',
  'Plumber',
  'AC Repair',
  'Carpenter',
  'Painter',
  'Cleaner',
];

String formatDate(String value) {
  try {
    final date = DateTime.parse(value).toLocal();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hour:$minute';
  } catch (_) {
    return value;
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.warning;
    case 'accepted':
      return AppColors.success;
    case 'rejected':
    case 'cancelled':
      return AppColors.error;
    case 'completed':
      return AppColors.info;
    default:
      return AppColors.gray500;
  }
}

String cleanError(Object error) {
  return error.toString().replaceAll('Exception: ', '');
}

Widget userAvatar(String imageUrl, {double radius = 32}) {
  if (imageUrl.isEmpty) {
    return CircleAvatar(
      radius: radius,
      child: Icon(Icons.person, size: radius * 0.8),
    );
  }

  String url = imageUrl;
  if (!url.startsWith('http')) {
    final base = ApiConstants.baseUrl.replaceAll('/api', '');
    if (url.startsWith('/')) {
      url = '$base$url';
    } else {
      url = '$base/$url';
    }
  }

  return CircleAvatar(
    radius: radius,
    backgroundColor: AppColors.gray200,
    child: ClipOval(
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.person,
            size: radius * 0.8,
            color: AppColors.gray500,
          );
        },
      ),
    ),
  );
}
