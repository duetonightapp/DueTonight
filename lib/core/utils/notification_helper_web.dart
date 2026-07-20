// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';

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

Future<String> requestNotificationPermission() async {
  try {
    final notificationCtor = js.context['Notification'];
    if (notificationCtor != null) {
      final promise = notificationCtor.callMethod('requestPermission');
      final result = await js_util.promiseToFuture(promise);
      return (result as String?) ?? 'denied';
    }
    debugPrint('requestNotificationPermission: Notification API not found');
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

    // Use js_util.callMethod instead of push.callMethod because the latter
    // doesn't properly return Promises from async JS functions.
    final promise = js_util.callMethod(push, 'subscribeUser', [publicVapidKey]);
    final result = await js_util.promiseToFuture(promise);

    if (result == null) {
      debugPrint('subscribeUserToPush: subscribeUser returned null');
      return null;
    }

    final endpoint = js_util.getProperty(result, 'endpoint') as String?;
    final p256dh = js_util.getProperty(result, 'p256dh') as String?;
    final auth = js_util.getProperty(result, 'auth') as String?;

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
