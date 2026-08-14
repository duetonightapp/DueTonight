import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/room_attachment_model.dart';
import '../../../core/theme/app_theme.dart';

class AttachmentViewerScreen extends StatelessWidget {
  final RoomAttachment attachment;

  const AttachmentViewerScreen({super.key, required this.attachment});

  bool get _isPdf =>
      attachment.fileType == 'application/pdf' ||
      attachment.fileName.toLowerCase().endsWith('.pdf');

  bool get _isImage => attachment.fileType.startsWith('image/');

  bool get _isWord =>
      attachment.fileType == 'application/msword' ||
      attachment.fileType ==
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
      attachment.fileName.toLowerCase().endsWith('.doc') ||
      attachment.fileName.toLowerCase().endsWith('.docx');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          attachment.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Container(
        color: AppTheme.surfaceColor,
        child: _isPdf
            ? _PdfViewer(url: attachment.fileUrl)
            : _isImage
                ? InteractiveViewer(
                    child: Center(
                      child: Image.network(
                        attachment.fileUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, _, __) => const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  )
                : _isWord
                    ? _WordPlaceholderAndDownloader(attachment: attachment)
                    : const Center(
                        child: Text(
                          'Unsupported file type',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
      ),
    );
  }
}

class _WordPlaceholderAndDownloader extends StatelessWidget {
  final RoomAttachment attachment;

  const _WordPlaceholderAndDownloader({required this.attachment});

  Future<void> _download() async {
    final uri = Uri.parse(attachment.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_rounded,
                color: Colors.blue,
                size: 72,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              attachment.fileName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Word Document',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _download,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.download_rounded),
              label: const Text(
                'Download Document',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfViewer extends StatefulWidget {
  final String url;
  const _PdfViewer({required this.url});

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  Uint8List? _bytes;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBytes();
  }

  Future<void> _fetchBytes() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _bytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load PDF (Status: ${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_bytes != null) {
      return SfPdfViewer.memory(_bytes!);
    }
    return const SizedBox();
  }
}
