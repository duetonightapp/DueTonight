import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/room_study_resource_model.dart';
import '../../data/repositories/study_resource_repository.dart';

final studyResourceRepositoryProvider = Provider<StudyResourceRepository>((ref) {
  return StudyResourceRepository();
});

final roomStudyResourcesProvider =
    StreamProvider.family<List<RoomStudyResource>, String>((ref, roomId) {
  return ref.watch(studyResourceRepositoryProvider).watchStudyResources(roomId);
});

final singleStudyResourceProvider =
    FutureProvider.family<RoomStudyResource?, String>((ref, resourceId) {
  return ref.watch(studyResourceRepositoryProvider).getStudyResourceById(resourceId);
});
