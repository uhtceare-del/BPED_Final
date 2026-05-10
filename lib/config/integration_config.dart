import 'local_config.dart';

class IntegrationConfig {
  static String get emailJsServiceId {
    try {
      return LocalConfig.emailJsServiceId;
    } catch (_) {
      return '';
    }
  }

  static String get emailJsTemplateId {
    try {
      return LocalConfig.emailJsTemplateId;
    } catch (_) {
      return '';
    }
  }

  static String get emailJsPublicKey {
    try {
      return LocalConfig.emailJsPublicKey;
    } catch (_) {
      return '';
    }
  }

  static bool get isEmailJsConfigured =>
      emailJsServiceId.isNotEmpty &&
      emailJsTemplateId.isNotEmpty &&
      emailJsPublicKey.isNotEmpty;
}
