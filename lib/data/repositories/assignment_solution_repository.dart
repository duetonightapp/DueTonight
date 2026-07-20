import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assignment_solution_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';

class AssignmentSolutionRepository {
  final SupabaseClient _client;

  AssignmentSolutionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Stream<List<AssignmentSolution>> watchAssignmentSolutions(String assignmentId) {
    return _client
        .from('assignment_solutions')
        .stream(primaryKey: ['id'])
        .eq('assignment_id', assignmentId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map((row) => AssignmentSolution.fromJson(Map<String, dynamic>.from(row)))
              .toList(),
        );
  }

  Future<List<AssignmentSolution>> getAssignmentSolutions(String assignmentId) async {
    final response = await _client
        .from('assignment_solutions')
        .select()
        .eq('assignment_id', assignmentId)
        .order('created_at', ascending: false);

    final rows = response as List;
    return rows
        .map((row) => AssignmentSolution.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<AssignmentSolution> createSolution({
    required String roomId,
    required String assignmentId,
    required String fileName,
    required String fileUrl,
    required String fileType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final response = await _client
        .from('assignment_solutions')
        .insert({
          'room_id': roomId,
          'assignment_id': assignmentId,
          'uploaded_by': userId,
          'file_name': fileName,
          'file_url': fileUrl,
          'file_type': fileType,
        })
        .select()
        .single();

    final solution = AssignmentSolution.fromJson(Map<String, dynamic>.from(response));

    // Fetch uploader name & assignment details asynchronously to send notification
    _triggerNotification(
      roomId: roomId,
      assignmentId: assignmentId,
      fileName: fileName,
      userId: userId,
    );

    return solution;
  }

  Future<void> _triggerNotification({
    required String roomId,
    required String assignmentId,
    required String fileName,
    required String userId,
  }) async {
    String uploaderName = 'Someone';
    String assignmentTitle = 'Assignment';
    
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
      debugPrint('Error fetching uploader profile: $e');
    }

    try {
      final assignmentRes = await _client
          .from('room_assignments')
          .select('title')
          .eq('id', assignmentId)
          .maybeSingle();
      if (assignmentRes != null && assignmentRes['title'] != null) {
        assignmentTitle = assignmentRes['title'] as String;
      }
    } catch (e) {
      debugPrint('Error fetching assignment details: $e');
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
          'type': 'solution',
          'title': 'solution for $assignmentTitle',
          'details': fileName,
          'uploaderName': uploaderName,
          'uploaderId': userId,
        }),
      );
    } catch (e) {
      debugPrint('Error triggering push notification: $e');
    }
  }
}
