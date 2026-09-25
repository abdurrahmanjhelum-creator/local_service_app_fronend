import 'dart:core';

/// Comprehensive Input Validation Utilities
class InputValidator {
  // Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Password Validation
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Name Validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  // Phone Validation
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]{10,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // Address Validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 10) {
      return 'Address must be at least 10 characters';
    }
    if (value.trim().length > 200) {
      return 'Address must be less than 200 characters';
    }
    return null;
  }

  // Category Validation
  static String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category is required';
    }
    return null;
  }

  // Price Validation
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }
    if (price < 0) {
      return 'Price cannot be negative';
    }
    if (price > 1000000) {
      return 'Price is too high';
    }
    return null;
  }

  // Experience Validation
  static String? validateExperience(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Experience is required';
    }
    final experience = int.tryParse(value);
    if (experience == null) {
      return 'Please enter a valid number';
    }
    if (experience < 0) {
      return 'Experience cannot be negative';
    }
    if (experience > 50) {
      return 'Experience cannot exceed 50 years';
    }
    return null;
  }

  // OTP Validation
  static String? validateOTP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    final otpRegex = RegExp(r'^\d{4,6}$');
    if (!otpRegex.hasMatch(value.trim())) {
      return 'OTP must be 4-6 digits';
    }
    return null;
  }

  // Comment Validation
  static String? validateComment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Comment is required';
    }
    if (value.trim().length < 10) {
      return 'Comment must be at least 10 characters';
    }
    if (value.trim().length > 500) {
      return 'Comment must be less than 500 characters';
    }
    return null;
  }

  // Generic Required Field Validation
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Sanitize Input (XSS Prevention)
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'javascript:'), '') // Remove javascript: protocol
        .replaceAll(RegExp(r'on\w+\s*='), '') // Remove event handlers
        .trim();
  }

  // Validate URL
  static String? validateURL(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL is required';
    }
    final urlRegex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }
    return null;
  }
}
