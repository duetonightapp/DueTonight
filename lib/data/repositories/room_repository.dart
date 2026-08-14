import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../models/room_model.dart';
import '../models/room_member_model.dart';
import '../models/room_assignment_model.dart';
import '../models/room_announcement_model.dart';
import '../models/room_membership_model.dart';
import '../models/room_subject_model.dart';
import '../models/room_personal_reminder_model.dart';

class RoomCreateResult {
  final String roomId;
  final String roomCode;
  final bool existed;

  const RoomCreateResult({
    required this.roomId,
    required this.roomCode,
    required this.existed,
  });
}

class RoomRepository {
  final SupabaseClient _client;

  RoomRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<RoomCreateResult> createRoom({
    required String collegeName,
    required String branch,
    required String semester,
    required String division,
    required List<String> subjects,
  }) async {
    final response = await _client.rpc(
      'create_room_with_owner',
      params: {
        'p_college': collegeName,
        'p_branch': branch,
        'p_semester': semester,
        'p_division': division,
        'p_subjects': subjects,
      },
    );

    final data = response is List
        ? (response.isNotEmpty ? response.first : null)
        : response;

    if (data == null) {
      throw Exception('Room creation failed');
    }

    return RoomCreateResult(
      roomId: data['room_id'] as String,
      roomCode: data['room_code'] as String,
      existed: data['existed'] as bool? ?? false,
    );
  }

  Future<List<RoomMembership>> fetchMyRooms() async {
    if (_client.auth.currentUser == null) return [];

    final response = await _client.rpc('get_my_rooms');
    if (response == null) return [];

    final rows = response as List;
    return rows
        .map(
          (row) =>
              RoomMembership.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<String> joinRoomByCode(String code) async {
    final response = await _client.rpc(
      'join_room_by_code',
      params: {'p_code': code},
    );

    if (response is String) {
      return response;
    }

    if (response is Map && response['room_id'] != null) {
      return response['room_id'] as String;
    }

    throw Exception('Invalid join response');
  }

  Future<void> transferOwnership({
    required String roomId,
    required String newOwnerId,
  }) async {
    await _client.rpc(
      'transfer_room_ownership',
      params: {'p_room_id': roomId, 'p_new_owner_id': newOwnerId},
    );
  }

  Future<void> updateMemberRole({
    required String roomId,
    required String userId,
    required String role,
  }) async {
    await _client
        .from('room_members')
        .update({'role': role})
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }

  Future<Room> getRoom(String roomId) async {
    final response = await _client
        .from('rooms')
        .select()
        .eq('id', roomId)
        .maybeSingle();

    if (response == null) {
      throw Exception('Room not found');
    }

    return Room.fromJson(Map<String, dynamic>.from(response));
  }

  Stream<List<RoomMember>> watchMembers(String roomId) {
    return _client
        .from('room_members')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('joined_at', ascending: true)
        .map(
          (rows) => rows
              .map((row) => RoomMember.fromJson(Map<String, dynamic>.from(row)))
              .toList(),
        );
  }

  Future<List<RoomMember>> getMembers(String roomId) async {
    final response = await _client
        .from('room_members')
        .select()
        .eq('room_id', roomId)
        .order('joined_at', ascending: true);

    final rows = response as List;
    return rows
        .map((row) => RoomMember.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<RoomSubject>> getSubjects(String roomId) async {
    final response = await _client
        .from('room_subjects')
        .select()
        .eq('room_id', roomId)
        .order('name', ascending: true);

    final rows = response as List;
    return rows
        .map((row) => RoomSubject.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Stream<List<RoomSubject>> watchSubjects(String roomId) {
    return _client
        .from('room_subjects')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('name', ascending: true)
        .map(
          (rows) => rows
              .map(
                (row) => RoomSubject.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList(),
        );
  }

  Stream<List<RoomAssignment>> watchAssignments(String roomId) {
    return _client
        .from('room_assignments')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map(
                (row) =>
                    RoomAssignment.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList(),
        );
  }

  Stream<List<RoomAnnouncement>> watchAnnouncements(String roomId) {
    return _client
        .from('room_announcements')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map(
                (row) =>
                    RoomAnnouncement.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList(),
        );
  }

  Future<String> createAssignment({
    required String roomId,
    required String title,
    required String subjectId,
    required String subjectName,
    String? description,
    DateTime? deadline,
  }) async {
    final response = await _client.from('room_assignments').insert({
      'room_id': roomId,
      'title': title,
      'description': description,
      'subject': subjectName,
      'subject_id': subjectId,
      'deadline': deadline?.toIso8601String(),
      'created_by': _client.auth.currentUser?.id,
    }).select().single();

    final assignmentId = response['id'] as String;

    _triggerNotification(
      roomId: roomId,
      type: 'assignment',
      title: title,
      details: description,
    );

    return assignmentId;
  }

  Future<void> createAnnouncement({
    required String roomId,
    required String title,
    required String body,
  }) async {
    await _client.from('room_announcements').insert({
      'room_id': roomId,
      'title': title,
      'body': body,
      'created_by': _client.auth.currentUser?.id,
    });

    _triggerNotification(
      roomId: roomId,
      type: 'announcement',
      title: title,
      details: body,
    );
  }

  Future<void> _triggerNotification({
    required String roomId,
    required String type,
    required String title,
    String? details,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    String uploaderName = 'Someone';
    try {
      final profileRes = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      if (profileRes != null && profileRes['full_name'] != null) {
        uploaderName = profileRes['full_name'] as String;
      }
    } catch (e) {
      debugPrint('Error fetching uploader profile name: $e');
    }

    try {
      // Use the web-specific backend URL on web, otherwise the native backend URL
      final baseUrl = kIsWeb ? AppConstants.backendUrlWeb : AppConstants.backendUrl;
      String url = '$baseUrl/api/notifications/notify';

      await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomId': roomId,
          'type': type,
          'title': title,
          'details': details ?? '',
          'uploaderName': uploaderName,
          'uploaderId': userId,
        }),
      );
    } catch (e) {
      debugPrint('Error triggering push notification: $e');
    }
  }

  Future<void> deleteRoom({required String roomId}) async {
    await _client.rpc('delete_room', params: {'p_room_id': roomId});
  }

  Stream<List<RoomPersonalReminder>> watchPersonalReminders(String roomId) {
    return _client
        .from('room_personal_reminders')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('date', ascending: true)
        .map(
          (rows) => rows
              .map(
                (row) =>
                    RoomPersonalReminder.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList(),
        );
  }

  Future<void> createPersonalReminder({
    required String roomId,
    required String title,
    String? body,
    required DateTime date,
  }) async {
    await _client.from('room_personal_reminders').insert({
      'room_id': roomId,
      'title': title,
      'body': body,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'user_id': _client.auth.currentUser?.id,
    });
  }

  Future<void> deletePersonalReminder(String id) async {
    await _client.from('room_personal_reminders').delete().eq('id', id);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _client.from('room_announcements').delete().eq('id', id);
  }

  Future<void> deleteAssignment(String id) async {
    try {
      // 1. Fetch attachments associated with this assignment
      final attachmentsResponse = await _client
          .from('room_attachments')
          .select('file_url')
          .eq('assignment_id', id);

      final attachments = attachmentsResponse as List;
      final storagePaths = <String>[];
      for (final att in attachments) {
        final url = att['file_url'] as String?;
        if (url != null) {
          final path = getStoragePathFromUrl(url);
          if (path != null) {
            storagePaths.add(path);
          }
        }
      }

      // 2. Delete files from Supabase Storage
      if (storagePaths.isNotEmpty) {
        await _client.storage.from('room-files').remove(storagePaths);
      }
    } catch (e) {
      // Log/ignore storage deletion failure to ensure DB deletion always proceeds
      print('Failed to delete assignment attachments from storage: $e');
    }

    // 3. Delete attachments from DB
    await _client.from('room_attachments').delete().eq('assignment_id', id);

    // 4. Delete the assignment itself
    await _client.from('room_assignments').delete().eq('id', id);
  }

  String? getStoragePathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIdx = segments.indexOf('room-files');
      if (bucketIdx != -1 && bucketIdx < segments.length - 1) {
        return segments.sublist(bucketIdx + 1).join('/');
      }
    } catch (_) {}
    return null;
  }


  Future<void> removeMember({
    required String roomId,
    required String userId,
  }) async {
    await _client
        .from('room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }


  Future<Map<String, Map<String, dynamic>>> fetchProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    final response = await _client
        .from('profiles')
        .select('id, full_name, email, avatar_url')
        .inFilter('id', userIds);

    final map = <String, Map<String, dynamic>>{};
    for (final row in response as List) {
      final data = Map<String, dynamic>.from(row as Map);
      map[data['id'] as String] = data;
    }
    return map;
  }
}
