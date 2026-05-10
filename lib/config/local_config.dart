import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/app_exceptions.dart';

class LocalConfig {
  static const String _defaultAdminEmail = 'admin.bped.dev@gmail.com';

  static String? _supabaseUrl;
  static String? _supabaseAnonKey;
  static String? _adminEmail;
  static String? _emailJsServiceId;
  static String? _emailJsTemplateId;
  static String? _emailJsPublicKey;

  /// Validates and caches runtime configuration loaded from .env.
  static void initialize() {
    _supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
    _supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();
    _adminEmail =
        dotenv.env['ADMIN_EMAIL']?.trim().toLowerCase() ?? _defaultAdminEmail;
    _emailJsServiceId = dotenv.env['EMAILJS_SERVICE_ID']?.trim() ?? '';
    _emailJsTemplateId = dotenv.env['EMAILJS_TEMPLATE_ID']?.trim() ?? '';
    _emailJsPublicKey = dotenv.env['EMAILJS_PUBLIC_KEY']?.trim() ?? '';

    if (_supabaseUrl == null || _supabaseUrl!.isEmpty) {
      throw ConfigurationException(
        'SUPABASE_URL is missing from .env',
        code: 'missing_config',
      );
    }
    if (_supabaseAnonKey == null || _supabaseAnonKey!.isEmpty) {
      throw ConfigurationException(
        'SUPABASE_ANON_KEY is missing from .env',
        code: 'missing_config',
      );
    }
  }

  static String get supabaseUrl {
    if (_supabaseUrl == null) {
      throw ConfigurationException('Config not initialized');
    }
    return _supabaseUrl!;
  }

  static String get supabaseAnonKey {
    if (_supabaseAnonKey == null) {
      throw ConfigurationException('Config not initialized');
    }
    return _supabaseAnonKey!;
  }

  static String get adminEmail {
    if (_adminEmail == null) {
      throw ConfigurationException('Config not initialized');
    }
    return _adminEmail!;
  }

  static String get emailJsServiceId {
    if (_emailJsServiceId == null) {
      throw ConfigurationException('Config not initialized');
    }
    return _emailJsServiceId!;
  }

  static String get emailJsTemplateId {
    if (_emailJsTemplateId == null) {
      throw ConfigurationException('Config not initialized');
    }
    return _emailJsTemplateId!;
  }

  static String get emailJsPublicKey {
    if (_emailJsPublicKey == null) {
      throw ConfigurationException('Config not initialized');
    }
    return _emailJsPublicKey!;
  }

  static bool get isEmailJsConfigured =>
      emailJsServiceId.isNotEmpty &&
      emailJsTemplateId.isNotEmpty &&
      emailJsPublicKey.isNotEmpty;
}
