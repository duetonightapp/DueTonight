import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/room_model.dart';
import '../../data/models/room_member_model.dart';
import '../../data/models/room_assignment_model.dart';
import '../../data/models/room_announcement_model.dart';
import '../../data/models/room_membership_model.dart';
import '../../data/models/room_subject_model.dart';
import '../../data/models/room_personal_reminder_model.dart';
import '../../data/repositories/room_repository.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository();
});

final myRoomsProvider = FutureProvider.autoDispose<List<RoomMembership>>((ref) {
  return ref.read(roomRepositoryProvider).fetchMyRooms();
});

final roomDetailsProvider = FutureProvider.family<Room, String>((ref, roomId) {
  return ref.read(roomRepositoryProvider).getRoom(roomId);
});

final roomMembersProvider = FutureProvider.family<List<RoomMember>, String>((
  ref,
  roomId,
) {
  return ref.read(roomRepositoryProvider).getMembers(roomId);
});

final roomSubjectsProvider = FutureProvider.family<List<RoomSubject>, String>((
  ref,
  roomId,
) {
  return ref.read(roomRepositoryProvider).getSubjects(roomId);
});

final roomAssignmentsProvider =
    StreamProvider.family<List<RoomAssignment>, String>((ref, roomId) {
      return ref.read(roomRepositoryProvider).watchAssignments(roomId);
    });

final roomAnnouncementsProvider =
    StreamProvider.family<List<RoomAnnouncement>, String>((ref, roomId) {
      return ref.read(roomRepositoryProvider).watchAnnouncements(roomId);
    });

final roomPersonalRemindersProvider =
    StreamProvider.family<List<RoomPersonalReminder>, String>((ref, roomId) {
      return ref.read(roomRepositoryProvider).watchPersonalReminders(roomId);
    });

final currentRoomRoleProvider = Provider.family<String?, String>((ref, roomId) {
  final members = ref.watch(roomMembersProvider(roomId)).valueOrNull ?? [];
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  final member = members.where((m) => m.userId == userId).toList();
  return member.isNotEmpty ? member.first.role : null;
});

final completedAssignmentsProvider = StateNotifierProvider<CompletedAssignmentsNotifier, Set<String>>((ref) {
  return CompletedAssignmentsNotifier();
});

class CompletedAssignmentsNotifier extends StateNotifier<Set<String>> {
  CompletedAssignmentsNotifier() : super({}) {
    _init();
  }

  static const _boxName = 'completed_assignments_box';

  Future<void> _init() async {
    final box = await Hive.openBox<String>(_boxName);
    state = box.values.toSet();
  }

  Future<void> markCompleted(String assignmentId) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(assignmentId, assignmentId);
    state = {...state, assignmentId};
  }

  Future<void> clearAll() async {
    final box = await Hive.openBox<String>(_boxName);
    await box.clear();
    state = {};
  }
}
