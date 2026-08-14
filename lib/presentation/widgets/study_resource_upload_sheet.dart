import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import '../../core/theme/app_theme.dart';
import '../providers/study_resource_provider.dart';

class StudyResourceUploadSheet extends ConsumerStatefulWidget {
  final String roomId;

  const StudyResourceUploadSheet({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<StudyResourceUploadSheet> createState() =>
      _StudyResourceUploadSheetState();
}

class _StudyResourceUploadSheetState
    extends ConsumerState<StudyResourceUploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  PlatformFile? _pickedFile;
  bool _isUploading = false;
  String? _fileError;

  static const int maxFileSizeBytes = 15 * 1024 * 1024; // 15 MB
  static const List<String> allowedExtensions = [
    'pdf',
    'ppt',
    'pptx',
    'doc',
    'docx',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _fileError = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final ext = file.extension?.toLowerCase() ??
        p.extension(file.name).toLowerCase().replaceFirst('.', '');

    if (!allowedExtensions.contains(ext)) {
      setState(() {
        _fileError =
            'Unsupported file format. Please upload PDF, PPT, or DOCX files.';
      });
      return;
    }

    if (file.size > maxFileSizeBytes) {
      setState(() {
        _fileError = 'File size exceeds the 15 MB limit.';
      });
      return;
    }

    setState(() {
      _pickedFile = file;
      _fileError = null;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = p.basenameWithoutExtension(file.name);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null) {
      setState(() {
        _fileError = 'Please select a study resource file.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final repo = ref.read(studyResourceRepositoryProvider);
      final ext = _pickedFile!.extension?.toLowerCase() ?? 'pdf';
      String mimeType = 'application/octet-stream';
      if (ext == 'pdf') {
        mimeType = 'application/pdf';
      } else if (ext == 'ppt') {
        mimeType = 'application/vnd.ms-powerpoint';
      } else if (ext == 'pptx') {
        mimeType =
            'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      } else if (ext == 'doc') {
        mimeType = 'application/msword';
      } else if (ext == 'docx') {
        mimeType =
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      }

      File? localFile;
      if (!kIsWeb && _pickedFile!.path != null) {
        localFile = File(_pickedFile!.path!);
      }

      await repo.uploadAndCreateResource(
        roomId: widget.roomId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        fileName: _pickedFile!.name,
        fileType: mimeType,
        fileSize: _pickedFile!.size,
        fileBytes: _pickedFile!.bytes,
        file: localFile,
      );

      ref.invalidate(roomStudyResourcesProvider(widget.roomId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study resource uploaded successfully!'),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _fileError = 'Upload failed: $e';
        });
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload Study Resource',
                style: GoogleFonts.unbounded(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Supported formats: PPT, PDF, DOCX (Max 15 MB)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),

              // Title Field
              Text(
                'Heading / Title *',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Chapter 4 Lecture Slides',
                  hintStyle:
                      TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title for the resource';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              Text(
                'Description (Optional)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      'Provide overview, key topics, or instructions for students...',
                  hintStyle:
                      TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // File Selection Box
              InkWell(
                onTap: _isUploading ? null : _pickFile,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _fileError != null
                          ? AppTheme.errorColor
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.upload_file_rounded,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pickedFile != null
                                  ? _pickedFile!.name
                                  : 'Select File (PDF, PPT, DOCX)',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_pickedFile != null)
                              Text(
                                _formatSize(_pickedFile!.size),
                                style: GoogleFonts.inter(
                                  color: AppTheme.secondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _isUploading ? null : _pickFile,
                        child: Text(
                          _pickedFile != null ? 'Change' : 'Browse',
                          style: const TextStyle(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_fileError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _fileError!,
                  style: GoogleFonts.inter(
                    color: AppTheme.errorColor,
                    fontSize: 12,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Upload Resource',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
