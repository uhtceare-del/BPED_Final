import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase/supabase.dart' as supabase;

import '../config/local_config.dart';
import '../core/app_exceptions.dart';
import '../core/error_handler.dart';
import '../core/retry_helper.dart';

final supabaseStorageProvider = Provider<FileUploadService>((ref) {
  return SupabaseStorageService();
});

abstract class FileUploadService {
  bool get isConfigured;

  String? detectMimeType({
    String? filename,
    Uint8List? bytes,
    String? filePath,
  });

  bool isPdfMimeType(String? mimeType);
  bool isVideoMimeType(String? mimeType);

  Future<String> uploadFile(String filePath, {String? bucketOverride});

  Future<String> uploadImage(File file, {String? bucketOverride});

  Future<String> uploadFileBytes(
    Uint8List bytes,
    String filename, {
    String? bucketOverride,
  });
}

final class StorageBuckets {
  static const documents = 'documents';
  static const media = 'media';
  static const avatars = 'avatars';

  const StorageBuckets._();
}

class SupabaseStorageService implements FileUploadService {
  supabase.SupabaseClient? _client;

  @override
  bool get isConfigured {
    try {
      return _resolveUrl().isNotEmpty && _resolveAnonKey().isNotEmpty;
    } on ConfigurationException {
      return false;
    }
  }

  supabase.SupabaseClient _getClient() {
    final existing = _client;
    if (existing != null) {
      return existing;
    }

    final url = _resolveUrl();
    final anonKey = _resolveAnonKey();
    if (url.isEmpty || anonKey.isEmpty) {
      throw const ConfigurationException(
        'Supabase not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY in .env file.',
        code: 'config-missing',
      );
    }

    final client = supabase.SupabaseClient(url, anonKey);
    _client = client;
    return client;
  }

  String _resolveUrl() {
    return LocalConfig.supabaseUrl.trim();
  }

  String _resolveAnonKey() {
    return LocalConfig.supabaseAnonKey.trim();
  }

  @override
  String? detectMimeType({
    String? filename,
    Uint8List? bytes,
    String? filePath,
  }) {
    return lookupMimeType(filePath ?? filename ?? '', headerBytes: bytes);
  }

  @override
  bool isPdfMimeType(String? mimeType) => mimeType == 'application/pdf';

  @override
  bool isVideoMimeType(String? mimeType) =>
      mimeType != null && mimeType.startsWith('video/');

  String _bucketForMimeType(String? mimeType) {
    if (isPdfMimeType(mimeType)) {
      return StorageBuckets.documents;
    }
    return StorageBuckets.media;
  }

  @override
  Future<String> uploadFile(String filePath, {String? bucketOverride}) {
    return _uploadWithRetry(
      filePath: filePath,
      bytes: null,
      filename: p.basename(filePath),
      bucketOverride: bucketOverride,
    );
  }

  @override
  Future<String> uploadImage(File file, {String? bucketOverride}) {
    return uploadFile(file.path, bucketOverride: bucketOverride);
  }

  @override
  Future<String> uploadFileBytes(
    Uint8List bytes,
    String filename, {
    String? bucketOverride,
  }) {
    return _uploadWithRetry(
      filePath: null,
      bytes: bytes,
      filename: filename,
      bucketOverride: bucketOverride,
    );
  }

  Future<String> _uploadWithRetry({
    String? filePath,
    Uint8List? bytes,
    required String filename,
    String? bucketOverride,
  }) async {
    try {
      return await RetryHelper.retry(
        () => _upload(filePath, bytes, filename, bucketOverride),
        maxAttempts: 3,
        shouldRetry: (error) =>
            error is NetworkException || error is FileStorageException,
      );
    } catch (error) {
      final appError = error is AppException
          ? error
          : ErrorHandler.handleFirebaseException(error, context: 'File upload');
      ErrorHandler.logError(appError, context: 'SupabaseStorageService.upload');
      throw appError;
    }
  }

  Future<String> _upload(
    String? filePath,
    Uint8List? bytes,
    String filename,
    String? bucketOverride,
  ) async {
    final client = _getClient();
    final mimeType = detectMimeType(
      filename: filename,
      bytes: bytes,
      filePath: filePath,
    );
    final bucket = bucketOverride ?? _bucketForMimeType(mimeType);
    final objectPath =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(filename)}';
    final fileOptions = supabase.FileOptions(
      upsert: true,
      contentType: mimeType,
    );

    try {
      if (filePath != null) {
        await client.storage
            .from(bucket)
            .upload(objectPath, File(filePath), fileOptions: fileOptions);
      } else if (bytes != null) {
        await client.storage
            .from(bucket)
            .uploadBinary(objectPath, bytes, fileOptions: fileOptions);
      } else {
        throw const ValidationException(
          'No file payload was provided for upload.',
        );
      }

      return client.storage.from(bucket).getPublicUrl(objectPath);
    } on supabase.StorageException catch (error) {
      throw FileStorageException(
        'Supabase upload failed for bucket "$bucket": ${error.message}',
        code: error.statusCode?.toString(),
        originalError: error,
      );
    } catch (error) {
      throw ErrorHandler.handleFirebaseException(
        error,
        context: 'Supabase upload',
      );
    }
  }
}
