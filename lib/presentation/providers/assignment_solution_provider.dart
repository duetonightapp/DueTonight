import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/assignment_solution_model.dart';
import '../../data/repositories/assignment_solution_repository.dart';

final assignmentSolutionRepositoryProvider = Provider<AssignmentSolutionRepository>((ref) {
  return AssignmentSolutionRepository();
});

final assignmentSolutionsProvider =
    FutureProvider.family<List<AssignmentSolution>, String>((ref, assignmentId) {
  return ref
      .read(assignmentSolutionRepositoryProvider)
      .getAssignmentSolutions(assignmentId);
});
