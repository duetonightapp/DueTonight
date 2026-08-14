import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/room_provider.dart';
import '../../providers/study_resource_provider.dart';

class ResourceJoinHandlerScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String resourceId;
  final String roomCode;

  const ResourceJoinHandlerScreen({
    super.key,
    required this.roomId,
    required this.resourceId,
    required this.roomCode,
  });

  @override
  ConsumerState<ResourceJoinHandlerScreen> createState() =>
      _ResourceJoinHandlerScreenState();
}

class _ResourceJoinHandlerScreenState
    extends ConsumerState<ResourceJoinHandlerScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processJoinAndRedirect();
  }

  Future<void> _processJoinAndRedirect() async {
    try {
      final roomRepo = ref.read(roomRepositoryProvider);

      // Auto-join the room by code if not already joined
      if (widget.roomCode.isNotEmpty) {
        try {
          await roomRepo.joinRoomByCode(widget.roomCode);
        } catch (_) {
          // User might already be a member, continue
        }
      }

      ref.invalidate(myRoomsProvider);
      ref.invalidate(roomStudyResourcesProvider(widget.roomId));

      if (!mounted) return;

      // Directly navigate user to the Room's Study Resources Page & pass resourceId to auto-open preview
      context.go('/rooms/${widget.roomId}?initialTab=2&resourceId=${widget.resourceId}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to join room and view resource: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    const SizedBox(height: 20),
                    Text(
                      'Joining room & opening study resources...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 52,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage ?? 'An error occurred.',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/rooms/${widget.roomId}?initialTab=2'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Go to Study Resources'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
