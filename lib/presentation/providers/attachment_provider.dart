import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/room_attachment_model.dart';
import '../../data/repositories/room_attachment_repository.dart';
import '../../data/services/cloudinary_upload_service.dart';

final cloudinaryUploadServiceProvider = Provider<CloudinaryUploadService>((ref) {
  return CloudinaryUploadService();
});

final roomAttachmentRepositoryProvider =
    Provider<RoomAttachmentRepository>((ref) {
  return RoomAttachmentRepository();
});

final roomAttachmentsProvider =
    FutureProvider.family<List<RoomAttachment>, String>((ref, roomId) {
  return ref.read(roomAttachmentRepositoryProvider).getRoomAttachments(roomId);
});

final assignmentAttachmentsProvider =
    FutureProvider.family<List<RoomAttachment>, String>((ref, assignmentId) {
  return ref
      .read(roomAttachmentRepositoryProvider)
      .getAssignmentAttachments(assignmentId);
});
