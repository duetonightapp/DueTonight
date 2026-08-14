import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudinaryUploadResult {
  final String url;
  final String publicId;
  final String resourceType;

  const CloudinaryUploadResult({
    required this.url,
    required this.publicId,
    required this.resourceType,
  });
}

class CloudinaryUploadService {
  final SupabaseClient _client;

  CloudinaryUploadService({Dio? dio, SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<CloudinaryUploadResult> uploadFile({
    File? file,
    Uint8List? fileBytes,
    required String roomId,
    required String fileName,
    String folder = 'assignments',
    required void Function(double progress) onProgress,
  }) async {
    final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'rooms/$roomId/$folder/${timestamp}_$cleanFileName';

    onProgress(0.1);

    if (fileBytes != null) {
      await _client.storage.from('room-files').uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );
    } else if (file != null) {
      await _client.storage.from('room-files').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
    } else {
      throw Exception('No file or file bytes provided for upload');
    }

    onProgress(0.8);

    final signedUrl = await _client.storage.from('room-files').createSignedUrl(
          path,
          315360000,
        );

    onProgress(1.0);

    return CloudinaryUploadResult(
      url: signedUrl,
      publicId: path,
      resourceType: 'raw',
    );
  }
}
