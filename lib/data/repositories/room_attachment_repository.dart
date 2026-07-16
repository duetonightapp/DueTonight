import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_attachment_model.dart';

class RoomAttachmentRepository {
  final SupabaseClient _client;

  RoomAttachmentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Stream<List<RoomAttachment>> watchRoomAttachments(String roomId) {
    return _client
        .from('room_attachments')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map(
                (row) =>
                    RoomAttachment.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList(),
        );
  }

  Stream<List<RoomAttachment>> watchAssignmentAttachments(String assignmentId) {
    return _client
        .from('room_attachments')
        .stream(primaryKey: ['id'])
        .eq('assignment_id', assignmentId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map(
                (row) =>
                    RoomAttachment.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList(),
        );
  }

  Future<List<RoomAttachment>> getRoomAttachments(String roomId) async {
    final response = await _client
        .from('room_attachments')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: false);

    final rows = response as List;
    return rows
        .map((row) => RoomAttachment.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<RoomAttachment>> getAssignmentAttachments(String assignmentId) async {
    final response = await _client
        .from('room_attachments')
        .select()
        .eq('assignment_id', assignmentId)
        .order('created_at', ascending: false);

    final rows = response as List;
    return rows
        .map((row) => RoomAttachment.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<RoomAttachment> createAttachment({
    required String roomId,
    required String fileName,
    required String fileUrl,
    required String fileType,
    String? assignmentId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final response = await _client
        .from('room_attachments')
        .insert({
          'room_id': roomId,
          'uploaded_by': userId,
          'file_name': fileName,
          'file_url': fileUrl,
          'file_type': fileType,
          'assignment_id': assignmentId,
        })
        .select()
        .single();

    return RoomAttachment.fromJson(Map<String, dynamic>.from(response));
  }
}
