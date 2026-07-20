// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// Gets the current notification permission status by reading the browser's
/// native `Notification.permission` directly via dart:js.
Future<String> getNotificationPermissionStatus() async {
  try {
    final notificationCtor = js.context['Notification'];
    if (notificationCtor != null) {
      final permission = notificationCtor['permission'];
      return (permission as String?) ?? 'unsupported';
    }
    debugPrint('getNotificationPermissionStatus: Notification API not found');
  } catch (e) {
    debugPrint('getNotificationPermissionStatus error: $e');
  }
  return 'unsupported';
}

/// Requests notification permission via `Notification.requestPermission()`.
/// Uses pure dart:js interop (no dart:js_util mixing) with manual Promise
/// handling through JS .then / .catch callbacks.
Future<String> requestNotificationPermission() async {
  try {
    final notificationCtor = js.context['Notification'];
    if (notificationCtor == null) {
      debugPrint('requestNotificationPermission: Notification API not found');
      return 'denied';
    }

    final promise = notificationCtor.callMethod('requestPermission');
    if (promise == null) return 'denied';

    final completer = Completer<String>();
    promise.callMethod('then', [
      js.allowInterop((result) {
        completer.complete(result as String? ?? 'denied');
      }),
    ]);
    promise.callMethod('catch', [
      js.allowInterop((error) {
        debugPrint('requestNotificationPermission rejected: $error');
        completer.complete('denied');
      }),
    ]);
    return completer.future;
  } catch (e) {
    debugPrint('requestNotificationPermission error: $e');
  }
  return 'denied';
}

/// Subscribes the active service worker to push notifications via
/// `dueTonightPush.subscribeUser()`. Uses pure dart:js interop.
Future<Map<String, String>?> subscribeUserToPush(String publicVapidKey) async {
  try {
    final push = js.context['dueTonightPush'];
    if (push == null) {
      debugPrint('subscribeUserToPush: dueTonightPush not found');
      return null;
    }

    final promise = push.callMethod('subscribeUser', [publicVapidKey]);
    if (promise == null) {
      debugPrint('subscribeUserToPush: subscribeUser returned null');
      return null;
    }

    final completer = Completer<Map<String, String>?>();
    promise.callMethod('then', [
      js.allowInterop((result) {
        if (result == null) {
          debugPrint('subscribeUserToPush: result was null');
          completer.complete(null);
          return;
        }

        final endpoint = result['endpoint'] as String?;
        final p256dh = result['p256dh'] as String?;
        final auth = result['auth'] as String?;

        if (endpoint == null || p256dh == null || auth == null) {
          debugPrint('subscribeUserToPush: subscription data incomplete');
          completer.complete(null);
          return;
        }

        debugPrint('subscribeUserToPush: subscription obtained successfully');
        completer.complete({
          'endpoint': endpoint,
          'p256dh': p256dh,
          'auth': auth,
        });
      }),
    ]);
    promise.callMethod('catch', [
      js.allowInterop((error) {
        debugPrint('subscribeUserToPush rejected: $error');
        completer.complete(null);
      }),
    ]);

    return completer.future;
  } catch (e) {
    debugPrint('subscribeUserToPush error: $e');
  }
  return null;
}
