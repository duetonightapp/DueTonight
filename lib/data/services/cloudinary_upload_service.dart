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
    required Uint8List fileBytes,
    required String roomId,
    required String fileName,
    required void Function(double progress) onProgress,
    String folder = 'assignments',
  }) async {
    // Clean file name to remove invalid characters
    final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // RLS policy checks split_part(name, '/', 2) to see if it is the room ID.
    // So the second segment MUST be the room ID.
    final path = 'rooms/$roomId/$folder/${timestamp}_$cleanFileName';

    onProgress(0.1);

    await _client.storage.from('room-files').uploadBinary(
      path,
      fileBytes,
      fileOptions: const FileOptions(upsert: true),
    );

    onProgress(0.8);

    // Create a pre-authenticated signed URL valid for 10 years (315360000 seconds)
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

