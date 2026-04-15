import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase/supabase.dart';

import '../config/local_config.dart';

final cloudinaryProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

class UploadException implements Exception {
  final String message;

  const UploadException(this.message);

  @override
  String toString() => message;
}

class CloudinaryService {
  static const String _documentsBucket = 'documents';
  static const String _mediaBucket = 'media';
  static const String avatarsBucket = 'avatars';

  SupabaseClient? _client;

  bool get isConfigured =>
      _resolveUrl().isNotEmpty && _resolveAnonKey().isNotEmpty;

  SupabaseClient _getClient() {
    final existing = _client;
    if (existing != null) {
      return existing;
    }

    final url = _resolveUrl();
    final anonKey = _resolveAnonKey();
    if (url.isEmpty || anonKey.isEmpty) {
      throw const UploadException(
        'Supabase not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY or update lib/config/local_config.dart.',
      );
    }

    final client = SupabaseClient(url, anonKey);
    _client = client;
    return client;
  }

  String _resolveUrl() {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    return LocalConfig.supabaseUrl.trim();
  }

  String _resolveAnonKey() {
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }
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

  Future<String?> uploadFile(String filePath, {String? bucketOverride}) async {
    return _upload(
      filePath: filePath,
      bytes: null,
      filename: p.basename(filePath),
      bucketOverride: bucketOverride,
    );
  }

  Future<String?> uploadImage(File file, {String? bucketOverride}) async {
    return uploadFile(file.path, bucketOverride: bucketOverride);
  }

  Future<String?> uploadFileBytes(
    Uint8List bytes,
    String filename, {
    String? bucketOverride,
  }) async {
    return _upload(
      filePath: null,
      bytes: bytes,
      filename: filename,
      bucketOverride: bucketOverride,
    );
  }

  Future<String?> _upload({
    String? filePath,
    Uint8List? bytes,
    required String filename,
    String? bucketOverride,
  }) async {
    final client = _getClient();
    final mimeType = detectMimeType(
      filename: filename,
      bytes: bytes,
      filePath: filePath,
    );
    final bucket = bucketOverride ?? _bucketForMimeType(mimeType);
    final objectPath =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(filename)}';
    final fileOptions = FileOptions(upsert: true, contentType: mimeType);

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
        throw const UploadException('No file payload was provided for upload.');
      }

      return client.storage.from(bucket).getPublicUrl(objectPath);
    } on StorageException catch (e) {
      final message =
          'Supabase upload failed for bucket "$bucket": ${e.message} (HTTP ${e.statusCode ?? 'unknown'})';
      debugPrint('[Storage] $message');
      throw UploadException(message);
    } catch (e) {
      final message = 'Unexpected upload error for bucket "$bucket": $e';
      debugPrint('[Storage] $message');
      throw UploadException(message);
    }
  }
}
