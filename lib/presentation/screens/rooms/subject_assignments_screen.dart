import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/room_provider.dart';
import '../../widgets/room_assignment_card.dart';

class SubjectAssignmentsScreen extends ConsumerWidget {
  final String roomId;
  final String subjectId;

  const SubjectAssignmentsScreen({
    super.key,
    required this.roomId,
    required this.subjectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(roomSubjectsProvider(roomId));
    final assignmentsAsync = ref.watch(roomAssignmentsProvider(roomId));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: subjectsAsync.when(
          data: (subjects) {
            if (subjectId == 'other') {
              return Text(
                'Other',
                style: GoogleFonts.unbounded(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              );
            }
            final subject = subjects.firstWhere(
              (s) => s.id == subjectId,
              orElse: () => subjects.first,
            );
            return Text(
              subject.name,
              style: GoogleFonts.unbounded(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const Text('Subject'),
        ),
      ),
      body: Container(
        color: Colors.black,
        child: assignmentsAsync.when(
          data: (assignments) {
            return subjectsAsync.when(
              data: (subjects) {
                final subjectIds = subjects.map((s) => s.id).toSet();
                final subjectAssignments = assignments.where((a) {
                  if (subjectId == 'other') {
                    return a.subjectId == null || !subjectIds.contains(a.subjectId);
                  }
                  return a.subjectId == subjectId;
                }).toList();

                if (subjectAssignments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            color: Colors.white.withOpacity(0.2),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No assignments yet',
                            style: GoogleFonts.unbounded(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Assignments for this subject will show up here.',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final sortedAssignments = [...subjectAssignments]
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: sortedAssignments.length,
                  itemBuilder: (context, index) {
                    return RoomAssignmentCard(
                      assignment: sortedAssignments[index],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
