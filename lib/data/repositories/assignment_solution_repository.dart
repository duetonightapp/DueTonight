import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assignment_solution_model.dart';

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

    return AssignmentSolution.fromJson(Map<String, dynamic>.from(response));
  }
}
