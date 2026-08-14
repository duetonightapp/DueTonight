import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

Future<String> getNotificationPermissionStatus() async {
  try {
    final notificationCtor = js.context['Notification'];
    if (notificationCtor == null) return 'unsupported';
    final permission = notificationCtor['permission'];
    return (permission as String?) ?? 'unsupported';
  } catch (e) {
    debugPrint('getNotificationPermissionStatus error: $e');
  }
  return 'unsupported';
}

Future<String> requestNotificationPermission() async {
  try {
    final push = js.context['dueTonightPush'];
    if (push == null) return 'denied';

    final completer = Completer<String>();
    push.callMethod('requestPermissionWithCallback', [
      js.allowInterop((result) {
        completer.complete(result as String? ?? 'denied');
      }),
    ]);

    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        debugPrint('requestPermission TIMEOUT');
        completer.complete('denied');
      }
    });

    return completer.future;
  } catch (e) {
    debugPrint('requestNotificationPermission error: $e');
  }
  return 'denied';
}

Future<Map<String, String>?> subscribeUserToPush(String publicVapidKey) async {
  try {
    final push = js.context['dueTonightPush'];
    if (push == null) {
      debugPrint('subscribeUserToPush: dueTonightPush not found');
      return null;
    }

    final completer = Completer<Map<String, String>?>();
    push.callMethod('subscribeWithCallback', [
      publicVapidKey,
      js.allowInterop((jsonStr) {
        try {
          final parsed = jsonDecode(jsonStr as String) as Map<String, dynamic>;
          final endpoint = parsed['endpoint'] as String?;
          final p256dh = parsed['p256dh'] as String?;
          final auth = parsed['auth'] as String?;
          if (endpoint != null && p256dh != null && auth != null) {
            debugPrint('subscribeUserToPush: SUCCESS');
            completer.complete({'endpoint': endpoint, 'p256dh': p256dh, 'auth': auth});
          } else {
            completer.complete(null);
          }
        } catch (e) {
          completer.complete(null);
        }
      }),
      js.allowInterop((error) {
        debugPrint('subscribeWithCallback error: $error');
        completer.complete(null);
      }),
    ]);

    Future.delayed(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        debugPrint('subscribeUserToPush TIMEOUT');
        completer.complete(null);
      }
    });

    return completer.future;
  } catch (e) {
    debugPrint('subscribeUserToPush error: $e');
  }
  return null;
}
