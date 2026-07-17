import 'dart:io' as io;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/room_attachment_model.dart';
import '../../providers/attachment_provider.dart';
import '../../providers/room_provider.dart';
import 'attachment_viewer_screen.dart';

class RoomAttachmentsSheet extends ConsumerStatefulWidget {
  final String roomId;
  final String? assignmentId;
  final bool canUpload;
  final String title;

  const RoomAttachmentsSheet({
    super.key,
    required this.roomId,
    required this.canUpload,
    this.assignmentId,
    this.title = 'Attachments',
  });

  static Future<void> show(
    BuildContext context, {
    required String roomId,
    required bool canUpload,
    String? assignmentId,
    String title = 'Attachments',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RoomAttachmentsSheet(
        roomId: roomId,
        assignmentId: assignmentId,
        canUpload: canUpload,
        title: title,
      ),
    );
  }

  @override
  ConsumerState<RoomAttachmentsSheet> createState() =>
      _RoomAttachmentsSheetState();
}

class _RoomAttachmentsSheetState extends ConsumerState<RoomAttachmentsSheet> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  double _progress = 0;
  bool _isUploading = false;
  String? _error;

  bool _isAllowedExtension(String extension) {
    final ext = extension.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'pdf'].contains(ext);
  }

  Future<void> _uploadFile(PlatformFile file) async {
    if (_isUploading) return;

    final fileName = file.name;
    final extension = p.extension(fileName).replaceFirst('.', '');
    if (!_isAllowedExtension(extension)) {
      setState(() {
        _error = 'Unsupported file type.';
      });
      return;
    }

    final mimeType = lookupMimeType(fileName) ??
        (fileName.toLowerCase().endsWith('.docx')
            ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
            : fileName.toLowerCase().endsWith('.doc')
                ? 'application/msword'
                : 'application/octet-stream');

    setState(() {
      _isUploading = true;
      _progress = 0;
      _error = null;
    });

    try {
      final uploadService = ref.read(cloudinaryUploadServiceProvider);
      final uploadResult = await uploadService.uploadFile(
        fileBytes: file.bytes!,
        roomId: widget.roomId,
        fileName: fileName,
        onProgress: (value) {
          setState(() => _progress = value);
        },
      );

      final repo = ref.read(roomAttachmentRepositoryProvider);
      await repo.createAttachment(
        roomId: widget.roomId,
        assignmentId: widget.assignmentId,
        fileName: fileName,
        fileUrl: uploadResult.url,
        fileType: mimeType,
      );

      if (widget.assignmentId == null) {
        ref.invalidate(roomAttachmentsProvider(widget.roomId));
      } else {
        ref.invalidate(assignmentAttachmentsProvider(widget.assignmentId!));
      }

      if (mounted) {
        setState(() {
          _isUploading = false;
          _progress = 0;
        });
        _messengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: AppTheme.safeColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _error = 'Upload failed: $e';
      });
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool get _effectiveCanUpload => widget.assignmentId == null && widget.canUpload;

  Future<void> _pickImage() async {
    if (!_effectiveCanUpload) return;

    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result == null) return;

    final bytes = await result.readAsBytes();
    final size = bytes.length;
    if (size > 5 * 1024 * 1024) {
      setState(() {
        _error = 'File size exceeds the 5MB limit.';
      });
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('File size exceeds the 5MB limit.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final platformFile = PlatformFile(
      name: result.name,
      size: size,
      bytes: bytes,
      path: kIsWeb ? null : result.path,
    );

    await _uploadFile(platformFile);
  }

  Future<void> _pickFile() async {
    if (!_effectiveCanUpload) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result == null) return;

    final file = result.files.single;
    final ext = p.extension(file.name).toLowerCase().replaceFirst('.', '');

    if (!['pdf', 'jpg', 'jpeg', 'png', 'webp', 'doc', 'docx'].contains(ext)) {
      setState(() {
        _error = 'Unsupported file type. Please select a PDF, Word Document, or an Image.';
      });
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Unsupported file type. Please select a PDF, Word Document, or an Image.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final Uint8List bytes;
    final int size;
    if (kIsWeb) {
      if (file.bytes == null) return;
      bytes = file.bytes!;
      size = bytes.length;
    } else {
      if (file.path == null) return;
      final ioFile = io.File(file.path!);
      bytes = await ioFile.readAsBytes();
      size = bytes.length;
    }

    if (size > 5 * 1024 * 1024) {
      setState(() {
        _error = 'File size exceeds the 5MB limit.';
      });
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('File size exceeds the 5MB limit.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final platformFile = PlatformFile(
      name: file.name,
      size: size,
      bytes: bytes,
      path: kIsWeb ? null : file.path,
    );

    await _uploadFile(platformFile);
  }

  Future<void> _downloadAttachment(RoomAttachment attachment) async {
    try {
      if (kIsWeb) {
        final urlUri = Uri.parse(attachment.fileUrl);
        if (await canLaunchUrl(urlUri)) {
          await launchUrl(urlUri, mode: LaunchMode.externalApplication);
          if (!mounted) return;
          _messengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Attachment opened in a new tab.'),
              backgroundColor: AppTheme.safeColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          throw Exception("Could not open attachment link.");
        }
        return;
      }

      _messengerKey.currentState?.showSnackBar(
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
      io.Directory? downloadsDir;
      String? savePath;

      try {
        if (io.Platform.isAndroid) {
          downloadsDir = io.Directory('/storage/emulated/0/Download');
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
          if (io.Platform.isIOS) {
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

      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
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
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Failed to download: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachmentsAsync = widget.assignmentId == null
        ? ref.watch(roomAttachmentsProvider(widget.roomId))
        : ref.watch(assignmentAttachmentsProvider(widget.assignmentId!));

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                        const Spacer(),
                        if (_effectiveCanUpload)
                          TextButton.icon(
                            onPressed: _isUploading ? null : _pickFile,
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Upload'),
                          ),
                      ],
                    ),
                    if (_effectiveCanUpload)
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _isUploading ? null : _pickImage,
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: const Text('Image'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _isUploading ? null : _pickFile,
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                            label: const Text('PDF/File'),
                          ),
                        ],
                      ),
                    if (_isUploading)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(value: _progress),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _error!,
                          style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 12),
                    attachmentsAsync.when(
                      data: (attachments) {
                        if (widget.assignmentId == null) {
                          attachments = attachments
                              .where((a) => a.assignmentId == null)
                              .toList();
                        }

                        if (attachments.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No attachments yet.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                              ),
                            ),
                          );
                        }

                        final uploaderIds =
                            attachments.map((a) => a.uploadedBy).toSet().toList();

                        return FutureBuilder<Map<String, Map<String, dynamic>>>(
                          future: ref.read(roomRepositoryProvider).fetchProfiles(
                                uploaderIds,
                              ),
                          builder: (context, snapshot) {
                            final profiles = snapshot.data ?? {};

                            return SizedBox(
                              height: 360,
                              child: ListView.builder(
                                itemCount: attachments.length,
                                itemBuilder: (context, index) {
                                  final attachment = attachments[index];
                                  final profile = profiles[attachment.uploadedBy];
                                  final uploaderName =
                                      profile?['full_name'] as String? ?? 'Member';
                                  final timestamp = DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(attachment.createdAt);

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      attachment.fileType == 'application/pdf'
                                          ? Icons.picture_as_pdf_outlined
                                          : Icons.image_outlined,
                                      color: AppTheme.primaryColor,
                                    ),
                                    title: Text(
                                      attachment.fileName,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.95),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '$uploaderName · $timestamp',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.download_outlined),
                                      onPressed: () => _downloadAttachment(attachment),
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
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Failed to load attachments: $err',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
