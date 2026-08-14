import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/web_iframe_helper.dart';
import '../../../data/models/room_study_resource_model.dart';

class StudyResourceViewerScreen extends StatefulWidget {
  final RoomStudyResource resource;

  const StudyResourceViewerScreen({
    super.key,
    required this.resource,
  });

  @override
  State<StudyResourceViewerScreen> createState() =>
      _StudyResourceViewerScreenState();
}

class _StudyResourceViewerScreenState
    extends State<StudyResourceViewerScreen> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _errorMessage;
  late String _viewTypeId;

  @override
  void initState() {
    super.initState();
    _viewTypeId = 'iframe-doc-viewer-${widget.resource.id}';
    if (widget.resource.isPdf) {
      _loadPdf();
    } else {
      _setupOfficeViewer();
    }
  }

  String _extractStoragePath(String fileUrl) {
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('room-files');
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        return pathSegments.sublist(bucketIndex + 1).join('/');
      }
    } catch (e) {
      debugPrint('Error parsing storage path: $e');
    }
    return '';
  }

  Future<void> _loadPdf() async {
    try {
      final client = Supabase.instance.client;
      final storagePath = _extractStoragePath(widget.resource.fileUrl);

      // Strategy 1: Supabase client authenticated download (solves private bucket RLS & CORS)
      if (storagePath.isNotEmpty) {
        try {
          final bytes = await client.storage
              .from('room-files')
              .download(storagePath);
          if (mounted) {
            setState(() {
              _pdfBytes = bytes;
              _isLoading = false;
            });
            return;
          }
        } catch (storageErr) {
          debugPrint('Supabase storage download error: $storageErr');
        }
      }

      // Strategy 2: Generate fresh signed URL & fetch
      if (storagePath.isNotEmpty) {
        try {
          final freshSignedUrl = await client.storage
              .from('room-files')
              .createSignedUrl(storagePath, 3600);
          final response = await http.get(Uri.parse(freshSignedUrl));
          if (response.statusCode == 200 && mounted) {
            setState(() {
              _pdfBytes = response.bodyBytes;
              _isLoading = false;
            });
            return;
          }
        } catch (signedErr) {
          debugPrint('Fresh signed URL error: $signedErr');
        }
      }

      // Strategy 3: Standard HTTP request
      final response = await http.get(Uri.parse(widget.resource.fileUrl));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _pdfBytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Failed to load document (Status ${response.statusCode}).';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load PDF document: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _setupOfficeViewer() {
    if (kIsWeb) {
      final encodedUrl = Uri.encodeComponent(widget.resource.fileUrl);
      final embedUrl =
          'https://docs.google.com/gview?url=$encodedUrl&embedded=true';
      registerIframeViewFactory(_viewTypeId, embedUrl);
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.resource.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.resource.fileExtension.toUpperCase()} • ${widget.resource.formattedSize} (Protected Internal Preview)',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: AppTheme.surfaceColor,
        child: _buildViewerContent(),
      ),
    );
  }

  Widget _buildViewerContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Loading secure preview...',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppTheme.errorColor, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  if (widget.resource.isPdf) {
                    _loadPdf();
                  } else {
                    _setupOfficeViewer();
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.resource.isPdf && _pdfBytes != null) {
      return SfPdfViewer.memory(
        _pdfBytes!,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoadFailed: (details) {
          debugPrint('SfPdfViewer load failed: ${details.description}');
          if (mounted) {
            setState(() {
              _errorMessage =
                  'PDF render error: ${details.description} (${details.error})';
            });
          }
        },
      );
    }

    if (kIsWeb) {
      return HtmlElementView(viewType: _viewTypeId);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Icon(
                    widget.resource.isPpt
                        ? Icons.slideshow_rounded
                        : Icons.description_rounded,
                    color: AppTheme.secondaryColor,
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.resource.title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Document is protected and previewable via web browser.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
