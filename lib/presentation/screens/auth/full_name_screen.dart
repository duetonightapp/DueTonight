import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class FullNameScreen extends ConsumerStatefulWidget {
  const FullNameScreen({super.key});

  @override
  ConsumerState<FullNameScreen> createState() => _FullNameScreenState();
}

class _FullNameScreenState extends ConsumerState<FullNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;
    final suggestedName =
        currentUser?.userMetadata?['full_name'] as String? ??
        currentUser?.userMetadata?['name'] as String? ??
        '';

    if (user != null && user.fullName.trim().isNotEmpty) {
      _controller.text = user.fullName;
    } else if (suggestedName.trim().isNotEmpty) {
      _controller.text = suggestedName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authStateProvider.notifier)
          .updateFullName(_controller.text);
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save name: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.25),
                        blurRadius: 25,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    size: 44,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Tell us your name',
                  style: AppTheme.unbounded(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'This will appear on your profile and dashboard.',
                  style: AppTheme.inter(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    style: AppTheme.inter(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      hintText: 'Enter your full name',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),
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
                        : Text(
                            'Continue',
                            style: AppTheme.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
