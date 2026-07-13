import 'package:flutter_test/flutter_test.dart';
import 'package:due_tonight/data/models/assignment_solution_model.dart';

void main() {
  group('AssignmentSolution', () {
    test('round-trips JSON correctly', () {
      final createdAt = DateTime.utc(2026, 7, 13, 10, 0, 0);
      final solution = AssignmentSolution(
        id: 'solution-1',
        roomId: 'room-1',
        assignmentId: 'assignment-1',
        uploadedBy: 'user-1',
        fileName: 'solved-assignment.pdf',
        fileUrl: 'https://example.com/solution.pdf',
        fileType: 'application/pdf',
        createdAt: createdAt,
      );

      final json = solution.toJson();
      final decoded = AssignmentSolution.fromJson(json);

      expect(decoded.id, solution.id);
      expect(decoded.roomId, solution.roomId);
      expect(decoded.assignmentId, solution.assignmentId);
      expect(decoded.uploadedBy, solution.uploadedBy);
      expect(decoded.fileName, solution.fileName);
      expect(decoded.fileUrl, solution.fileUrl);
      expect(decoded.fileType, solution.fileType);
      expect(decoded.createdAt, solution.createdAt);
    });
  });
}
