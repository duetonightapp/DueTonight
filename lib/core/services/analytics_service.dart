import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../constants/app_constants.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _initialized = false;

  /// Initializes PostHog SDK if valid API keys are available
  Future<void> init() async {
    if (_initialized) return;

    try {
      if (AppConstants.posthogApiKey.startsWith('phc_') &&
          !AppConstants.posthogApiKey.contains('YOUR_')) {
        final postHogConfig = PostHogConfig(AppConstants.posthogApiKey)
          ..host = AppConstants.posthogHost
          ..sessionReplay = true;

        await Posthog().setup(postHogConfig);
        _initialized = true;
        debugPrint('[AnalyticsService] PostHog initialized successfully.');
      } else {
        debugPrint('[AnalyticsService] PostHog API key is invalid or placeholder.');
      }
    } catch (e) {
      debugPrint('[AnalyticsService] Error initializing PostHog: $e');
    }
  }

  /// Identifies a user with their unique ID and optional profile properties
  Future<void> identify({
    required String userId,
    Map<String, Object>? userProperties,
  }) async {
    try {
      await Posthog().identify(
        userId: userId,
        userProperties: userProperties,
      );
      debugPrint('[AnalyticsService] Identified user: $userId');
    } catch (e) {
      debugPrint('[AnalyticsService] Identify error: $e');
    }
  }

  /// Resets user identity on logout
  Future<void> reset() async {
    try {
      await Posthog().reset();
      debugPrint('[AnalyticsService] Reset user session');
    } catch (e) {
      debugPrint('[AnalyticsService] Reset error: $e');
    }
  }

  /// Captures a custom event
  Future<void> capture(
    String eventName, {
    Map<String, Object>? properties,
  }) async {
    try {
      await Posthog().capture(
        eventName: eventName,
        properties: properties,
      );
      debugPrint('[AnalyticsService] Event captured: $eventName');
    } catch (e) {
      debugPrint('[AnalyticsService] Capture error for $eventName: $e');
    }
  }

  /// Manually tracks screen navigation
  Future<void> screen(
    String screenName, {
    Map<String, Object>? properties,
  }) async {
    try {
      await Posthog().screen(
        screenName: screenName,
        properties: properties,
      );
      debugPrint('[AnalyticsService] Screen viewed: $screenName');
    } catch (e) {
      debugPrint('[AnalyticsService] Screen track error: $e');
    }
  }

  // --- Convenience Domain Event Helpers ---

  Future<void> trackUserSignedIn({
    required String method,
    required String userId,
    String? email,
  }) async {
    await capture('user_signed_in', properties: {
      'method': method,
      'user_id': userId,
      if (email != null && email.isNotEmpty) 'email': email,
    });
  }

  Future<void> trackUserSignedUp({
    required String method,
    required String userId,
    String? email,
  }) async {
    await capture('user_signed_up', properties: {
      'method': method,
      'user_id': userId,
      if (email != null && email.isNotEmpty) 'email': email,
    });
  }

  Future<void> trackUserSignedOut() async {
    await capture('user_signed_out');
    await reset();
  }

  Future<void> trackRoomCreated({
    required String roomId,
    required String roomName,
    required String roomCode,
  }) async {
    await capture('room_created', properties: {
      'room_id': roomId,
      'room_name': roomName,
      'room_code': roomCode,
    });
  }

  Future<void> trackRoomJoined({
    required String roomId,
    required String roomCode,
  }) async {
    await capture('room_joined', properties: {
      'room_id': roomId,
      'room_code': roomCode,
    });
  }

  Future<void> trackAssignmentCreated({
    required String assignmentId,
    required String roomId,
    required String title,
    String? subjectId,
  }) async {
    await capture('assignment_created', properties: {
      'assignment_id': assignmentId,
      'room_id': roomId,
      'title': title,
      if (subjectId != null) 'subject_id': subjectId,
    });
  }

  Future<void> trackAssignmentCompleted({
    required String assignmentId,
    required String roomId,
    required bool completed,
  }) async {
    await capture('assignment_status_toggled', properties: {
      'assignment_id': assignmentId,
      'room_id': roomId,
      'completed': completed,
    });
  }

  Future<void> trackResourceViewed({
    required String resourceId,
    required String roomId,
    required String title,
    String? fileType,
  }) async {
    await capture('resource_viewed', properties: {
      'resource_id': resourceId,
      'room_id': roomId,
      'title': title,
      if (fileType != null) 'file_type': fileType,
    });
  }

  Future<void> trackResourceUploaded({
    required String resourceId,
    required String roomId,
    required String title,
    String? fileType,
  }) async {
    await capture('resource_uploaded', properties: {
      'resource_id': resourceId,
      'room_id': roomId,
      'title': title,
      if (fileType != null) 'file_type': fileType,
    });
  }

  Future<void> trackResourceShared({
    required String resourceId,
    required String roomId,
  }) async {
    await capture('resource_shared', properties: {
      'resource_id': resourceId,
      'room_id': roomId,
    });
  }
}
