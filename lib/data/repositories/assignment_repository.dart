import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/assignment_local_datasource.dart';
import '../models/assignment_model.dart';

class AssignmentRepository {
  final AssignmentLocalDatasource _localDatasource;
  final SupabaseClient _supabaseClient;

  AssignmentRepository({
    AssignmentLocalDatasource? localDatasource,
    SupabaseClient? supabaseClient,
  })  : _localDatasource = localDatasource ?? AssignmentLocalDatasource(),
        _supabaseClient = supabaseClient ?? Supabase.instance.client;

  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

  Future<List<Assignment>> getAssignments({bool forceRefresh = false}) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    if (!forceRefresh) {
      try {
        final cached = await _localDatasource.getAssignments();
        if (cached.isNotEmpty) {
          return cached.where((a) => a.userId == userId).toList();
        }
      } catch (e) {
        print('Error reading cached assignments: $e');
      }
    }

    try {
      final response = await _supabaseClient
          .from('assignments')
          .select()
          .order('deadline', ascending: true);

      final assignments = (response as List)
          .map((json) => Assignment.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      await _localDatasource.saveAssignments(assignments);
      return assignments;
    } catch (e) {
      print('Error fetching assignments from remote: $e');
      final cached = await _localDatasource.getAssignments();
      return cached.where((a) => a.userId == userId).toList();
    }
  }

  Future<void> toggleAssignmentCompletion(String id, bool isCompleted) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final cached = await _localDatasource.getAssignments();
      final idx = cached.indexWhere((a) => a.id == id);
      if (idx != -1) {
        final updated = cached[idx].copyWith(isCompleted: isCompleted);
        await _localDatasource.saveAssignment(updated);
      }
    } catch (e) {
      print('Error updating local cache: $e');
    }

    try {
      await _supabaseClient
          .from('assignments')
          .update({'is_completed': isCompleted})
          .eq('id', id);
    } catch (e) {
      print('Error updating remote assignment completion: $e');
      rethrow;
    }
  }

  Future<Assignment> createAssignment(Assignment assignment) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final assignmentWithUser = assignment.copyWith(userId: userId);

    try {
      final response = await _supabaseClient
          .from('assignments')
          .insert(assignmentWithUser.toJson())
          .select()
          .single();

      final created = Assignment.fromJson(Map<String, dynamic>.from(response));
      await _localDatasource.saveAssignment(created);
      return created;
    } catch (e) {
      print('Error creating assignment on remote: $e');
      rethrow;
    }
  }

  Future<void> deleteAssignment(String id) async {
    await _localDatasource.deleteAssignment(id);

    try {
      await _supabaseClient
          .from('assignments')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting assignment from remote: $e');
      rethrow;
    }
  }
}
