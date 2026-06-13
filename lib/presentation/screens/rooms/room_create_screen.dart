import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/room_provider.dart';

class RoomCreateScreen extends ConsumerStatefulWidget {
  const RoomCreateScreen({super.key});

  @override
  ConsumerState<RoomCreateScreen> createState() => _RoomCreateScreenState();
}

class _RoomCreateScreenState extends ConsumerState<RoomCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _collegeController = TextEditingController();
  final _branchController = TextEditingController();
  final _semesterController = TextEditingController();
  final _divisionController = TextEditingController();
  final _subjectController = TextEditingController();
  final List<String> _subjects = [];
  String? _subjectError;
  bool _isLoading = false;

  @override
  void dispose() {
    _collegeController.dispose();
    _branchController.dispose();
    _semesterController.dispose();
    _divisionController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _addSubject() {
    final raw = _subjectController.text.trim();
    if (raw.isEmpty) return;

    final exists = _subjects.any((s) => s.toLowerCase() == raw.toLowerCase());
    if (exists) {
      setState(() {
        _subjectError = 'Subject already added.';
      });
      return;
    }

    setState(() {
      _subjects.add(raw);
      _subjectController.clear();
      _subjectError = null;
    });
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    if (_subjects.isEmpty) {
      setState(() {
        _subjectError = 'Add at least one subject.';
      });
      return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(roomRepositoryProvider);

    try {
      final result = await repo.createRoom(
        collegeName: _collegeController.text.trim(),
        branch: _branchController.text.trim(),
        semester: _semesterController.text.trim(),
        division: _divisionController.text.trim(),
        subjects: List<String>.from(_subjects),
      );

      String roomId = result.roomId;
      if (result.existed) {
        roomId = await repo.joinRoomByCode(result.roomCode);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room already exists. Joined successfully.'),
            ),
          );
        }
      }

      if (mounted) {
        ref.invalidate(myRoomsProvider);
        context.go('/rooms/$roomId');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create room: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Room')),
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.15),
                          AppTheme.primaryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.meeting_room_outlined,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Set up your academic room',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.95),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We will generate a unique room code for your class.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _RoomField(
                    controller: _collegeController,
                    label: 'College Name',
                    hint: 'e.g. ABC College of Engineering',
                    icon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 16),
                  _RoomField(
                    controller: _branchController,
                    label: 'Branch',
                    hint: 'e.g. Computer Science',
                    icon: Icons.account_tree_outlined,
                  ),
                  const SizedBox(height: 16),
                  _RoomField(
                    controller: _semesterController,
                    label: 'Semester / Year',
                    hint: 'e.g. Semester 3 or Year 2',
                    icon: Icons.format_list_numbered_rounded,
                  ),
                  const SizedBox(height: 16),
                  _RoomField(
                    controller: _divisionController,
                    label: 'Division',
                    hint: 'e.g. A',
                    icon: Icons.group_work_outlined,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Subjects',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _subjectController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Add subject',
                      hintText: 'e.g. Data Structures',
                      prefixIcon: const Icon(Icons.book_outlined, size: 22),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _addSubject,
                      ),
                      errorText: _subjectError,
                    ),
                    onFieldSubmitted: (_) => _addSubject(),
                  ),
                  if (_subjects.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _subjects
                          .map(
                            (subject) => Chip(
                              label: Text(subject),
                              onDeleted: () {
                                setState(() {
                                  _subjects.remove(subject);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
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
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
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
                              'Create Room',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
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
    );
  }
}

class _RoomField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _RoomField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 22),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
