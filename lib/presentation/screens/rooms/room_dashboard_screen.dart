import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/app_theme.dart';
import '../../providers/room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/room_assignment_model.dart';
import '../../../data/models/room_announcement_model.dart';
import '../../widgets/room_assignment_card.dart';
import '../../widgets/responsive_container.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../../providers/attachment_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/room_personal_reminder_model.dart';

class RoomDashboardScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomDashboardScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDashboardScreen> createState() => _RoomDashboardScreenState();
}

class _RoomDashboardScreenState extends ConsumerState<RoomDashboardScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomDetailsProvider(widget.roomId));
    final role = ref.watch(currentRoomRoleProvider(widget.roomId));
    final canPost = role == 'owner' || role == 'moderator';
    final canDelete = role == 'owner' || role == 'moderator';

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final isDesktop = width >= 1024;

    return roomAsync.when(
      data: (room) {
        return Scaffold(
          appBar: AppBar(
            leading: Navigator.of(context).canPop()
                ? null
                : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        color: const Color(0xFFF9F6F0),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
            centerTitle: true,
            title: Text(
              '${room.branch} - #${room.roomCode}',
              style: GoogleFonts.unbounded(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'details') {
                    _showRoomDetails(context, room);
                  } else if (value == 'switch') {
                    context.push('/rooms');
                  } else if (value == 'logout') {
                    _signOut(context, ref);
                  } else if (value == 'delete') {
                    _confirmDeleteRoom(context, ref, widget.roomId);
                  }
                },
                color: AppTheme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white.withOpacity(0.6),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Text('Room Details'),
                  ),
                  if (!Navigator.of(context).canPop()) ...[
                    const PopupMenuItem(
                      value: 'switch',
                      child: Text('Switch Rooms'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Log Out'),
                    ),
                  ],
                  if (canDelete)
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete Room',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: Container(
            color: Colors.black,
            child: Row(
              children: [
                if (!isMobile) ...[
                  NavigationRail(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    backgroundColor: AppTheme.surfaceColor,
                    extended: isDesktop,
                    labelType: isDesktop ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                    unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.4)),
                    selectedIconTheme: const IconThemeData(color: AppTheme.secondaryColor),
                    unselectedLabelTextStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                    selectedLabelTextStyle: const TextStyle(color: AppTheme.secondaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.assignment_outlined),
                        selectedIcon: Icon(Icons.assignment_rounded),
                        label: Text('Assignments'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.campaign_outlined),
                        selectedIcon: Icon(Icons.campaign_rounded),
                        label: Text('Announcements'),
                      ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
                ],
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    children: [
                      ResponsiveContainer(
                        child: _RoomHomeTab(
                          roomId: widget.roomId,
                          onSwitchTab: (index) {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                      ResponsiveContainer(
                        child: _RoomAssignmentsTab(roomId: widget.roomId),
                      ),
                      ResponsiveContainer(
                        child: _RoomAnnouncementsTab(
                          roomId: widget.roomId,
                          onSwitchTab: (index) {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: (canPost && (_currentIndex == 1 || _currentIndex == 2))
              ? FloatingActionButton(
                  onPressed: () {
                    if (_currentIndex == 1) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => RoomAssignmentSheet(roomId: widget.roomId),
                      );
                    } else if (_currentIndex == 2) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => RoomAnnouncementSheet(roomId: widget.roomId),
                      );
                    }
                  },
                  backgroundColor: AppTheme.primaryColor,
                  child: const Icon(Icons.add_rounded, size: 28),
                )
              : null,
          bottomNavigationBar: isMobile ? _buildBottomNavBar(context) : null,
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Failed to load room',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$err',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavBarItem(0, Icons.home_rounded, Icons.home_outlined),
            _buildNavBarItem(1, Icons.assignment_rounded, Icons.assignment_outlined),
            _buildNavBarItem(2, Icons.campaign_rounded, Icons.campaign_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isActive = _currentIndex == index;
    final color = isActive ? AppTheme.secondaryColor : Colors.white.withOpacity(0.4);
    return InkWell(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: isActive
            ? BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondaryColor.withOpacity(0.08),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              )
            : null,
        child: Icon(
          isActive ? activeIcon : inactiveIcon,
          color: color,
          size: 24,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteRoom(
    BuildContext context,
    WidgetRef ref,
    String roomId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete room?'),
          content: const Text(
            'This will permanently delete the room and all related data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final repo = ref.read(roomRepositoryProvider);
    try {
      await repo.deleteRoom(roomId: roomId);
      if (!context.mounted) return;
      ref.invalidate(myRoomsProvider);
      context.go('/');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete room: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out',
          style: GoogleFonts.unbounded(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of DueTonight?',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
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
              'Log Out',
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
      ref.invalidate(myRoomsProvider);
      await ref.read(authStateProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully!'),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  static void _showRoomDetails(BuildContext context, dynamic room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.15),
                                  AppTheme.primaryColor.withOpacity(0.05),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Room Details',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _DetailRow(label: 'College', value: room.collegeName),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Branch', value: room.branch),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Semester', value: room.semester),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Division', value: room.division),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Room Code',
                        value: room.roomCode,
                        isHighlighted: true,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cardColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: Colors.white.withOpacity(0.06)),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.book_outlined, size: 20),
                              label: const Text('Subjects'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => FractionallySizedBox(
                                    heightFactor: 0.8,
                                    child: _RoomSubjectsSheet(roomId: room.id),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cardColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: Colors.white.withOpacity(0.06)),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.people_outlined, size: 20),
                              label: const Text('Members'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => FractionallySizedBox(
                                    heightFactor: 0.8,
                                    child: _RoomMembersSheet(roomId: room.id),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void _showCreateMenu(BuildContext context, String roomId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.15),
                          AppTheme.primaryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Create Post',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.assignment_outlined,
                title: 'New Assignment',
                subtitle: 'Post a new assignment for the room',
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => RoomAssignmentSheet(roomId: roomId),
                  );
                },
              ),
              const SizedBox(height: 4),
              _MenuTile(
                icon: Icons.campaign_outlined,
                title: 'New Announcement',
                subtitle: 'Share an announcement with the room',
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => RoomAnnouncementSheet(roomId: roomId),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.white.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }
}


class _RoomAssignmentsTab extends ConsumerStatefulWidget {
  final String roomId;

  const _RoomAssignmentsTab({super.key, required this.roomId});

  @override
  ConsumerState<_RoomAssignmentsTab> createState() => _RoomAssignmentsTabState();
}

class _RoomAssignmentsTabState extends ConsumerState<_RoomAssignmentsTab> {
  bool _isBySubject = true;

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(roomAssignmentsProvider(widget.roomId));
    final subjectsAsync = ref.watch(roomSubjectsProvider(widget.roomId));

    return Column(
      children: [
        const SizedBox(height: 16),
        // Toggle Switcher (Segmented Control)
        Center(
          child: Container(
            width: 350,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBySubject = true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isBySubject
                            ? Colors.white.withOpacity(0.06)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'By Subject',
                        style: GoogleFonts.inter(
                          color: _isBySubject ? Colors.white : Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBySubject = false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: !_isBySubject
                            ? Colors.white.withOpacity(0.06)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'By Priority',
                        style: GoogleFonts.inter(
                          color: !_isBySubject ? Colors.white : Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: assignmentsAsync.when(
            data: (assignments) {
              if (assignments.isEmpty) {
                return const _EmptyState(
                  icon: Icons.assignment_outlined,
                  message: 'No assignments posted yet.',
                  subtitle: 'Assignments from your room will appear here.',
                );
              }

              if (_isBySubject) {
                // By Subject grouping view
                return subjectsAsync.when(
                  data: (subjects) {
                    final subjectIds = subjects.map((s) => s.id).toSet();
                    final assignmentsBySubjectId = <String, List<RoomAssignment>>{};
                    final orphanedAssignments = <RoomAssignment>[];
                    for (final assignment in assignments) {
                      final key = assignment.subjectId;
                      if (key == null || !subjectIds.contains(key)) {
                        orphanedAssignments.add(assignment);
                        continue;
                      }
                      assignmentsBySubjectId.putIfAbsent(key, () => []);
                      assignmentsBySubjectId[key]!.add(assignment);
                    }

                    final widgets = <Widget>[];
                    for (final subject in subjects) {
                      final subjectAssignments = assignmentsBySubjectId[subject.id] ?? [];

                      widgets.add(
                        _SubjectTile(
                          title: subject.name,
                          count: subjectAssignments.length,
                          onTap: () {
                            context.push('/rooms/${widget.roomId}/subjects/${subject.id}');
                          },
                        ),
                      );
                    }

                    if (orphanedAssignments.isNotEmpty) {
                      widgets.add(
                        _SubjectTile(
                          title: 'Other',
                          count: orphanedAssignments.length,
                          onTap: () {
                            context.push('/rooms/${widget.roomId}/subjects/other');
                          },
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      children: widgets,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => _ErrorState(message: '$err'),
                );
              } else {
                // By Priority grouping view
                final highPriority = <RoomAssignment>[];
                final medPriority = <RoomAssignment>[];
                final lowPriority = <RoomAssignment>[];

                for (final a in assignments) {
                  final priority = a.deadline != null ? _getPriority(a.deadline!) : 'LOW';
                  if (priority == 'HIGH') {
                    highPriority.add(a);
                  } else if (priority == 'MEDIUM') {
                    medPriority.add(a);
                  } else {
                    lowPriority.add(a);
                  }
                }

                // Sort lists by deadline
                final sorter = (RoomAssignment a, RoomAssignment b) {
                  if (a.deadline == null) return 1;
                  if (b.deadline == null) return -1;
                  return a.deadline!.compareTo(b.deadline!);
                };
                highPriority.sort(sorter);
                medPriority.sort(sorter);
                lowPriority.sort(sorter);

                final widgets = <Widget>[];

                if (highPriority.isNotEmpty) {
                  widgets.add(const _PriorityHeader(title: 'HIGH PRIORITY', color: AppTheme.overdueColor));
                  widgets.addAll(highPriority.map((a) => RoomAssignmentCard(assignment: a)));
                }
                if (medPriority.isNotEmpty) {
                  widgets.add(const _PriorityHeader(title: 'MEDIUM PRIORITY', color: AppTheme.urgentColor));
                  widgets.addAll(medPriority.map((a) => RoomAssignmentCard(assignment: a)));
                }
                if (lowPriority.isNotEmpty) {
                  widgets.add(const _PriorityHeader(title: 'LOW PRIORITY', color: AppTheme.safeColor));
                  widgets.addAll(lowPriority.map((a) => RoomAssignmentCard(assignment: a)));
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  children: widgets,
                );
              }
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _ErrorState(message: '$err'),
          ),
        ),
      ],
    );
  }

  String _getPriority(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative || difference.inDays <= 1) {
      return 'HIGH';
    } else if (difference.inDays <= 4) {
      return 'MEDIUM';
    } else {
      return 'LOW';
    }
  }
}

class _PriorityHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _PriorityHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomSubjectsTab extends ConsumerWidget {
  final String roomId;

  const _RoomSubjectsTab({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(roomSubjectsProvider(roomId));
    final assignmentsAsync = ref.watch(roomAssignmentsProvider(roomId));

    return subjectsAsync.when(
      data: (subjects) {
        if (subjects.isEmpty) {
          return _EmptyState(
            icon: Icons.menu_book_outlined,
            message: 'No subjects yet.',
            subtitle: 'Subjects added during room creation appear here.',
          );
        }

        return assignmentsAsync.when(
          data: (assignments) {
            final subjectIds = subjects.map((s) => s.id).toSet();
            final assignmentsBySubjectId = <String, List<RoomAssignment>>{};
            final orphanedAssignments = <RoomAssignment>[];
            for (final assignment in assignments) {
              final key = assignment.subjectId;
              if (key == null || !subjectIds.contains(key)) {
                orphanedAssignments.add(assignment);
                continue;
              }
              assignmentsBySubjectId.putIfAbsent(key, () => []);
              assignmentsBySubjectId[key]!.add(assignment);
            }

            for (final list in assignmentsBySubjectId.values) {
              list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            }

            final widgets = <Widget>[];
            for (final subject in subjects) {
              final subjectAssignments =
                  assignmentsBySubjectId[subject.id] ?? [];

              widgets.add(
                _SubjectHeader(
                  title: subject.name,
                  count: subjectAssignments.length,
                ),
              );

              if (subjectAssignments.isEmpty) {
                widgets.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'No assignments yet.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              } else {
                widgets.addAll(
                  subjectAssignments
                      .map(
                        (assignment) =>
                            RoomAssignmentCard(assignment: assignment),
                      )
                      .toList(),
                );
              }
            }

            if (orphanedAssignments.isNotEmpty) {
              orphanedAssignments.sort(
                (a, b) => b.createdAt.compareTo(a.createdAt),
              );
              widgets.add(
                _SubjectHeader(
                  title: 'Other',
                  count: orphanedAssignments.length,
                ),
              );
              widgets.addAll(
                orphanedAssignments
                    .map(
                      (assignment) =>
                          RoomAssignmentCard(assignment: assignment),
                    )
                    .toList(),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: widgets,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorState(message: '$err'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(message: '$err'),
    );
  }
}

class _RoomMembersTab extends ConsumerWidget {
  final String roomId;

  const _RoomMembersTab({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(roomMembersProvider(roomId));
    final role = ref.watch(currentRoomRoleProvider(roomId));
    final repo = ref.read(roomRepositoryProvider);
    final canManage = role == 'owner' || role == 'moderator';

    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return _EmptyState(
            icon: Icons.people_outlined,
            message: 'No members yet.',
            subtitle: 'Members of your room will appear here.',
          );
        }

        final userIds = members.map((m) => m.userId).toList();

        return FutureBuilder<Map<String, Map<String, dynamic>>>(
          future: repo.fetchProfiles(userIds),
          builder: (context, snapshot) {
            final profiles = snapshot.data ?? {};

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final profile = profiles[member.userId];
                final rawName = profile?['full_name'] as String?;
                final displayName =
                    (rawName != null && rawName.trim().isNotEmpty)
                    ? rawName.trim()
                    : 'Member';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.15),
                              AppTheme.primaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: member.role == 'owner'
                              ? AppTheme.primaryColor.withOpacity(0.12)
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          member.role.toUpperCase(),
                          style: TextStyle(
                            color: member.role == 'owner'
                                ? AppTheme.primaryColor
                                : Colors.white.withOpacity(0.4),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      trailing: () {
                        // Check if current user can manage the target member
                        final isCurrentUserOwner = role == 'owner';
                        final isCurrentUserModerator = role == 'moderator';
                        final isTargetOwner = member.role == 'owner';
                        final isTargetModerator = member.role == 'moderator';
                        final isTargetStudent = member.role == 'student';

                        // Owner can manage everyone except themselves
                        // Moderator can only manage students
                        final allowedToManage = isCurrentUserOwner && !isTargetOwner ||
                                                isCurrentUserModerator && isTargetStudent;

                        if (!canManage || !allowedToManage) return null;

                        return PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'transfer') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppTheme.cardColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text('Transfer Ownership', style: GoogleFonts.unbounded(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                  content: const Text('Are you sure you want to transfer ownership of the room? You will become a student.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Transfer', style: TextStyle(color: AppTheme.errorColor)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await repo.transferOwnership(
                                  roomId: roomId,
                                  newOwnerId: member.userId,
                                );
                                ref.invalidate(roomMembersProvider(roomId));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ownership transferred successfully!'),
                                      backgroundColor: AppTheme.safeColor,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            } else if (value == 'remove') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppTheme.cardColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text('Remove Member', style: GoogleFonts.unbounded(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                  content: Text('Are you sure you want to remove $displayName from the room?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Remove', style: TextStyle(color: AppTheme.errorColor)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                try {
                                  await repo.removeMember(
                                    roomId: roomId,
                                    userId: member.userId,
                                  );
                                  ref.invalidate(roomMembersProvider(roomId));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Member removed successfully!'),
                                        backgroundColor: AppTheme.safeColor,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to remove member: $e'),
                                        backgroundColor: AppTheme.errorColor,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              }
                            } else {
                              await repo.updateMemberRole(
                                roomId: roomId,
                                userId: member.userId,
                                role: value,
                              );
                              ref.invalidate(roomMembersProvider(roomId));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Role updated to $value successfully!'),
                                    backgroundColor: AppTheme.safeColor,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          color: AppTheme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white.withOpacity(0.4),
                            size: 20,
                          ),
                          itemBuilder: (context) => [
                            if (isCurrentUserOwner && isTargetStudent)
                              PopupMenuItem(
                                value: 'moderator',
                                child: Text(
                                  'Make Moderator',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                                ),
                              ),
                            if (isCurrentUserOwner && isTargetModerator)
                              PopupMenuItem(
                                value: 'student',
                                child: Text(
                                  'Make Student',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                                ),
                              ),
                            if (isCurrentUserOwner)
                              PopupMenuItem(
                                value: 'transfer',
                                child: Text(
                                  'Transfer Ownership',
                                  style: TextStyle(
                                    color: AppTheme.errorColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            PopupMenuItem(
                              value: 'remove',
                              child: const Text(
                                'Remove Member',
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      }(),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(message: '$err'),
    );
  }
}


class _SubjectHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SubjectHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.unbounded(
                color: Colors.white.withOpacity(0.95),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onTap;

  const _SubjectTile({
    required this.title,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.cardColor,
                AppTheme.cardColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_open_outlined,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count ${count == 1 ? "assignment" : "assignments"}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.white.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _AnnouncementCard extends ConsumerWidget {
  final RoomAnnouncement announcement;
  final Function(int)? onSwitchTab;

  const _AnnouncementCard({required this.announcement, this.onSwitchTab});

  String _classifyAnnouncement(String title, String body) {
    final text = '$title $body'.toLowerCase();
    if (text.contains('urgent') ||
        text.contains('midterm') ||
        text.contains('exam') ||
        text.contains('test') ||
        text.contains('alert') ||
        text.contains('important') ||
        text.contains('warn')) {
      return 'URGENT';
    } else if (text.contains('assignment') ||
        text.contains('project') ||
        text.contains('homework') ||
        text.contains('submission') ||
        text.contains('task') ||
        text.contains('due')) {
      return 'ASSIGNMENT';
    } else {
      return 'GENERAL';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'URGENT':
        return AppTheme.overdueColor;
      case 'ASSIGNMENT':
        return AppTheme.secondaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'URGENT':
        return Icons.warning_amber_rounded;
      case 'ASSIGNMENT':
        return Icons.assignment_outlined;
      default:
        return Icons.campaign_rounded;
    }
  }

  Future<void> _downloadAndOpenFile(BuildContext context, String fileUrl, String fileName) async {
    try {
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
              Text('Opening attachment...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final savePath = p.join(tempDir.path, fileName);

      await dio.download(fileUrl, savePath);

      await OpenFilex.open(savePath);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open document: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildAttachmentTile(BuildContext context, String url) {
    final fileName = p.basename(Uri.parse(url).path);
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        onTap: () => _downloadAndOpenFile(context, url, fileName),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isPdf ? AppTheme.overdueColor : AppTheme.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined,
                  color: isPdf ? AppTheme.overdueColor : AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPdf ? 'PDF Document • 1.2 MB' : 'Attachment • File',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.download_rounded,
                color: Colors.white.withOpacity(0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAnnouncement(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Announcement',
          style: GoogleFonts.unbounded(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this announcement?',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
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
        await ref.read(roomRepositoryProvider).deleteAnnouncement(announcement.id);
        ref.invalidate(roomAnnouncementsProvider(announcement.roomId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement deleted successfully!'),
              backgroundColor: AppTheme.safeColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete announcement: $e'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoomRoleProvider(announcement.roomId));
    final canDelete = role == 'owner' || role == 'moderator';

    final category = _classifyAnnouncement(announcement.title, announcement.body);
    final categoryColor = _getCategoryColor(category);
    final categoryIcon = _getCategoryIcon(category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              categoryColor.withOpacity(0.05),
              AppTheme.cardColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: categoryColor.withOpacity(0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: categoryColor,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    categoryIcon,
                                    size: 14,
                                    color: categoryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    category,
                                    style: GoogleFonts.inter(
                                      color: categoryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 18),
                                onPressed: () => _deleteAnnouncement(context, ref),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Text(
                          announcement.title,
                          style: GoogleFonts.unbounded(
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          announcement.body,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        if (announcement.attachmentPath != null &&
                            announcement.attachmentPath!.isNotEmpty)
                          _buildAttachmentTile(context, announcement.attachmentPath!),
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.06),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<Map<String, Map<String, dynamic>>>(
                          future: ref.read(roomRepositoryProvider).fetchProfiles([announcement.createdBy]),
                          builder: (context, snapshot) {
                            final profiles = snapshot.data ?? {};
                            final profile = profiles[announcement.createdBy];
                            final rawName = profile?['full_name'] as String?;
                            final displayName =
                                (rawName != null && rawName.trim().isNotEmpty)
                                ? rawName.trim()
                                : 'Professor';

                            return Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor.withOpacity(0.2),
                                        AppTheme.primaryColor.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        _getTimeAgoText(announcement.createdAt),
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (category == 'ASSIGNMENT' && onSwitchTab != null)
                                  TextButton(
                                    onPressed: () => onSwitchTab!(1),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'View Assignment',
                                          style: GoogleFonts.inter(
                                            color: AppTheme.secondaryColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: AppTheme.secondaryColor,
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgoText(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class RoomAssignmentSheet extends ConsumerStatefulWidget {
  final String roomId;

  const RoomAssignmentSheet({super.key, required this.roomId});

  @override
  ConsumerState<RoomAssignmentSheet> createState() =>
      _RoomAssignmentSheetState();
}

class _RoomAssignmentSheetState extends ConsumerState<RoomAssignmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  DateTime? _deadline;
  bool _isLoading = false;
  final List<PlatformFile> _selectedFiles = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result == null) return;
    
    final bytes = await result.readAsBytes();
    final size = bytes.length;
    if (size > 5 * 1024 * 1024) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('File size exceeds the 5MB limit.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _selectedFiles.add(PlatformFile(
        name: result.name,
        size: size,
        bytes: bytes,
        path: kIsWeb ? null : result.path,
      ));
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result == null) return;
    
    final file = result.files.single;
    final ext = p.extension(file.name).toLowerCase().replaceFirst('.', '');
    
    if (!['pdf', 'jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('Unsupported file type. Please select a PDF or an Image.'),
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
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('File size exceeds the 5MB limit.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _selectedFiles.add(PlatformFile(
        name: file.name,
        size: size,
        bytes: bytes,
        path: kIsWeb ? null : file.path,
      ));
    });
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    if (_selectedSubjectId == null || _selectedSubjectName == null) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('Select a subject first.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(roomRepositoryProvider);

    try {
      final assignmentId = await repo.createAssignment(
        roomId: widget.roomId,
        title: _titleController.text.trim(),
        subjectId: _selectedSubjectId!,
        subjectName: _selectedSubjectName!,
        description: _descriptionController.text.trim(),
        deadline: _deadline,
      );

      if (_selectedFiles.isNotEmpty) {
        final uploadService = ref.read(cloudinaryUploadServiceProvider);
        final attachmentRepo = ref.read(roomAttachmentRepositoryProvider);

        for (final file in _selectedFiles) {
          final fileName = file.name;
          final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

          final uploadResult = await uploadService.uploadFile(
            fileBytes: file.bytes!,
            roomId: widget.roomId,
            fileName: fileName,
            onProgress: (_) {},
          );

          await attachmentRepo.createAttachment(
            roomId: widget.roomId,
            assignmentId: assignmentId,
            fileName: fileName,
            fileUrl: uploadResult.url,
            fileType: mimeType,
          );
        }
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment posted successfully!'),
            backgroundColor: AppTheme.safeColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Failed to post assignment: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.surfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.surfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final deadlineText = _deadline == null
        ? 'Set deadline'
        : DateFormat('dd MMM yyyy, hh:mm a').format(_deadline!);
    final subjectsAsync = ref.watch(roomSubjectsProvider(widget.roomId));
    final canSubmit = !_isLoading && _selectedSubjectId != null;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.15),
                                  AppTheme.primaryColor.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.assignment_outlined,
                              color: AppTheme.primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'New Assignment',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter assignment title',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      subjectsAsync.when(
                        data: (subjects) {
                          if (subjects.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'No subjects available for this room.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            value: _selectedSubjectId,
                            items: subjects
                                .map(
                                  (subject) => DropdownMenuItem<String>(
                                    value: subject.id,
                                    child: Text(subject.name),
                                  ),
                                )
                                .toList(),
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    final selected = subjects.firstWhere(
                                      (subject) => subject.id == value,
                                    );
                                    setState(() {
                                      _selectedSubjectId = value;
                                      _selectedSubjectName = selected.name;
                                    });
                                  },
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                              hintText: 'Select subject',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                  return 'Select a subject';
                              }
                              return null;
                            },
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Failed to load subjects: $err',
                            style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe the assignment',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.inputFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: TextButton.icon(
                            onPressed: _pickDeadline,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                            ),
                            icon: const Icon(Icons.schedule_rounded, size: 18),
                            label: Text(
                              deadlineText,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: _deadline == null
                                    ? Colors.white.withOpacity(0.5)
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Attachments',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _isLoading ? null : _pickImage,
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: const Text('Add Image'),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                          ),
                          TextButton.icon(
                            onPressed: _isLoading ? null : _pickFile,
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                            label: const Text('Add PDF/File'),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                      if (_selectedFiles.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _selectedFiles.length,
                            itemBuilder: (context, index) {
                              final file = _selectedFiles[index];
                              final fileName = file.name;
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                leading: Icon(
                                  p.extension(fileName).toLowerCase() == '.pdf'
                                      ? Icons.picture_as_pdf_outlined
                                      : Icons.image_outlined,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                title: Text(
                                  fileName,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                                  onPressed: _isLoading ? null : () => _removeFile(index),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: canSubmit ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cardColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Post Assignment',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: 0.2,
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
      ),
    );
  }
}

class RoomAnnouncementSheet extends ConsumerStatefulWidget {
  final String roomId;

  const RoomAnnouncementSheet({super.key, required this.roomId});

  @override
  ConsumerState<RoomAnnouncementSheet> createState() =>
      _RoomAnnouncementSheetState();
}

class _RoomAnnouncementSheetState extends ConsumerState<RoomAnnouncementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);
    final repo = ref.read(roomRepositoryProvider);

    try {
      await repo.createAnnouncement(
        roomId: widget.roomId,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement posted successfully!'),
            backgroundColor: AppTheme.safeColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Failed to post announcement: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.secondaryColor.withOpacity(0.15),
                                  AppTheme.secondaryColor.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.campaign_outlined,
                              color: AppTheme.secondaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'New Announcement',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter announcement title',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _bodyController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: 'Announcement',
                          hintText: 'Write your announcement...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter the announcement';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.secondaryColor,
                              AppTheme.secondaryColor.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cardColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Post Announcement',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: 0.2,
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
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                    color: isHighlighted
                        ? AppTheme.primaryColor
                        : Colors.white.withOpacity(0.9),
                    letterSpacing: isHighlighted ? 0.5 : 0,
                  ),
                ),
              ),
              if (isHighlighted) ...[
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final origin = kIsWeb ? Uri.base.origin : 'https://my.duetonight.app';
                      final joinLink = '$origin/rooms/join?code=$value';
                      await Clipboard.setData(ClipboardData(text: joinLink));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Join link copied to clipboard!'),
                            backgroundColor: AppTheme.primaryColor,
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      if (!kIsWeb) {
                        await Share.share('Join my classroom room on DueTonight!\nLink: $joinLink');
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.share_rounded,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.3),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _RoomHomeTab extends ConsumerWidget {
  final String roomId;
  final Function(int) onSwitchTab;

  const _RoomHomeTab({
    required this.roomId,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final roomAsync = ref.watch(roomDetailsProvider(roomId));
    final assignmentsAsync = ref.watch(roomAssignmentsProvider(roomId));
    final announcementsAsync = ref.watch(roomAnnouncementsProvider(roomId));
    final role = ref.watch(currentRoomRoleProvider(roomId));
    final canPost = role == 'owner' || role == 'moderator';

    return roomAsync.when(
      data: (room) {
        return assignmentsAsync.when(
          data: (assignments) {
            return announcementsAsync.when(
              data: (announcements) {
                final completedIds = ref.watch(completedAssignmentsProvider);
                final pendingAssignments = assignments.where((a) => !completedIds.contains(a.id)).toList();
                final totalAssignmentsCount = pendingAssignments.length;

                // Sort upcoming assignments by nearest deadline first
                final upcoming = List<RoomAssignment>.from(pendingAssignments)
                  ..sort((a, b) {
                    if (a.deadline == null) return 1;
                    if (b.deadline == null) return -1;
                    return a.deadline!.compareTo(b.deadline!);
                  });

                // Take top 2 upcoming
                final topUpcoming = upcoming.take(2).toList();

                // Get latest announcement (filtering out calendar events)
                final regularAnnouncements = announcements.where((a) => !a.title.startsWith('[CalendarEvent]:')).toList();
                final latestAnnouncement = regularAnnouncements.isNotEmpty ? regularAnnouncements.first : null;

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(roomAssignmentsProvider(roomId));
                    ref.invalidate(roomAnnouncementsProvider(roomId));
                    ref.invalidate(roomDetailsProvider(roomId));
                    ref.invalidate(roomMembersProvider(roomId));
                    ref.invalidate(roomSubjectsProvider(roomId));
                  },
                  color: AppTheme.primaryColor,
                  backgroundColor: AppTheme.cardColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting Section
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, ${user?.fullName.isNotEmpty == true ? user!.fullName : "Student"}',
                                    style: GoogleFonts.unbounded(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'What do you want to do today?',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: Colors.white.withOpacity(0.5),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Bento Grid Layout
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Stats Card)
                            Expanded(
                              child: InkWell(
                                onTap: () => onSwitchTab(1),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  height: canPost ? 112 : 120,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.cardColor,
                                        AppTheme.cardColor.withOpacity(0.6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.06),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Assignments',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.5),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '$totalAssignmentsCount',
                                        style: GoogleFonts.unbounded(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          Text(
                                            'VIEW ALL',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primaryColor,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 12,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (canPost) ...[
                              const SizedBox(width: 16),
                              // Right Column (New Assignment Card)
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => RoomAssignmentSheet(roomId: roomId),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    height: 169,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.cardColor,
                                          AppTheme.cardColor.withOpacity(0.6),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.06),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                AppTheme.primaryColor.withOpacity(0.2),
                                                AppTheme.primaryColor.withOpacity(0.05),
                                              ],
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.add_task_rounded,
                                              color: AppTheme.primaryColor,
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'New\nAssignment',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.unbounded(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Upcoming Assignments Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Upcoming Assignments',
                              style: GoogleFonts.unbounded(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            TextButton(
                              onPressed: () => onSwitchTab(1),
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'See all',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.4),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (topUpcoming.isEmpty)
                          const _EmptyState(
                            icon: Icons.assignment_outlined,
                            message: 'No upcoming assignments',
                            subtitle: 'Great job! You are all caught up.',
                          )
                        else
                          ...topUpcoming.map((assignment) {
                            final remainingText = assignment.deadline != null
                                ? _getRemainingTimeText(assignment.deadline!)
                                : 'No deadline';
                            final priority = assignment.deadline != null
                                ? _getPriority(assignment.deadline!)
                                : 'LOW';
                            final priorityColor = _getPriorityColor(priority);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  context.push('/rooms/${assignment.roomId}/assignments/${assignment.id}');
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.cardColor,
                                        AppTheme.cardColor.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.06),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    assignment.title,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white.withOpacity(0.95),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: Icon(
                                                Icons.check_circle_outline_rounded,
                                                color: AppTheme.safeColor.withOpacity(0.7),
                                                size: 22,
                                              ),
                                              onPressed: () async {
                                                final confirmed = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    backgroundColor: AppTheme.cardColor,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    title: Text(
                                                      'Mark as Completed',
                                                      style: GoogleFonts.unbounded(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    content: Text(
                                                      'Are you sure you want to mark this assignment as completed? It will be removed from your home feed.',
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white.withOpacity(0.7),
                                                        fontSize: 14,
                                                      ),
                                                    ),
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
                                                          'Complete',
                                                          style: GoogleFonts.inter(
                                                            color: AppTheme.safeColor,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirmed == true) {
                                                  await ref
                                                      .read(completedAssignmentsProvider.notifier)
                                                      .markCompleted(assignment.id);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Assignment marked as completed!'),
                                                        backgroundColor: AppTheme.safeColor,
                                                        behavior: SnackBarBehavior.floating,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: priorityColor.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                priority,
                                                style: TextStyle(
                                                  color: priorityColor,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          height: 1,
                                          color: Colors.white.withOpacity(0.06),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (assignment.subject != null &&
                                                assignment.subject!.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  assignment.subject!,
                                                  style: TextStyle(
                                                    color: AppTheme.primaryColor,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              )
                                            else
                                              const SizedBox(),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_outlined,
                                                  size: 14,
                                                  color: Colors.white.withOpacity(0.4),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  remainingText,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white.withOpacity(0.45),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 28),

                        // Recent Announcements Section
                        Text(
                          'Recent Announcements',
                          style: GoogleFonts.unbounded(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (latestAnnouncement == null)
                          const _EmptyState(
                            icon: Icons.campaign_outlined,
                            message: 'No announcements yet',
                            subtitle: 'Updates from professor will appear here.',
                          )
                        else
                          FutureBuilder<Map<String, Map<String, dynamic>>>(
                            future: ref.read(roomRepositoryProvider).fetchProfiles([latestAnnouncement.createdBy]),
                            builder: (context, snapshot) {
                              final profiles = snapshot.data ?? {};
                              final profile = profiles[latestAnnouncement.createdBy];
                              final rawName = profile?['full_name'] as String?;
                              final displayName =
                                  (rawName != null && rawName.trim().isNotEmpty)
                                  ? rawName.trim()
                                  : 'Professor';

                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.secondaryColor.withOpacity(0.05),
                                      AppTheme.cardColor,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppTheme.secondaryColor.withOpacity(0.08),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppTheme.secondaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.campaign_rounded,
                                              size: 18,
                                              color: AppTheme.secondaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'From $displayName • ${_getTimeAgoText(latestAnnouncement.createdAt)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: Colors.white.withOpacity(0.5),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        latestAnnouncement.title,
                                        style: GoogleFonts.unbounded(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.95),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        latestAnnouncement.body,
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.65),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorState(message: '$err'),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorState(message: '$err'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(message: '$err'),
    );
  }

  String _getTimeAgoText(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  String _getRemainingTimeText(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays == 0) {
      if (difference.inHours > 0) {
        return 'Due in ${difference.inHours}h';
      } else {
        return 'Due in ${difference.inMinutes}m';
      }
    } else if (difference.inDays == 1) {
      return 'Due tomorrow';
    } else if (difference.inDays < 7) {
      return 'Due in ${difference.inDays} days';
    } else {
      final weeks = (difference.inDays / 7).round();
      return 'Due in $weeks ${weeks == 1 ? "week" : "weeks"}';
    }
  }

  String _getPriority(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative || difference.inDays <= 1) {
      return 'HIGH';
    } else if (difference.inDays <= 4) {
      return 'MEDIUM';
    } else {
      return 'LOW';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'HIGH':
        return AppTheme.overdueColor;
      case 'MEDIUM':
        return AppTheme.urgentColor;
      default:
        return AppTheme.safeColor;
    }
  }
}

class _AddCalendarEventSheet extends ConsumerStatefulWidget {
  final String roomId;
  final DateTime date;

  const _AddCalendarEventSheet({
    required this.roomId,
    required this.date,
  });

  @override
  ConsumerState<_AddCalendarEventSheet> createState() => __AddCalendarEventSheetState();
}

class __AddCalendarEventSheetState extends ConsumerState<_AddCalendarEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isGeneralEvent = true;

  @override
  void initState() {
    super.initState();
    // Default to general event if owner/moderator, otherwise personal reminder
    final role = ref.read(currentRoomRoleProvider(widget.roomId));
    _isGeneralEvent = (role == 'owner' || role == 'moderator');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);

    try {
      if (_isGeneralEvent) {
        final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
        final formattedTitle = '[CalendarEvent]:$dateStr | ${_titleController.text.trim()}';

        await ref.read(roomRepositoryProvider).createAnnouncement(
          roomId: widget.roomId,
          title: formattedTitle,
          body: _descriptionController.text.trim(),
        );

        ref.invalidate(roomAnnouncementsProvider(widget.roomId));
      } else {
        await ref.read(roomRepositoryProvider).createPersonalReminder(
          roomId: widget.roomId,
          title: _titleController.text.trim(),
          body: _descriptionController.text.trim(),
          date: widget.date,
        );

        ref.invalidate(roomPersonalRemindersProvider(widget.roomId));
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isGeneralEvent
                ? 'Academic reminder assigned successfully!'
                : 'Personal reminder added successfully!'),
            backgroundColor: AppTheme.safeColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to assign reminder: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMMM yyyy').format(widget.date);
    final role = ref.watch(currentRoomRoleProvider(widget.roomId));
    final canPostGeneral = role == 'owner' || role == 'moderator';

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
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        canPostGeneral ? 'Add Reminder' : 'Add Own Reminder',
                        style: GoogleFonts.unbounded(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: $formattedDate',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (canPostGeneral) ...[
                        Text(
                          'Reminder Type',
                          style: GoogleFonts.unbounded(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isGeneralEvent = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isGeneralEvent
                                        ? AppTheme.primaryColor.withOpacity(0.15)
                                        : AppTheme.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isGeneralEvent
                                          ? AppTheme.primaryColor
                                          : Colors.white.withOpacity(0.06),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'General Room',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _isGeneralEvent ? AppTheme.primaryColor : Colors.white60,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isGeneralEvent = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isGeneralEvent
                                        ? AppTheme.safeColor.withOpacity(0.15)
                                        : AppTheme.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: !_isGeneralEvent
                                          ? AppTheme.safeColor
                                          : Colors.white.withOpacity(0.06),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Own Reminder',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: !_isGeneralEvent ? AppTheme.safeColor : Colors.white60,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter reminder title (e.g. Midterm Exam)',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter title';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Details / Description',
                          hintText: 'Optional details (e.g. Syllabus: Chapters 1-4)',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : Text(
                                  _isGeneralEvent ? 'Assign Reminder' : 'Add Own Reminder',
                                  style: GoogleFonts.unbounded(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

class _AcademicCalendarWidget extends ConsumerStatefulWidget {
  final String roomId;
  final List<RoomAnnouncement> generalEvents;
  final List<RoomPersonalReminder> personalEvents;

  const _AcademicCalendarWidget({
    required this.roomId,
    required this.generalEvents,
    required this.personalEvents,
  });

  @override
  ConsumerState<_AcademicCalendarWidget> createState() => _AcademicCalendarWidgetState();
}

class _AcademicCalendarWidgetState extends ConsumerState<_AcademicCalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  void _showAddEventSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddCalendarEventSheet(
        roomId: widget.roomId,
        date: _selectedDay!,
      ),
    );
  }

  Future<void> _deleteGeneralReminder(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete General Reminder', style: GoogleFonts.unbounded(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this general reminder for the room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(roomRepositoryProvider).deleteAnnouncement(id);
        ref.invalidate(roomAnnouncementsProvider(widget.roomId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('General reminder deleted successfully!'),
              backgroundColor: AppTheme.safeColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete reminder: $e'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePersonalReminder(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Personal Reminder', style: GoogleFonts.unbounded(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this personal reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(roomRepositoryProvider).deletePersonalReminder(id);
        ref.invalidate(roomPersonalRemindersProvider(widget.roomId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Personal reminder deleted successfully!'),
              backgroundColor: AppTheme.safeColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete personal reminder: $e'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentRoomRoleProvider(widget.roomId));
    final canPost = role == 'owner' || role == 'moderator';

    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final numDays = lastDay.day;
    final leadingEmptySpaces = firstDay.weekday - 1;
    final totalCells = leadingEmptySpaces + numDays;

    final selectedDayStr = _selectedDay != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDay!)
        : null;

    final selectedDayGeneralEvents = widget.generalEvents.where((e) {
      final dateStr = e.title.split('|').first.replaceAll('[CalendarEvent]:', '').trim();
      return dateStr == selectedDayStr;
    }).toList();

    final selectedDayPersonalEvents = widget.personalEvents.where((e) {
      final dateStr = DateFormat('yyyy-MM-dd').format(e.date);
      return dateStr == selectedDayStr;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Academic Calendar',
                style: GoogleFonts.unbounded(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white54),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: GoogleFonts.unbounded(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white54),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              if (index < leadingEmptySpaces) {
                return const SizedBox();
              }

              final dayNumber = index - leadingEmptySpaces + 1;
              final dayDate = DateTime(_focusedDay.year, _focusedDay.month, dayNumber);
              final isSelected = _selectedDay != null &&
                  _selectedDay!.year == dayDate.year &&
                  _selectedDay!.month == dayDate.month &&
                  _selectedDay!.day == dayDate.day;
              final isToday = DateTime.now().year == dayDate.year &&
                  DateTime.now().month == dayDate.month &&
                  DateTime.now().day == dayDate.day;

              final dayDateStr = DateFormat('yyyy-MM-dd').format(dayDate);

              final hasGeneralEvent = widget.generalEvents.any((e) {
                final dateStr = e.title.split('|').first.replaceAll('[CalendarEvent]:', '').trim();
                return dateStr == dayDateStr;
              });

              final hasPersonalEvent = widget.personalEvents.any((e) {
                final dateStr = DateFormat('yyyy-MM-dd').format(e.date);
                return dateStr == dayDateStr;
              });

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = dayDate;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : isToday
                            ? AppTheme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: AppTheme.primaryColor.withOpacity(0.5))
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          '$dayNumber',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? Colors.black
                                : Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      if (hasGeneralEvent || hasPersonalEvent)
                        Positioned(
                          bottom: 4,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasGeneralEvent)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF8B7EF6), // Purple
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (hasPersonalEvent)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2ED573), // Green
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedDay != null
                    ? DateFormat('dd MMMM yyyy').format(_selectedDay!)
                    : 'Select a date',
                style: GoogleFonts.unbounded(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              if (_selectedDay != null)
                TextButton.icon(
                  onPressed: () => _showAddEventSheet(context),
                  icon: const Icon(Icons.add, size: 14),
                  label: Text(
                    canPost ? 'Add Reminder' : 'Add Own Reminder',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 1. General Reminders Section
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B7EF6), // Purple
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'General Reminders',
                style: GoogleFonts.unbounded(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedDayGeneralEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              child: Text(
                'No general reminders scheduled.',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            )
          else
            ...selectedDayGeneralEvents.map((e) {
              final parts = e.title.split('|');
              final title = parts.length > 1 ? parts[1].trim() : 'Academic Event';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          if (e.body.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              e.body,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (canPost)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 18),
                        onPressed: () => _deleteGeneralReminder(e.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 16),
          
          // 2. Personal Reminders Section
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF2ED573), // Green
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'My Reminders',
                style: GoogleFonts.unbounded(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedDayPersonalEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              child: Text(
                'No personal reminders scheduled.',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            )
          else
            ...selectedDayPersonalEvents.map((e) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          if (e.body != null && e.body!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              e.body!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 18),
                      onPressed: () => _deletePersonalReminder(e.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RoomAnnouncementsTab extends ConsumerWidget {
  final String roomId;
  final Function(int) onSwitchTab;

  const _RoomAnnouncementsTab({
    super.key,
    required this.roomId,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(roomAnnouncementsProvider(roomId));
    final personalRemindersAsync = ref.watch(roomPersonalRemindersProvider(roomId));
    final roomAsync = ref.watch(roomDetailsProvider(roomId));

    return announcementsAsync.when(
      data: (announcements) {
        return personalRemindersAsync.when(
          data: (personalReminders) {
            final roomCode = roomAsync.when(
              data: (room) => room.roomCode,
              loading: () => '...',
              error: (_, __) => '',
            );

            final header = Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Announcements',
                    style: GoogleFonts.unbounded(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Important updates and materials for #$roomCode.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );

            final regularAnnouncements = announcements
                .where((a) => !a.title.startsWith('[CalendarEvent]:'))
                .toList();

            final calendarAnnouncements = announcements
                .where((a) => a.title.startsWith('[CalendarEvent]:'))
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                header,
                Text(
                  'Announcements Feed',
                  style: GoogleFonts.unbounded(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                if (regularAnnouncements.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          color: Colors.white.withOpacity(0.2),
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No announcements yet',
                          style: GoogleFonts.unbounded(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Announcements from your professor will appear here.',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...regularAnnouncements.map((announcement) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AnnouncementCard(
                          announcement: announcement,
                          onSwitchTab: onSwitchTab,
                        ),
                      )),
                const SizedBox(height: 32),
                _AcademicCalendarWidget(
                  roomId: roomId,
                  generalEvents: calendarAnnouncements,
                  personalEvents: personalReminders,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorState(message: '$err'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(message: '$err'),
    );
  }
}

class _RoomSubjectsSheet extends StatelessWidget {
  final String roomId;
  const _RoomSubjectsSheet({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      body: Container(
        color: Colors.black,
        child: _RoomSubjectsTab(roomId: roomId),
      ),
    );
  }
}

class _RoomMembersSheet extends StatelessWidget {
  final String roomId;
  const _RoomMembersSheet({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Members')),
      body: Container(
        color: Colors.black,
        child: _RoomMembersTab(roomId: roomId),
      ),
    );
  }
}
