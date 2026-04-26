import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phys_ed/providers/cloudinary_provider.dart';

void main() {
  group('cloudinaryProvider', () {
    test('provides a CloudinaryService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(cloudinaryProvider);

      expect(service, isA<CloudinaryService>());
    });
  });
}
