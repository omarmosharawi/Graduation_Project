class ValidationUtils {
  /// Validates an email address using a strong regular expression.
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Comprehensive email regex
    // final emailRegex = RegExp(
    //   r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    // );
    
    // More robust one often used in production:
    // r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"
    final robustEmailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );

    if (!robustEmailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates a password against strong complexity requirements.
  /// - At least 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  /// - At least one special character
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must contain at least one uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Must contain at least one lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must contain at least one number';
    }
    
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Must contain at least one special character';
    }
    
    return null;
  }

  /// Validates that two passwords match.
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}
