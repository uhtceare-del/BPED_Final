class Validator {
  static String? validateEmail(String? email) {
    final normalized = email?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Email is required';
    }

    if (normalized.contains(' ')) {
      return 'Email address must not contain spaces';
    }

    final emailPattern = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );
    if (!emailPattern.hasMatch(normalized)) {
      return 'Enter a valid email address';
    }

    final parts = normalized.split('@');
    if (parts.length != 2) {
      return 'Enter a valid email address';
    }

    final localPart = parts.first;
    final domain = parts.last.toLowerCase();
    if (localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..') ||
        domain.startsWith('.') ||
        domain.endsWith('.') ||
        domain.contains('..')) {
      return 'Enter a valid email address';
    }

    if (domain.startsWith('gmail') && domain != 'gmail.com') {
      return 'If you are using Gmail, the address must end with @gmail.com';
    }

    if (domain == 'gmail.com') {
      final gmailPattern = RegExp(
        r'^[A-Za-z0-9](?:[A-Za-z0-9.]{4,28}[A-Za-z0-9])?$',
      );
      if (!gmailPattern.hasMatch(localPart) || localPart.contains('..')) {
        return 'Enter a valid Gmail address';
      }
    }

    return null;
  }

  static String? validatePassword(String? password) {
    final value = password ?? '';
    if (value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 12) {
      return 'Password must be at least 12 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must include at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must include at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must include at least one number';
    }
    if (!RegExp(
      r'''[!@#$%^&*(),.?":{}|<>_\-\\/\[\]=+;'`~]''',
    ).hasMatch(value)) {
      return 'Password must include at least one special character';
    }
    if (value.contains(' ')) {
      return 'Password must not contain spaces';
    }
    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    return (value == null || value.trim().isEmpty)
        ? '$fieldName is required'
        : null;
  }

  static String? validateFullName(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Full name is required';
    }
    if (!RegExp(r'^[A-Za-z]+(?: [A-Za-z]+)*$').hasMatch(normalized)) {
      return 'Full name must contain letters and spaces only';
    }
    if (normalized.replaceAll(' ', '').length < 2) {
      return 'Full name must contain at least 2 letters';
    }
    return null;
  }
}
