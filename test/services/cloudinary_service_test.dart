import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phys_ed/providers/supabase_storage_provider.dart';

void main() {
  group('SupabaseStorageService', () {
    final service = SupabaseStorageService();

    test('detects file MIME types from filenames and bytes', () {
      expect(service.detectMimeType(filename: 'lesson.pdf'), 'application/pdf');
      expect(
        service.detectMimeType(
          filename: 'clip.mp4',
          bytes: Uint8List.fromList(const [0, 0, 0, 0]),
        ),
        startsWith('video/'),
      );
    });

    test('classifies PDF and video MIME types', () {
      expect(service.isPdfMimeType('application/pdf'), isTrue);
      expect(service.isPdfMimeType('video/mp4'), isFalse);
      expect(service.isVideoMimeType('video/mp4'), isTrue);
      expect(service.isVideoMimeType('application/pdf'), isFalse);
    });

    test('reports configuration state without throwing', () {
      expect(service.isConfigured, isA<bool>());
    });
  });
}
