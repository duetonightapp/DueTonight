import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/assignment_model.dart';

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final ValueChanged<bool?>? onToggleComplete;
  final VoidCallback? onDelete;

  const AssignmentCard({
    super.key,
    required this.assignment,
    this.onToggleComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = assignment.isOverdue;
    final isCompleted = assignment.isCompleted;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final deadlineDay = DateTime(
      assignment.deadline.year,
      assignment.deadline.month,
      assignment.deadline.day,
    );

    String dateStr;
    if (deadlineDay == today) {
      dateStr =
          'Due Tonight at ${DateFormat('h:mm a').format(assignment.deadline)}';
    } else if (deadlineDay == tomorrow) {
      dateStr =
          'Due Tomorrow at ${DateFormat('h:mm a').format(assignment.deadline)}';
    } else {
      dateStr =
          'Due ${DateFormat('MMM d, yyyy').format(assignment.deadline)} at ${DateFormat('h:mm a').format(assignment.deadline)}';
    }

    Color statusColor;
    if (isCompleted) {
      statusColor = const Color(0xFF2ED573);
    } else if (isOverdue) {
      statusColor = const Color(0xFFFF4757);
    } else {
      statusColor = assignment.priority == 'high'
          ? const Color(0xFFFFB347)
          : const Color(0xFF8B7EF6);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF2ED573).withOpacity(0.12)
                : isOverdue
                ? const Color(0xFFFF4757).withOpacity(0.15)
                : Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor,
                        statusColor.withOpacity(0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
                    child: Row(
                      children: [
                        Transform.scale(
                          scale: 1.15,
                          child: Checkbox(
                            value: isCompleted,
                            onChanged: onToggleComplete,
                            activeColor: const Color(0xFF2ED573),
                            checkColor: Colors.black,
                            side: BorderSide(
                              color: isOverdue
                                  ? const Color(0xFFFF4757)
                                  : Colors.white.withOpacity(0.25),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      assignment.subject?.toUpperCase() ??
                                          'GENERAL',
                                      style: TextStyle(
                                        color: statusColor.withOpacity(0.9),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person_rounded,
                                          size: 10,
                                          color: Colors.white.withOpacity(0.25),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Manual',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.25),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                assignment.title,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: Colors.white.withOpacity(0.3),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: isOverdue
                                        ? const Color(0xFFFF4757)
                                        : Colors.white.withOpacity(0.4),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      color: isOverdue
                                          ? const Color(0xFFFF4757)
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
                                        color: const Color(0xFFFF4757)
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'OVERDUE',
                                        style: TextStyle(
                                          color: Color(0xFFFF4757),
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
                        if (onDelete != null)
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.white.withOpacity(0.2),
                                size: 20,
                              ),
                              onPressed: onDelete,
                            ),
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
}
