import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/room_provider.dart';

class RoomJoinScreen extends ConsumerStatefulWidget {
  const RoomJoinScreen({super.key});

  @override
  ConsumerState<RoomJoinScreen> createState() => _RoomJoinScreenState();
}

class _RoomJoinScreenState extends ConsumerState<RoomJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);
    final repo = ref.read(roomRepositoryProvider);

    try {
      final roomId = await repo.joinRoomByCode(_codeController.text.trim());
      if (mounted) {
        ref.invalidate(myRoomsProvider);
        context.go('/rooms/$roomId');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join room: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Room')),
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
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
                      Icons.key_rounded,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Enter your room code',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.95),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ask your class representative for the 6-character code.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Room Code',
                      hintText: 'e.g. A1B2C3',
                      prefixIcon: Icon(
                        Icons.vpn_key_outlined,
                        size: 22,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the room code';
                      }
                      if (value.trim().length < 4) {
                        return 'Room code looks too short';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
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
                              'Join Room',
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
