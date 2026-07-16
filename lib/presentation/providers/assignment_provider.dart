import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/assignment_model.dart';
import '../../data/repositories/assignment_repository.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository();
});

class AssignmentListState {
  final List<Assignment> assignments;
  final bool isLoading;
  final String? error;

  AssignmentListState({
    this.assignments = const [],
    this.isLoading = false,
    this.error,
  });

  AssignmentListState copyWith({
    List<Assignment>? assignments,
    bool? isLoading,
    String? error,
  }) {
    return AssignmentListState(
      assignments: assignments ?? this.assignments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AssignmentListNotifier extends StateNotifier<AssignmentListState> {
  final AssignmentRepository _repository;
  final Ref _ref;

  AssignmentListNotifier(this._repository, this._ref)
    : super(AssignmentListState()) {
    loadAssignments();
  }

  Future<void> loadAssignments({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repository.getAssignments(forceRefresh: forceRefresh);
      state = state.copyWith(assignments: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleAssignment(String id, bool isCompleted) async {
    final originalAssignments = [...state.assignments];
    state = state.copyWith(
      assignments: state.assignments.map((a) {
        if (a.id == id) {
          return a.copyWith(isCompleted: isCompleted);
        }
        return a;
      }).toList(),
    );

    try {
      await _repository.toggleAssignmentCompletion(id, isCompleted);
    } catch (e) {
      state = state.copyWith(
        assignments: originalAssignments,
        error: e.toString(),
      );
    }
  }

  Future<void> addAssignment(Assignment assignment) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await _repository.createAssignment(assignment);
      state = state.copyWith(
        assignments: [...state.assignments, created],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeAssignment(String id) async {
    final originalAssignments = [...state.assignments];
    state = state.copyWith(
      assignments: state.assignments.where((a) => a.id != id).toList(),
    );

    try {
      await _repository.deleteAssignment(id);
    } catch (e) {
      state = state.copyWith(
        assignments: originalAssignments,
        error: e.toString(),
      );
    }
  }
}

final assignmentListProvider =
    StateNotifierProvider<AssignmentListNotifier, AssignmentListState>((ref) {
      final repo = ref.read(assignmentRepositoryProvider);
      return AssignmentListNotifier(repo, ref);
    });

final pendingAssignmentsProvider = Provider<List<Assignment>>((ref) {
  final state = ref.watch(assignmentListProvider);
  return state.assignments
      .where((a) => !a.isCompleted && !a.isOverdue)
      .toList();
});

final completedAssignmentsProvider = Provider<List<Assignment>>((ref) {
  final state = ref.watch(assignmentListProvider);
  return state.assignments.where((a) => a.isCompleted).toList();
});

final overdueAssignmentsProvider = Provider<List<Assignment>>((ref) {
  final state = ref.watch(assignmentListProvider);
  return state.assignments.where((a) => a.isOverdue).toList();
});
