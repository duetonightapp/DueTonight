import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

/// Reads the browser's native `Notification.permission` (granted / denied / default).
Future<String> getNotificationPermissionStatus() async {
  try {
    final notification = globalThis.getProperty('Notification'.toJS);
    if (notification.isNull || notification.isUndefined) return 'unsupported';
    final permission = notification.getProperty('permission'.toJS);
    return permission.dartify() as String? ?? 'unsupported';
  } catch (e) {
    debugPrint('getNotificationPermissionStatus error: $e');
  }
  return 'unsupported';
}

/// Requests notification permission via `Notification.requestPermission()`.
Future<String> requestNotificationPermission() async {
  try {
    final notification = globalThis.getProperty('Notification'.toJS);
    if (notification.isNull || notification.isUndefined) return 'denied';
    final promise =
        notification.callMethod('requestPermission'.toJS) as JSPromise;
    final result = await promise.toDart;
    return result?.dartify() as String? ?? 'denied';
  } catch (e) {
    debugPrint('requestNotificationPermission error: $e');
  }
  return 'denied';
}

/// Subscribes the active service worker to push notifications.
Future<Map<String, String>?> subscribeUserToPush(String publicVapidKey) async {
  try {
    debugPrint('subscribeUserToPush: starting...');

    final push = globalThis.getProperty('dueTonightPush'.toJS);
    if (push.isNull || push.isUndefined) {
      debugPrint('subscribeUserToPush: dueTonightPush not found');
      return null;
    }

    final promise = push.callMethod(
      'subscribeUser'.toJS,
      publicVapidKey.toJS,
    ) as JSPromise;
    final result = await promise.toDart.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('subscribeUserToPush: TIMEOUT after 15s');
        return null;
      },
    );

    if (result == null || result.isNull || result.isUndefined) {
      debugPrint('subscribeUserToPush: result was null/undefined');
      return null;
    }

    final obj = result as JSObject;
    final endpoint = obj.getProperty('endpoint'.toJS).dartify() as String?;
    final p256dh = obj.getProperty('p256dh'.toJS).dartify() as String?;
    final auth = obj.getProperty('auth'.toJS).dartify() as String?;

    if (endpoint == null || p256dh == null || auth == null) {
      debugPrint('subscribeUserToPush: incomplete data');
      return null;
    }

    debugPrint('subscribeUserToPush: SUCCESS');
    return {
      'endpoint': endpoint,
      'p256dh': p256dh,
      'auth': auth,
    };
  } catch (e) {
    debugPrint('subscribeUserToPush error: $e');
  }
  return null;
}
