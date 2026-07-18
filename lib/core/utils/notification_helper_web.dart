// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:js_util' as js_util;

Future<String> getNotificationPermissionStatus() async {
  try {
    final push = js.context['dueTonightPush'];
    if (push != null) {
      return push.callMethod('getPermissionStatus') as String;
    }
  } catch (e) {
    // Fail silently or log
  }
  return 'unsupported';
}

Future<String> requestNotificationPermission() async {
  try {
    final push = js.context['dueTonightPush'];
    if (push != null) {
      final promise = push.callMethod('requestPermission');
      final result = await js_util.promiseToFuture(promise);
      return result as String;
    }
  } catch (e) {
    // Fail silently
  }
  return 'denied';
}

Future<Map<String, String>?> subscribeUserToPush(String publicVapidKey) async {
  try {
    final push = js.context['dueTonightPush'];
    if (push != null) {
      final promise = push.callMethod('subscribeUser', [publicVapidKey]);
      final result = await js_util.promiseToFuture(promise);
      if (result != null) {
        final endpoint = js_util.getProperty(result, 'endpoint') as String;
        final p256dh = js_util.getProperty(result, 'p256dh') as String;
        final auth = js_util.getProperty(result, 'auth') as String;
        return {
          'endpoint': endpoint,
          'p256dh': p256dh,
          'auth': auth,
        };
      }
    }
  } catch (e) {
    // Fail silently
  }
  return null;
}
