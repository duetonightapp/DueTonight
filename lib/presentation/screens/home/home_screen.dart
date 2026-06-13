import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../rooms/room_dashboard_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final roomsAsync = ref.watch(myRoomsProvider);

    return roomsAsync.when(
      data: (rooms) {
        if (rooms.isNotEmpty) {
          // If the user is in at least one room, show the RoomDashboardScreen for the first room.
          return RoomDashboardScreen(roomId: rooms.first.room.id);
        }

        // If the user has not joined any rooms, show the Create/Join Room prompt.
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    color: const Color(0xFFF9F6F0),
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('DueTonight'),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, size: 22),
                  onPressed: () => _signOut(context, ref),
                ),
              ),
            ],
          ),
          body: Container(
            color: Colors.black,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user != null) ...[
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryLight,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.25),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.transparent,
                                backgroundImage: user.avatarUrl != null
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null
                                    ? Text(
                                        (user.fullName.isNotEmpty
                                                ? user.fullName[0]
                                                : user.email[0])
                                            .toUpperCase(),
                                        style: GoogleFonts.unbounded(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName
                                        : user.email.split('@')[0],
                                    style: GoogleFonts.unbounded(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 40),
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.15),
                                AppTheme.primaryColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.school_outlined,
                            color: AppTheme.primaryColor,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Join or Create a Room',
                          style: GoogleFonts.unbounded(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Collaborate with your classmates. Join an existing room with a class code or create a new one for your batch.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _RoomActionCard(
                        title: 'Create a Room',
                        description: 'Set up a new room for your college batch, semester, and subjects.',
                        icon: Icons.meeting_room_outlined,
                        onTap: () => context.push('/rooms/create'),
                      ),
                      const SizedBox(height: 16),
                      _RoomActionCard(
                        title: 'Join a Room',
                        description: 'Enter a 6-character room code to join your class dashboard instantly.',
                        icon: Icons.key_rounded,
                        onTap: () => context.push('/rooms/join'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        body: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Container(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load rooms',
                    style: GoogleFonts.unbounded(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(myRoomsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
}

class _RoomActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _RoomActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.15),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.unbounded(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
