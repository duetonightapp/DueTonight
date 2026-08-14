import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/web_iframe_helper.dart';
import '../../../data/models/room_study_resource_model.dart';
import '../../providers/room_provider.dart';
import '../../providers/study_resource_provider.dart';

class StudyResourceViewerScreen extends ConsumerStatefulWidget {
  final RoomStudyResource? resource;
  final String? roomId;
  final String? resourceId;
  final String? roomCode;

  const StudyResourceViewerScreen({
    super.key,
    this.resource,
    this.roomId,
    this.resourceId,
    this.roomCode,
  });

  @override
  ConsumerState<StudyResourceViewerScreen> createState() =>
      _StudyResourceViewerScreenState();
}

class _StudyResourceViewerScreenState
    extends ConsumerState<StudyResourceViewerScreen> {
  RoomStudyResource? _resource;
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  bool _useBlobIframe = false;
  String? _errorMessage;
  late String _viewTypeId;

  @override
  void initState() {
    super.initState();
    _resource = widget.resource;
    if (_resource != null) {
      _initResourceViewer(_resource!);
    } else {
      _fetchResourceAndJoin();
    }
  }

  Future<void> _fetchResourceAndJoin() async {
    try {
      final roomId = widget.roomId ?? '';
      final resourceId = widget.resourceId ?? '';
      final roomCode = widget.roomCode ?? '';

      // Auto-join room by code if user isn't already joined
      if (roomCode.isNotEmpty) {
        try {
          final roomRepo = ref.read(roomRepositoryProvider);
          await roomRepo.joinRoomByCode(roomCode);
        } catch (_) {
          // Silent catch if user is already a member
        }
      }

      ref.invalidate(myRoomsProvider);
      if (roomId.isNotEmpty) {
        ref.invalidate(roomStudyResourcesProvider(roomId));
      }

      final repo = ref.read(studyResourceRepositoryProvider);
      final resource = await repo.getStudyResourceById(resourceId);

      if (resource != null && mounted) {
        setState(() {
          _resource = resource;
        });
        _initResourceViewer(resource);
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Resource not found or access denied.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading study resource: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _initResourceViewer(RoomStudyResource resource) {
    _viewTypeId = 'iframe-doc-viewer-${resource.id}';
    if (resource.isPdf) {
      _loadPdf(resource);
    } else {
      _setupOfficeViewer(resource);
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

  Future<void> _loadPdf(RoomStudyResource resource) async {
    try {
      final client = Supabase.instance.client;
      final storagePath = _extractStoragePath(resource.fileUrl);

      // Strategy 1: Supabase client authenticated download
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

      // Strategy 2: Fresh signed URL fetch
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
      final response = await http.get(Uri.parse(resource.fileUrl));
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

  void _switchToBlobIframe() {
    if (kIsWeb && _pdfBytes != null) {
      try {
        final blobUrl = createBlobUrl(_pdfBytes!, 'application/pdf');
        registerIframeViewFactory(_viewTypeId, blobUrl);
        if (mounted) {
          setState(() {
            _useBlobIframe = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Blob URL creation error: $e');
      }
    }
  }

  void _setupOfficeViewer(RoomStudyResource resource) {
    if (kIsWeb) {
      final encodedUrl = Uri.encodeComponent(resource.fileUrl);
      final embedUrl =
          'https://docs.google.com/gview?url=$encodedUrl&embedded=true';
      registerIframeViewFactory(_viewTypeId, embedUrl);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildPdfLogoBadge(RoomStudyResource resource) {
    Color badgeColor;
    String badgeText;
    IconData icon;

    if (resource.isPdf) {
      badgeColor = const Color(0xFFEF4444);
      badgeText = 'PDF';
      icon = Icons.picture_as_pdf;
    } else if (resource.isPpt) {
      badgeColor = const Color(0xFFF97316);
      badgeText = 'PPT';
      icon = Icons.slideshow;
    } else {
      badgeColor = const Color(0xFF3B82F6);
      badgeText = 'DOC';
      icon = Icons.description;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          Text(
            badgeText,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
    } else {
      final targetRoomId = _resource?.roomId ?? widget.roomId ?? '';
      if (targetRoomId.isNotEmpty) {
        context.go('/rooms/$targetRoomId?initialTab=2');
      } else {
        context.go('/rooms');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resource = _resource;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: _handleBackNavigation,
          ),
          title: resource != null
              ? Row(
                  children: [
                    _buildPdfLogoBadge(resource),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            resource.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${resource.formattedSize} • Protected Internal Preview',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Text(
                  'Study Resource Preview',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
        body: Container(
          color: AppTheme.surfaceColor,
          child: _buildViewerContent(resource),
        ),
      ),
    );
  }

  Widget _buildViewerContent(RoomStudyResource? resource) {
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

    if (_errorMessage != null || resource == null) {
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
                _errorMessage ?? 'Failed to load study resource.',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleBackNavigation,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go to Room'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (resource.isPdf && _pdfBytes != null) {
      if (_useBlobIframe && kIsWeb) {
        return HtmlElementView(viewType: _viewTypeId);
      }

      return SfPdfViewer.memory(
        _pdfBytes!,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoadFailed: (details) {
          debugPrint('SfPdfViewer load failed: ${details.description}');
          if (kIsWeb) {
            _switchToBlobIframe();
          } else if (mounted) {
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
                    resource.isPpt
                        ? Icons.slideshow_rounded
                        : Icons.description_rounded,
                    color: AppTheme.secondaryColor,
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    resource.title,
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
