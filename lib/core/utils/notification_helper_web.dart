import 'dart:js_interop';
import 'package:flutter/foundation.dart';

/// Gets the current notification permission status via `Notification.permission`.
Future<String> getNotificationPermissionStatus() async {
  try {
    final notification = globalThis.getProperty('Notification'.toJS);
    if (notification.isNull || notification.isUndefined) return 'unsupported';

    final permission = notification.getProperty('permission'.toJS);
    final result = permission.dartify();
    return (result is String) ? result : 'unsupported';
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

    final promise = notification.callMethod(
      'requestPermission'.toJS,
    ) as JSPromise<JSAny?>;
    final result = await promise.toDart;
    final permission = result?.dartify() as String? ?? 'denied';
    return permission;
  } catch (e) {
    debugPrint('requestNotificationPermission error: $e');
  }
  return 'denied';
}

/// Subscribes the active service worker to push notifications via the
/// `window.dueTonightPush.subscribeUser` helper defined in `index.html`.
Future<Map<String, String>?> subscribeUserToPush(String publicVapidKey) async {
  try {
    final push = globalThis.getProperty('dueTonightPush'.toJS);
    if (push.isNull || push.isUndefined) {
      debugPrint('subscribeUserToPush: dueTonightPush not found in global scope');
      return null;
    }

    final promise = push.callMethod(
      'subscribeUser'.toJS,
      publicVapidKey.toJS,
    ) as JSPromise<JSAny?>;
    final result = await promise.toDart;

    if (result == null || result.isNull || result.isUndefined) {
      debugPrint('subscribeUserToPush: subscribeUser returned null');
      return null;
    }

    final endpoint = result.getProperty('endpoint'.toJS).dartify() as String?;
    final p256dh = result.getProperty('p256dh'.toJS).dartify() as String?;
    final auth = result.getProperty('auth'.toJS).dartify() as String?;

    if (endpoint == null || p256dh == null || auth == null) {
      debugPrint('subscribeUserToPush: subscription data incomplete');
      return null;
    }

    debugPrint('subscribeUserToPush: subscription obtained successfully');
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
