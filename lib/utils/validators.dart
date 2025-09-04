import 'package:soil_app/const.dart';

/// Utility class containing validation functions for various input fields
class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  /// Email validation
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }

    final trimmedEmail = email.trim();

    // Basic email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmedEmail)) {
      return 'Please enter a valid email address';
    }

    // Check for common invalid patterns
    if (trimmedEmail.contains('..') ||
        trimmedEmail.startsWith('.') ||
        trimmedEmail.endsWith('.')) {
      return 'Please enter a valid email address';
    }

    // Check length constraints
    if (trimmedEmail.length > 254) {
      return 'Email address is too long';
    }

    return null;
  }

  /// Password validation
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters long';
    }

    if (password.length > AppConstants.maxPasswordLength) {
      return 'Password must be less than ${AppConstants.maxPasswordLength} characters long';
    }

    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Confirm password validation
  static String? validateConfirmPassword(String? confirmPassword, String? password) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (confirmPassword != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Display name validation
  static String? validateDisplayName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) {
      return 'Display name is required';
    }

    final trimmedName = displayName.trim();

    if (trimmedName.length < 2) {
      return 'Display name must be at least 2 characters long';
    }

    if (trimmedName.length > 50) {
      return 'Display name must be less than 50 characters long';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(trimmedName)) {
      return 'Display name can only contain letters, spaces, hyphens, and apostrophes';
    }

    // Check for consecutive spaces
    if (trimmedName.contains(RegExp(r'\s{2,}'))) {
      return 'Display name cannot contain consecutive spaces';
    }

    return null;
  }

  /// Phone number validation (optional field)
  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return null; // Phone number is optional
    }

    final trimmedPhone = phoneNumber.trim();

    // Remove all non-digit characters for validation
    final digitsOnly = trimmedPhone.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (digitsOnly.length > 15) {
      return 'Phone number must be less than 15 digits';
    }

    // Basic phone number pattern (supports international formats)
    final phoneRegex = RegExp(r'^[\+]?[0-9\-\(\)\s]+$');
    if (!phoneRegex.hasMatch(trimmedPhone)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Device name validation
  static String? validateDeviceName(String? deviceName) {
    if (deviceName == null || deviceName.trim().isEmpty) {
      return 'Device name is required';
    }

    final trimmedName = deviceName.trim();

    if (trimmedName.length < 2) {
      return 'Device name must be at least 2 characters long';
    }

    if (trimmedName.length > 30) {
      return 'Device name must be less than 30 characters long';
    }

    // Allow letters, numbers, spaces, hyphens, underscores
    if (!RegExp(r'^[a-zA-Z0-9\s\-_]+$').hasMatch(trimmedName)) {
      return 'Device name can only contain letters, numbers, spaces, hyphens, and underscores';
    }

    return null;
  }

  /// Temperature validation
  static String? validateTemperature(String? temperature) {
    if (temperature == null || temperature.trim().isEmpty) {
      return 'Temperature is required';
    }

    final temp = double.tryParse(temperature.trim());
    if (temp == null) {
      return 'Please enter a valid temperature';
    }

    if (temp < AppConstants.minTemperature || temp > AppConstants.maxTemperature) {
      return 'Temperature must be between ${AppConstants.minTemperature}°C and ${AppConstants.maxTemperature}°C';
    }

    return null;
  }

  /// Moisture validation
  static String? validateMoisture(String? moisture) {
    if (moisture == null || moisture.trim().isEmpty) {
      return 'Moisture is required';
    }

    final moist = double.tryParse(moisture.trim());
    if (moist == null) {
      return 'Please enter a valid moisture percentage';
    }

    if (moist < AppConstants.minMoisture || moist > AppConstants.maxMoisture) {
      return 'Moisture must be between ${AppConstants.minMoisture}% and ${AppConstants.maxMoisture}%';
    }

    return null;
  }

  /// Bluetooth address validation
  static String? validateBluetoothAddress(String? address) {
    if (address == null || address.trim().isEmpty) {
      return 'Bluetooth address is required';
    }

    final trimmedAddress = address.trim().toUpperCase();

    // Standard Bluetooth MAC address format: XX:XX:XX:XX:XX:XX
    final bluetoothRegex = RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$');

    if (!bluetoothRegex.hasMatch(trimmedAddress)) {
      return 'Please enter a valid Bluetooth address (XX:XX:XX:XX:XX:XX)';
    }

    return null;
  }

  /// Generic required field validation
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Numeric input validation
  static String? validateNumeric(String? value, {
    String fieldName = 'Value',
    double? min,
    double? max,
    bool allowDecimals = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final number = allowDecimals
        ? double.tryParse(value.trim())
        : int.tryParse(value.trim())?.toDouble();

    if (number == null) {
      return 'Please enter a valid ${allowDecimals ? 'number' : 'whole number'}';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }

    return null;
  }

  /// URL validation
  static String? validateUrl(String? url, {bool requireHttps = false}) {
    if (url == null || url.trim().isEmpty) {
      return null; // URL is optional unless specified otherwise
    }

    final trimmedUrl = url.trim();

    try {
      final uri = Uri.parse(trimmedUrl);

      if (!uri.hasScheme) {
        return 'URL must include protocol (http:// or https://)';
      }

      if (requireHttps && uri.scheme.toLowerCase() != 'https') {
        return 'URL must use HTTPS protocol';
      }

      if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
        return 'URL must use HTTP or HTTPS protocol';
      }

      if (uri.host.isEmpty) {
        return 'Please enter a valid URL';
      }

      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }

  /// Text length validation
  static String? validateTextLength(String? text, {
    required int minLength,
    required int maxLength,
    String fieldName = 'Text',
  }) {
    if (text == null || text.trim().isEmpty) {
      if (minLength > 0) {
        return '$fieldName is required';
      }
      return null;
    }

    final trimmedText = text.trim();

    if (trimmedText.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }

    if (trimmedText.length > maxLength) {
      return '$fieldName must be less than $maxLength characters long';
    }

    return null;
  }

  /// Date validation
  static String? validateDate(String? dateString, {
    DateTime? minDate,
    DateTime? maxDate,
    String fieldName = 'Date',
  }) {
    if (dateString == null || dateString.trim().isEmpty) {
      return '$fieldName is required';
    }

    try {
      final date = DateTime.parse(dateString.trim());

      if (minDate != null && date.isBefore(minDate)) {
        return '$fieldName cannot be before ${minDate.toLocal().toString().split(' ')[0]}';
      }

      if (maxDate != null && date.isAfter(maxDate)) {
        return '$fieldName cannot be after ${maxDate.toLocal().toString().split(' ')[0]}';
      }

      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  /// Combine multiple validators
  static String? combineValidators(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// Custom validation with regex
  static String? validateWithRegex(String? value, RegExp regex, String errorMessage) {
    if (value == null || value.trim().isEmpty) {
      return null; // Let required validator handle empty values
    }

    if (!regex.hasMatch(value.trim())) {
      return errorMessage;
    }

    return null;
  }

  /// Helper method to check if email domain is commonly used
  static bool isCommonEmailDomain(String email) {
    final commonDomains = [
      'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com',
      'icloud.com', 'protonmail.com', 'aol.com', 'live.com'
    ];

    final domain = email.split('@').last.toLowerCase();
    return commonDomains.contains(domain);
  }

  /// Helper method to check password strength
  static PasswordStrength getPasswordStrength(String password) {
    int score = 0;

    // Length
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;

    // Character types
    if (password.contains(RegExp(r'[a-z]'))) score += 1;
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    if (password.contains(RegExp(r'[0-9]'))) score += 1;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 1;

    // Complexity
    if (password.length >= 16) score += 1;
    if (RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*])').hasMatch(password)) {
      score += 1;
    }

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }
}

/// Enum for password strength levels
enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong;

  String get description {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  String get color {
    switch (this) {
      case PasswordStrength.weak:
        return '#FF0000'; // Red
      case PasswordStrength.medium:
        return '#FFA500'; // Orange
      case PasswordStrength.strong:
        return '#008000'; // Green
      case PasswordStrength.veryStrong:
        return '#006400'; // Dark Green
    }
  }
}