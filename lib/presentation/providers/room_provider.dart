import 'package:flutter/foundation.dart';
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

final roomPushSubscribedUserIdsProvider =
    FutureProvider.family<Set<String>, String>((ref, roomId) {
  return ref.read(roomRepositoryProvider).fetchPushSubscribedUserIds(roomId);
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
  RealtimeChannel? _subscriptionChannel;

  Future<void> _init() async {
    final box = await Hive.openBox<String>(_boxName);
    state = box.values.toSet();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await fetchRemoteCompletions(userId);
      _subscribeToRealtime(userId);
    }
  }

  Future<void> fetchRemoteCompletions(String userId) async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('user_assignment_completions')
          .select('assignment_id')
          .eq('user_id', userId);

      final remoteSet = <String>{};
      for (final row in response as List) {
        final id = row['assignment_id'] as String?;
        if (id != null) remoteSet.add(id);
      }

      final box = await Hive.openBox<String>(_boxName);
      await box.clear();
      for (final id in remoteSet) {
        await box.put(id, id);
      }

      state = remoteSet;
    } catch (e) {
      debugPrint('Error fetching remote completions: $e');
    }
  }

  void _subscribeToRealtime(String userId) {
    try {
      _subscriptionChannel?.unsubscribe();
      final client = Supabase.instance.client;

      _subscriptionChannel = client.channel('public:user_assignment_completions:$userId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_assignment_completions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('Realtime completion change received: ${payload.eventType}');
            fetchRemoteCompletions(userId);
          },
        )
        ..subscribe();
    } catch (e) {
      debugPrint('Error subscribing to realtime completions: $e');
    }
  }

  Future<void> toggleCompleted(String assignmentId) async {
    final isDone = state.contains(assignmentId);
    if (isDone) {
      await markIncomplete(assignmentId);
    } else {
      await markCompleted(assignmentId);
    }
  }

  Future<void> markCompleted(String assignmentId) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(assignmentId, assignmentId);
    state = {...state, assignmentId};

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final client = Supabase.instance.client;
        await client.from('user_assignment_completions').upsert(
          {
            'user_id': userId,
            'assignment_id': assignmentId,
          },
          onConflict: 'user_id, assignment_id',
        );
      } catch (e) {
        debugPrint('Error saving completion to Supabase: $e');
      }
    }
  }

  Future<void> markIncomplete(String assignmentId) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.delete(assignmentId);
    state = state.where((id) => id != assignmentId).toSet();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final client = Supabase.instance.client;
        await client
            .from('user_assignment_completions')
            .delete()
            .eq('user_id', userId)
            .eq('assignment_id', assignmentId);
      } catch (e) {
        debugPrint('Error deleting completion from Supabase: $e');
      }
    }
  }

  Future<void> clearAll() async {
    final box = await Hive.openBox<String>(_boxName);
    await box.clear();
    state = {};
  }

  @override
  void dispose() {
    _subscriptionChannel?.unsubscribe();
    super.dispose();
  }
}
