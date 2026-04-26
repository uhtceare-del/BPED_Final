import 'package:flutter_test/flutter_test.dart';
import 'package:phys_ed/config/integration_config.dart';

void main() {
  group('IntegrationConfig', () {
    test('defaults to empty EmailJS values in test environment', () {
      expect(IntegrationConfig.emailJsServiceId, isEmpty);
      expect(IntegrationConfig.emailJsTemplateId, isEmpty);
      expect(IntegrationConfig.emailJsPublicKey, isEmpty);
      expect(IntegrationConfig.isEmailJsConfigured, isFalse);
    });
  });
}
