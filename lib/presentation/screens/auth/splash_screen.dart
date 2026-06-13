import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    // Wait for the animation to play out
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      context.go('/login');
    } else {
      final authState = ref.read(authStateProvider);
      if (authState != null) {
        final needsName = authState.fullName.trim().isEmpty;
        context.go(needsName ? '/setup-name' : '/');
      } else {
        // Wait for authStateProvider to load if it hasn't already
        ref.listenManual(authStateProvider, (previous, next) {
          if (next != null && mounted) {
            final needsName = next.fullName.trim().isEmpty;
            context.go(needsName ? '/setup-name' : '/');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F6F0), // Cream background matching the logo's inner color
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.35),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'DueTonight',
                style: GoogleFonts.unbounded(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
