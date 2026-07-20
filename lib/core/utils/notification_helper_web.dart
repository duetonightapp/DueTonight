// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_interop';
import 'package:js/js.dart';
import 'package:flutter/foundation.dart';

// ── Type-safe JS interop bindings using package:js ──────────────────

/// Access the browser's Notification constructor.
@JS('Notification')
external JSObject get _notificationCtor;

/// Access the dueTonightPush helper object defined in index.html.
@JS('dueTonightPush')
external DueTonightPushHelper get _dueTonightPush;

/// Typed binding for the dueTonightPush JS object.
@JS()
@anonymous
class DueTonightPushHelper {
  external String getPermissionStatus();
  external JSPromise requestPermission();
  external JSPromise<JSObject?> subscribeUser(String publicVapidKey);

  external factory DueTonightPushHelper();
}

// ── Public API ──────────────────────────────────────────────────────

/// Reads the browser's native `Notification.permission` (granted / denied / default).
Future<String> getNotificationPermissionStatus() async {
  try {
    final permission = _notificationCtor.getProperty('permission'.toJS);
    return permission.dartify() as String? ?? 'unsupported';
  } catch (e) {
    debugPrint('getNotificationPermissionStatus error: $e');
  }
  return 'unsupported';
}

/// Requests notification permission via `Notification.requestPermission()`.
Future<String> requestNotificationPermission() async {
  try {
    final promise = _notificationCtor.callMethod('requestPermission'.toJS);
    final result = await (promise as JSPromise).toDart;
    return result.dartify() as String? ?? 'denied';
  } catch (e) {
    debugPrint('requestNotificationPermission error: $e');
  }
  return 'denied';
}

/// Subscribes the active service worker to push notifications. Adds a
/// 15-second timeout so the UI never hangs forever.
Future<Map<String, String>?> subscribeUserToPush(String publicVapidKey) async {
  try {
    debugPrint('subscribeUserToPush: starting...');
    final promise = _dueTonightPush.subscribeUser(publicVapidKey);
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

    final endpoint = result.getProperty('endpoint'.toJS).dartify() as String?;
    final p256dh = result.getProperty('p256dh'.toJS).dartify() as String?;
    final auth = result.getProperty('auth'.toJS).dartify() as String?;

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
