class IntegrationConfig {
  static const String emailJsServiceId = String.fromEnvironment(
    'EMAILJS_SERVICE_ID',
  );
  static const String emailJsTemplateId = String.fromEnvironment(
    'EMAILJS_TEMPLATE_ID',
  );
  static const String emailJsPublicKey = String.fromEnvironment(
    'EMAILJS_PUBLIC_KEY',
  );

  static bool get isEmailJsConfigured =>
      emailJsServiceId.isNotEmpty &&
      emailJsTemplateId.isNotEmpty &&
      emailJsPublicKey.isNotEmpty;
}
