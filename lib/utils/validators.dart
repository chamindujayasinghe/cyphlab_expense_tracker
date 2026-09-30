import 'constants.dart';

/// Form validators: return an error message, or null when valid.
class Validators {
  Validators._();

  static final RegExp _amountPattern = RegExp(r'^\d+(\.\d{1,2})?$');
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? title(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter a title';
    if (text.length > AppConstants.titleMaxLength) {
      return 'Title must be ${AppConstants.titleMaxLength} characters or less';
    }
    return null;
  }

  static String? amount(String? value) {
    final text = value?.trim().replaceAll(',', '') ?? '';
    if (text.isEmpty) return 'Please enter an amount';
    if (!_amountPattern.hasMatch(text)) {
      return 'Enter a valid amount (up to 2 decimal places)';
    }
    final amount = double.parse(text);
    if (amount <= 0) return 'Amount must be greater than zero';
    if (amount > AppConstants.maxAmount) return 'Amount is too large';
    return null;
  }

  /// Parses a validated amount, allowing commas (e.g. `1,250.50`).
  static double parseAmount(String value) =>
      double.parse(value.trim().replaceAll(',', ''));

  static String? note(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > AppConstants.noteMaxLength) {
      return 'Note must be ${AppConstants.noteMaxLength} characters or less';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter your email';
    if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Please enter your password';
    if (text.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
