import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase/supabase.dart' as supabase;

import '../config/local_config.dart';
import '../core/error_handling.dart';

final cloudinaryProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

class CloudinaryService {
  static const String _documentsBucket = 'documents';
  static const String _mediaBucket = 'media';
  static const String avatarsBucket = 'avatars';

  supabase.SupabaseClient? _client;

  bool get isConfigured =>
      _resolveUrl().isNotEmpty && _resolveAnonKey().isNotEmpty;

  supabase.SupabaseClient _getClient() {
    final existing = _client;
    if (existing != null) {
      return existing;
    }

    final url = _resolveUrl();
    final anonKey = _resolveAnonKey();
    if (url.isEmpty || anonKey.isEmpty) {
      throw ConfigurationException(
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

  String? detectMimeType({
    String? filename,
    Uint8List? bytes,
    String? filePath,
  }) {
    return lookupMimeType(filePath ?? filename ?? '', headerBytes: bytes);
  }

  bool isPdfMimeType(String? mimeType) => mimeType == 'application/pdf';

  bool isVideoMimeType(String? mimeType) =>
      mimeType != null && mimeType.startsWith('video/');

  String _bucketForMimeType(String? mimeType) {
    if (isPdfMimeType(mimeType)) {
      return _documentsBucket;
    }
    return _mediaBucket;
  }

  Future<String?> uploadFile(
    String filePath, {
    String? bucketOverride,
  }) async {
    final result = await _uploadWithRetry(
      filePath: filePath,
      bytes: null,
      filename: p.basename(filePath),
      bucketOverride: bucketOverride,
    );

    return result.isSuccess ? result.data : null;
  }

  Future<String?> uploadImage(
    File file, {
    String? bucketOverride,
  }) async {
    return uploadFile(file.path, bucketOverride: bucketOverride);
  }

  Future<String?> uploadFileBytes(
    Uint8List bytes,
    String filename, {
    String? bucketOverride,
  }) async {
    final result = await _uploadWithRetry(
      filePath: null,
      bytes: bytes,
      filename: filename,
      bucketOverride: bucketOverride,
    );

    return result.isSuccess ? result.data : null;
  }

  Future<Result<String?>> _uploadWithRetry({
    String? filePath,
    Uint8List? bytes,
    required String filename,
    String? bucketOverride,
  }) async {
    try {
      final url = await RetryHelper.retry(
        () => _upload(filePath, bytes, filename, bucketOverride),
        maxAttempts: 3,
        shouldRetry: (error) =>
            error is NetworkException || error is FileStorageException,
      );
      return Result.success(url);
    } catch (error) {
      final appError = error is AppException
          ? error
          : ErrorHandler.handleFirebaseException(error, context: 'File upload');
      ErrorHandler.logError(appError, context: 'CloudinaryService.upload');
      return Result.failure(appError);
    }
  }

  Future<String?> _upload(
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
        throw ValidationException('No file payload was provided for upload.');
      }

      return client.storage.from(bucket).getPublicUrl(objectPath);
    } on supabase.StorageException catch (e) {
      throw FileStorageException(
        'Supabase upload failed for bucket "$bucket": ${e.message}',
        code: e.statusCode?.toString(),
        originalError: e,
      );
    } catch (error) {
      throw ErrorHandler.handleFirebaseException(
        error,
        context: 'Supabase upload',
      );
    }
  }
}
