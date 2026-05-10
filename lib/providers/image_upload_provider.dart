import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_storage_provider.dart';

final imageUploadProvider =
    StateNotifierProvider<ImageUploadNotifier, AsyncValue<String?>>((ref) {
      final storage = ref.read(supabaseStorageProvider);
      return ImageUploadNotifier(storage);
    });

class ImageUploadNotifier extends StateNotifier<AsyncValue<String?>> {
  final FileUploadService _storage;

  ImageUploadNotifier(this._storage) : super(const AsyncValue.data(null));

  Future<String> upload(File file) async {
    state = const AsyncValue.loading();
    try {
      final url = await _storage.uploadImage(
        file,
        bucketOverride: StorageBuckets.avatars,
      );
      state = AsyncValue.data(url);
      return url;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<String> uploadBytes(
    Uint8List bytes, {
    String filename = 'avatar.jpg',
  }) async {
    state = const AsyncValue.loading();
    try {
      final url = await _storage.uploadFileBytes(
        bytes,
        filename,
        bucketOverride: StorageBuckets.avatars,
      );
      state = AsyncValue.data(url);
      return url;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
