import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/room_assignment_model.dart';

class RoomAssignmentCard extends ConsumerWidget {
  final RoomAssignment assignment;

  const RoomAssignmentCard({super.key, required this.assignment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadlineText = assignment.deadline != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(assignment.deadline!)
        : 'No deadline';

    final isOverdue =
        assignment.deadline != null &&
        assignment.deadline!.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/rooms/${assignment.roomId}/assignments/${assignment.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.cardColor, AppTheme.cardColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOverdue
                  ? AppTheme.errorColor.withOpacity(0.15)
                  : Colors.white.withOpacity(0.06),
            ),
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
                      gradient: LinearGradient(
                        colors: [
                          isOverdue ? AppTheme.errorColor : AppTheme.primaryColor,
                          isOverdue
                              ? AppTheme.errorColor.withOpacity(0.5)
                              : AppTheme.primaryLight,
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (assignment.subject != null &&
                              assignment.subject!.isNotEmpty)
                            Text(
                              assignment.subject!.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                          if (assignment.subject != null &&
                              assignment.subject!.isNotEmpty)
                            const SizedBox(height: 6),
                          Text(
                            assignment.title,
                            style: GoogleFonts.unbounded(
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: isOverdue
                                    ? AppTheme.errorColor
                                    : Colors.white.withOpacity(0.4),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                deadlineText,
                                style: GoogleFonts.inter(
                                  color: isOverdue
                                      ? AppTheme.errorColor
                                      : Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontWeight: isOverdue
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              if (isOverdue) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'OVERDUE',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.errorColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
      ),
    );
  }
}
