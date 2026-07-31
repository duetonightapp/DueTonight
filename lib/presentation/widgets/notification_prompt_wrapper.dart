import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/notification_helper.dart';
import '../../routes/app_router.dart';
import '../providers/auth_provider.dart';

class NotificationPromptWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationPromptWrapper({super.key, required this.child});

  @override
  ConsumerState<NotificationPromptWrapper> createState() => _NotificationPromptWrapperState();
}

class _NotificationPromptWrapperState extends ConsumerState<NotificationPromptWrapper> {
  String? _lastCheckedUserId;

  Future<void> _checkPermissionsAndShowPrompt(String userId) async {
    final status = await getNotificationPermissionStatus();
    debugPrint('Browser notification permission status for user $userId: $status');

    if (status == 'denied') {
      debugPrint('Notification permission explicitly denied by browser settings.');
      return;
    }

    // 1. Check if the user ALREADY has an active push subscription record in the database
    bool isSubscribedInDb = false;
    try {
      final client = Supabase.instance.client;
      final existingSub = await client
          .from('push_subscriptions')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingSub != null) {
        isSubscribedInDb = true;
        debugPrint('User $userId ALREADY has an active push subscription in DB.');
      } else {
        debugPrint('User $userId has NO active push subscription in DB.');
      }
    } catch (e) {
      debugPrint('Error checking push subscription DB status for user $userId: $e');
    }

    // 2. If user is already subscribed in DB:
    if (isSubscribedInDb) {
      if (status == 'granted') {
        // Silently update subscription keys to keep them fresh
        _registerSubscriptionSilently(userId);
      }
      return; // Do NOT show prompt dialog if already subscribed in DB
    }

    // 3. If user is NOT subscribed in DB: SHOW THE PROMPT DIALOG!
    if (!mounted) return;
    try {
      _showPromptDialog(userId);
    } catch (e, stack) {
      debugPrint('Error showing prompt dialog: $e\n$stack');
    }
  }

  void _showPromptDialog(String userId) {
    final dialogContext = rootNavigatorKey.currentContext ?? context;

    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        final navigator = Navigator.of(dialogCtx);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFF1E1C29), // Rich dark purple theme
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(28),
            constraints: const BoxConstraints(maxWidth: 440),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    // High impact icon container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4C4C).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Color(0xFFFF5252),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Don\'t Miss Out on Deadlines!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                        children: const [
                          TextSpan(
                            text: 'It will be ',
                          ),
                          TextSpan(
                            text: 'YOUR LOSS',
                            style: TextStyle(
                              color: Color(0xFFFF5252),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(
                            text: ' if you don\'t allow notifications! You won\'t get instant alerts when classmates post new assignments, announcements, or solutions.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Big prominent CTA button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          navigator.pop();
                          _triggerPermissionRequest(userId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6750A4),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFF6750A4).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_active_outlined, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Enable Notifications Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Small subtle close button on top corner
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 22,
                    ),
                    onPressed: () {
                      navigator.pop();
                    },
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _triggerPermissionRequest(String userId) async {
    final result = await requestNotificationPermission();
    if (result == 'granted') {
      if (!mounted) return;
      _showLoadingSnackBar('Setting up push subscriptions...');
      
      final subscription = await subscribeUserToPush(AppConstants.vapidPublicKey);
      if (subscription != null) {
        try {
          final client = Supabase.instance.client;
          await client.from('push_subscriptions').upsert({
            'user_id': userId,
            'endpoint': subscription['endpoint'],
            'p256dh': subscription['p256dh'],
            'auth': subscription['auth'],
          }, onConflict: 'endpoint');

          if (!mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showSuccessSnackBar('Notifications enabled successfully! 🎉');
        } catch (e) {
          debugPrint('Error saving subscription: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showErrorSnackBar('Failed to save subscription. Please try again.');
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar('Failed to register subscription with browser.');
      }
    } else if (result == 'denied') {
      if (!mounted) return;
      _showErrorSnackBar('Notification permission denied. You can enable it in browser settings.');
    }
  }

  Future<bool> _registerSubscriptionSilently(String userId) async {
    final subscription = await subscribeUserToPush(AppConstants.vapidPublicKey);
    if (subscription != null) {
      try {
        final client = Supabase.instance.client;
        await client.from('push_subscriptions').upsert({
          'user_id': userId,
          'endpoint': subscription['endpoint'],
          'p256dh': subscription['p256dh'],
          'auth': subscription['auth'],
        }, onConflict: 'endpoint');
        debugPrint('Push subscription verified and registered silently.');
        return true;
      } catch (e) {
        debugPrint('Error registering subscription silently: $e');
      }
    }
    return false;
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: const Duration(days: 1), // keeps it open until hidden
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF323232),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final user = ref.watch(authStateProvider);
      final router = ref.watch(routerProvider);
      final location = router.routeInformationProvider.value.uri.path;

      final isAuthOrLoadingRoute = location == '/splash' ||
          location == '/login' ||
          location == '/login-callback' ||
          location == '/setup-name';

      if (user != null && !isAuthOrLoadingRoute && _lastCheckedUserId != user.id) {
        _lastCheckedUserId = user.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkPermissionsAndShowPrompt(user.id);
        });
      }
    }
    return widget.child;
  }
}
