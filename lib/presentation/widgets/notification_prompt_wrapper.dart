import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/notification_helper.dart';
import '../providers/auth_provider.dart';

class NotificationPromptWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationPromptWrapper({super.key, required this.child});

  @override
  ConsumerState<NotificationPromptWrapper> createState() => _NotificationPromptWrapperState();
}

class _NotificationPromptWrapperState extends ConsumerState<NotificationPromptWrapper> {
  bool _hasPrompted = false;



  Future<void> _checkPermissionsAndShowPrompt(String userId) async {
    final status = await getNotificationPermissionStatus();
    debugPrint('Browser notification permission status: $status');

    if (status == 'default') {
      if (!mounted) return;

      // Show Dialog and SnackBar (toast) at the same time
      try {
        _showPromptDialog(userId);
      } catch (e, stack) {
        debugPrint('Error showing prompt dialog: $e\n$stack');
      }
      try {
        _showPromptSnackBar(userId);
      } catch (e, stack) {
        debugPrint('Error showing prompt snackbar: $e\n$stack');
      }
    } else if (status == 'granted') {
      // If already granted, ensure the subscription is registered in the database
      _registerSubscriptionSilently(userId);
    }
  }

  void _showPromptSnackBar(String userId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.notifications_outlined, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Please enable notifications to receive real-time class updates!',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Enable',
          textColor: Colors.tealAccent,
          onPressed: () {
            // Dismiss current SnackBar and trigger request
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _triggerPermissionRequest(userId);
          },
        ),
        duration: const Duration(seconds: 15),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF6750A4), // Primary Deep Purple color
      ),
    );
  }

  void _showPromptDialog(String userId) {
    // Capture these BEFORE showDialog to avoid null context inside dialog builder
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF1E1E1E), // Fallback dark card color
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6750A4).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFF9880e6), // Bright purple tone
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Enable Push Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Never miss a deadline! Enable notifications to receive instant updates when classmates upload assignments, announcements, or solutions.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          navigator.pop();
                          messenger.hideCurrentSnackBar();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Later',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          navigator.pop();
                          messenger.hideCurrentSnackBar();
                          _triggerPermissionRequest(userId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6750A4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Enable',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
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

  Future<void> _registerSubscriptionSilently(String userId) async {
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
      } catch (e) {
        debugPrint('Error registering subscription silently: $e');
      }
    }
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
      if (user != null && user.fullName.isNotEmpty && !_hasPrompted) {
        _hasPrompted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkPermissionsAndShowPrompt(user.id);
        });
      }
    }
    return widget.child;
  }
}
