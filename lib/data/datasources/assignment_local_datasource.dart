import 'package:hive_flutter/hive_flutter.dart';
import '../models/assignment_model.dart';

class AssignmentLocalDatasource {
  static const String _boxName = 'assignments_box';

  Future<Box<Map>> get _box async => await Hive.openBox<Map>(_boxName);

  Future<List<Assignment>> getAssignments() async {
    final box = await _box;
    final list = box.values.toList();
    return list.map((e) => Assignment.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveAssignments(List<Assignment> assignments) async {
    final box = await _box;
    await box.clear();
    for (final assignment in assignments) {
      await box.put(assignment.id, assignment.toJson());
    }
  }

  Future<void> saveAssignment(Assignment assignment) async {
    final box = await _box;
    await box.put(assignment.id, assignment.toJson());
  }

  Future<void> deleteAssignment(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<void> clearCache() async {
    final box = await _box;
    await box.clear();
  }
}
