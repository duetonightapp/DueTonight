import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_study_resource_model.dart';

class StudyResourceRepository {
  final SupabaseClient _client;

  StudyResourceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Stream<List<RoomStudyResource>> watchStudyResources(String roomId) {
    return _client
        .from('room_study_resources')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((row) => RoomStudyResource.fromJson(row)).toList());
  }

  Future<List<RoomStudyResource>> getStudyResources(String roomId) async {
    final response = await _client
        .from('room_study_resources')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: false);

    final rows = response as List;
    return rows.map((row) => RoomStudyResource.fromJson(Map<String, dynamic>.from(row))).toList();
  }

  Future<RoomStudyResource?> getStudyResourceById(String resourceId) async {
    final response = await _client
        .from('room_study_resources')
        .select()
        .eq('id', resourceId)
        .maybeSingle();

    if (response == null) return null;
    return RoomStudyResource.fromJson(Map<String, dynamic>.from(response));
  }

  Future<RoomStudyResource> uploadAndCreateResource({
    required String roomId,
    required String title,
    String? description,
    required String fileName,
    required String fileType,
    required int fileSize,
    Uint8List? fileBytes,
    File? file,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Clean file name for storage path
    final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'rooms/$roomId/study_resources/${timestamp}_$cleanFileName';

    if (fileBytes != null) {
      await _client.storage.from('room-files').uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: fileType.isNotEmpty ? fileType : null,
            ),
          );
    } else if (file != null) {
      await _client.storage.from('room-files').upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: fileType.isNotEmpty ? fileType : null,
            ),
          );
    } else {
      throw Exception('No file content provided');
    }

    // Create a 10-year signed URL for private bucket access inside app
    final signedUrl = await _client.storage.from('room-files').createSignedUrl(
          storagePath,
          315360000,
        );

    final response = await _client
        .from('room_study_resources')
        .insert({
          'room_id': roomId,
          'title': title,
          'description': description,
          'file_url': signedUrl,
          'file_name': fileName,
          'file_type': fileType,
          'file_size': fileSize,
          'uploaded_by': userId,
        })
        .select()
        .single();

    return RoomStudyResource.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deleteResource({
    required String resourceId,
    required String roomId,
  }) async {
    await _client.from('room_study_resources').delete().eq('id', resourceId);
  }
}
