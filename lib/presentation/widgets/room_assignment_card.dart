import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/room_assignment_model.dart';

import '../providers/room_provider.dart';

class RoomAssignmentCard extends ConsumerWidget {
  final RoomAssignment assignment;
  final bool showPriority;

  const RoomAssignmentCard({
    super.key,
    required this.assignment,
    this.showPriority = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedIds = ref.watch(completedAssignmentsProvider);
    final isCompleted = completedIds.contains(assignment.id);

    final deadlineText = assignment.deadline != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(assignment.deadline!)
        : 'No deadline';

    final isOverdue = !isCompleted &&
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
              colors: [
                AppTheme.cardColor,
                isCompleted
                    ? const Color(0xFF10B981).withValues(alpha: 0.05)
                    : AppTheme.cardColor.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF10B981).withValues(alpha: 0.25)
                  : isOverdue
                      ? AppTheme.errorColor.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.06),
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
                          isCompleted
                              ? const Color(0xFF10B981)
                              : isOverdue
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryColor,
                          isCompleted
                              ? const Color(0xFF10B981).withValues(alpha: 0.5)
                              : isOverdue
                                  ? AppTheme.errorColor.withValues(alpha: 0.5)
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
                          Row(
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
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  ref
                                      .read(completedAssignmentsProvider.notifier)
                                      .toggleCompleted(assignment.id);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                        : AppTheme.primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isCompleted
                                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                          : AppTheme.primaryColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isCompleted
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked_rounded,
                                        size: 13,
                                        color: isCompleted
                                            ? const Color(0xFF10B981)
                                            : AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isCompleted ? 'Completed' : 'Mark as Complete',
                                        style: GoogleFonts.inter(
                                          color: isCompleted
                                              ? const Color(0xFF10B981)
                                              : AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            assignment.title,
                            style: GoogleFonts.unbounded(
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.95),
                              fontSize: 14,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: Colors.white38,
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
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                deadlineText,
                                style: GoogleFonts.inter(
                                  color: isOverdue
                                      ? AppTheme.errorColor
                                      : Colors.white.withValues(alpha: 0.5),
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
                                    color: AppTheme.errorColor.withValues(alpha: 0.12),
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
