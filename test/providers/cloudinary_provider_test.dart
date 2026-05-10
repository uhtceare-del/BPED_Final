import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phys_ed/providers/supabase_storage_provider.dart';

void main() {
  group('supabaseStorageProvider', () {
    test('provides a FileUploadService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(supabaseStorageProvider);

      expect(service, isA<FileUploadService>());
    });
  });
}
