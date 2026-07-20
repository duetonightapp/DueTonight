// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_interop';
import 'package:js/js.dart';
import 'package:flutter/foundation.dart';

@JS('Notification')
external JSObject get _notificationCtor;

@JS('dueTonightPush')
external DueTonightPushHelper get _dueTonightPush;

@JS()
@anonymous
class DueTonightPushHelper {
  external String getPermissionStatus();
  external JSPromise requestPermission();
  external JSPromise<JSObject?> subscribeUser(String publicVapidKey);
  external factory DueTonightPushHelper();
}

Future<String> getNotificationPermissionStatus() async {
  try {
    final permission = _notificationCtor.getProperty('permission'.toJS);
    return permission.dartify() as String? ?? 'unsupported';
  } catch (e) {
    debugPrint('getNotificationPermissionStatus error: $e');
  }
  return 'unsupported';
}

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
