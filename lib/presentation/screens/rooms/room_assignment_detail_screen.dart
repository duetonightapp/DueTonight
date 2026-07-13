import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/assignment_solution_model.dart';
import '../../../data/models/room_attachment_model.dart';
import '../../providers/assignment_solution_provider.dart';
import '../../providers/attachment_provider.dart';
import '../../providers/room_provider.dart';
import 'attachment_viewer_screen.dart';

class RoomAssignmentDetailScreen extends ConsumerWidget {
  final String roomId;
  final String assignmentId;

  const RoomAssignmentDetailScreen({
    super.key,
    required this.roomId,
    required this.assignmentId,
  });

  Future<void> _downloadAndOpenFile(BuildContext context, RoomAttachment attachment) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Downloading ${attachment.fileName}...'),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final dio = Dio();
      Directory? downloadsDir;
      String? savePath;

      try {
        if (Platform.isAndroid) {
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            downloadsDir = await getExternalStorageDirectory();
          }
          if (downloadsDir != null) {
            savePath = p.join(downloadsDir.path, attachment.fileName);
            await dio.download(attachment.fileUrl, savePath);
          } else {
            throw Exception("No external storage directory found");
          }
        } else {
          if (Platform.isIOS) {
            downloadsDir = await getApplicationDocumentsDirectory();
          } else {
            downloadsDir = await getDownloadsDirectory();
          }
          downloadsDir ??= await getTemporaryDirectory();
          savePath = p.join(downloadsDir.path, attachment.fileName);
          await dio.download(attachment.fileUrl, savePath);
        }
      } catch (e) {
        // Fallback to temporary directory on write/permission errors
        downloadsDir = await getTemporaryDirectory();
        savePath = p.join(downloadsDir.path, attachment.fileName);
        await dio.download(attachment.fileUrl, savePath);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded successfully to ${p.basename(savePath!)}'),
          backgroundColor: AppTheme.safeColor,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () {
              OpenFilex.open(savePath!);
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadAndOpenSolution(
    BuildContext context,
    AssignmentSolution solution,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Downloading ${solution.fileName}...'),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final dio = Dio();
      Directory? downloadsDir;
      String? savePath;

      try {
        if (Platform.isAndroid) {
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            downloadsDir = await getExternalStorageDirectory();
          }
          if (downloadsDir != null) {
            savePath = p.join(downloadsDir.path, solution.fileName);
            await dio.download(solution.fileUrl, savePath);
          } else {
            throw Exception('No external storage directory found');
          }
        } else {
          if (Platform.isIOS) {
            downloadsDir = await getApplicationDocumentsDirectory();
          } else {
            downloadsDir = await getDownloadsDirectory();
          }
          downloadsDir ??= await getTemporaryDirectory();
          savePath = p.join(downloadsDir.path, solution.fileName);
          await dio.download(solution.fileUrl, savePath);
        }
      } catch (e) {
        downloadsDir = await getTemporaryDirectory();
        savePath = p.join(downloadsDir.path, solution.fileName);
        await dio.download(solution.fileUrl, savePath);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded successfully to ${p.basename(savePath!)}'),
          backgroundColor: AppTheme.safeColor,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () {
              OpenFilex.open(savePath!);
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _uploadSolution(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final file = File(filePath);
      final lowerPath = filePath.toLowerCase();
      final mimeType = lookupMimeType(filePath) ??
          (lowerPath.endsWith('.docx')
              ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
              : lowerPath.endsWith('.doc')
                  ? 'application/msword'
                  : 'application/pdf');
      final size = await file.length();
      final isSupportedDocument = mimeType == 'application/pdf' ||
          mimeType == 'application/msword' ||
          mimeType == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
          lowerPath.endsWith('.doc') ||
          lowerPath.endsWith('.docx') ||
          lowerPath.endsWith('.pdf');

      if (!isSupportedDocument) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload a PDF or Word file.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (size > 5 * 1024 * 1024) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File size exceeds the 5MB limit.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Uploading solution...'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 10),
        ),
      );

      final uploadService = ref.read(cloudinaryUploadServiceProvider);
      final uploadResult = await uploadService.uploadFile(
        file: file,
        roomId: roomId,
        fileName: p.basename(filePath),
        folder: 'solutions',
        onProgress: (_) {},
      );

      await ref.read(assignmentSolutionRepositoryProvider).createSolution(
        roomId: roomId,
        assignmentId: assignmentId,
        fileName: p.basename(filePath),
        fileUrl: uploadResult.url,
        fileType: mimeType,
      );

      ref.invalidate(assignmentSolutionsProvider(assignmentId));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solution uploaded successfully!'),
          backgroundColor: AppTheme.safeColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(roomAssignmentsProvider(roomId));
    final attachmentsAsync = ref.watch(assignmentAttachmentsProvider(assignmentId));
    final solutionsAsync = ref.watch(assignmentSolutionsProvider(assignmentId));
    final role = ref.watch(currentRoomRoleProvider(roomId));
    final canDelete = role == 'owner' || role == 'moderator';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Assignment Details',
          style: GoogleFonts.unbounded(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      'Delete Assignment',
                      style: GoogleFonts.unbounded(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    content: const Text('Are you sure you want to delete this assignment for the room?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.inter(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await ref.read(roomRepositoryProvider).deleteAssignment(assignmentId);
                    ref.invalidate(roomAssignmentsProvider(roomId));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Assignment deleted successfully!'),
                          backgroundColor: AppTheme.safeColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete assignment: $e'),
                          backgroundColor: AppTheme.errorColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: assignmentsAsync.when(
          data: (assignments) {
            final assignment = assignments.firstWhere(
              (a) => a.id == assignmentId,
              orElse: () => throw Exception('Assignment not found'),
            );

            final deadlineText = assignment.deadline != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(assignment.deadline!)
                : 'No deadline';

            final isOverdue =
                assignment.deadline != null &&
                assignment.deadline!.isBefore(DateTime.now());

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject Tag/Badge
                  if (assignment.subject != null && assignment.subject!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        assignment.subject!.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    assignment.title,
                    style: GoogleFonts.unbounded(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Deadline card/info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isOverdue
                            ? AppTheme.errorColor.withOpacity(0.15)
                            : Colors.white.withOpacity(0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 20,
                          color: isOverdue ? AppTheme.errorColor : AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                deadlineText,
                                style: GoogleFonts.inter(
                                  color: isOverdue ? AppTheme.errorColor : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'OVERDUE',
                              style: GoogleFonts.inter(
                                color: AppTheme.errorColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description Header & Content
                  Text(
                    'Description',
                    style: GoogleFonts.unbounded(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Text(
                      assignment.description?.isNotEmpty == true
                          ? assignment.description!
                          : 'No description provided.',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Uploaded Solutions',
                          style: GoogleFonts.unbounded(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _uploadSolution(context, ref),
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Upload File'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  solutionsAsync.when(
                    data: (solutions) {
                      if (solutions.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Center(
                            child: Text(
                              'No solutions uploaded yet.',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }

                      final uploaderIds = solutions.map((s) => s.uploadedBy).toSet().toList();

                      return FutureBuilder<Map<String, Map<String, dynamic>>>(
                        future: ref.read(roomRepositoryProvider).fetchProfiles(uploaderIds),
                        builder: (context, snapshot) {
                          final profiles = snapshot.data ?? {};

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: solutions.length,
                            itemBuilder: (context, index) {
                              final solution = solutions[index];
                              final profile = profiles[solution.uploadedBy];
                              final uploaderName = profile?['full_name'] as String? ?? 'Member';
                              final timestamp = DateFormat('dd MMM yyyy, hh:mm a').format(solution.createdAt);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                      color: AppTheme.primaryColor,
                                    ),
                                    title: Text(
                                      solution.fileName,
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.95),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '$uploaderName · $timestamp',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.download_outlined),
                                      onPressed: () => _downloadAndOpenSolution(context, solution),
                                    ),
                                    onTap: () => _downloadAndOpenSolution(context, solution),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Failed to load solutions: $err',
                        style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Attachments Header & List
                  Text(
                    'Attachments',
                    style: GoogleFonts.unbounded(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  attachmentsAsync.when(
                    data: (attachments) {
                      if (attachments.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Center(
                            child: Text(
                              'No attachments uploaded.',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }

                      final uploaderIds = attachments.map((a) => a.uploadedBy).toSet().toList();

                      return FutureBuilder<Map<String, Map<String, dynamic>>>(
                        future: ref.read(roomRepositoryProvider).fetchProfiles(uploaderIds),
                        builder: (context, snapshot) {
                          final profiles = snapshot.data ?? {};

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: attachments.length,
                            itemBuilder: (context, index) {
                              final attachment = attachments[index];
                              final profile = profiles[attachment.uploadedBy];
                              final uploaderName = profile?['full_name'] as String? ?? 'Member';
                              final timestamp = DateFormat('dd MMM yyyy, hh:mm a').format(attachment.createdAt);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: Icon(
                                      attachment.fileType == 'application/pdf'
                                          ? Icons.picture_as_pdf_outlined
                                          : Icons.image_outlined,
                                      color: AppTheme.primaryColor,
                                    ),
                                    title: Text(
                                      attachment.fileName,
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.95),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '$uploaderName · $timestamp',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.download_outlined),
                                      onPressed: () => _downloadAndOpenFile(context, attachment),
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => AttachmentViewerScreen(
                                            attachment: attachment,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Failed to load attachments: $err',
                        style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'Failed to load assignment details: $err',
              style: TextStyle(color: AppTheme.errorColor, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
