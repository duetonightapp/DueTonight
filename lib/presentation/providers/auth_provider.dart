import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user.dart' as app;
import '../../core/services/analytics_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StateNotifierProvider<AuthNotifier, app.User?>((ref) {
  return AuthNotifier(ref.watch(supabaseClientProvider));
});

class AuthNotifier extends StateNotifier<app.User?> {
  final SupabaseClient _client;

  AuthNotifier(this._client) : super(null) {
    _init();
  }

  void _init() {
    final session = _client.auth.currentSession;
    if (session != null) {
      debugPrint('Found existing session for user: ${session.user.id}');
      _fetchProfile(session.user.id);
    }

    _client.auth.onAuthStateChange.listen((event) {
      debugPrint('Auth state changed: ${event.event}');
      if (event.session != null) {
        _fetchProfile(event.session!.user.id);
      } else {
        state = null;
      }
    });
  }

  Future<void> _fetchProfile(String userId) async {
    try {
      debugPrint('Fetching profile for user: $userId');
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        debugPrint('Profile found: $response');
        final user = app.User.fromJson(response);
        state = user;
        AnalyticsService().identify(
          userId: userId,
          userProperties: {
            'email': user.email,
            'name': user.fullName,
          },
        );
      } else {
        debugPrint('No profile found, creating from auth user');
        final authUser = _client.auth.currentUser;
        final user = app.User(
          id: userId,
          email: authUser?.email ?? '',
          fullName: '',
          avatarUrl: authUser?.userMetadata?['avatar_url'] as String?,
        );
        state = user;
        AnalyticsService().identify(
          userId: userId,
          userProperties: {
            'email': user.email,
            'name': user.fullName,
          },
        );
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      final authUser = _client.auth.currentUser;
      final user = app.User(
        id: userId,
        email: authUser?.email ?? '',
        fullName: '',
        avatarUrl: authUser?.userMetadata?['avatar_url'] as String?,
      );
      state = user;
      AnalyticsService().identify(
        userId: userId,
        userProperties: {
          'email': user.email,
          'name': user.fullName,
        },
      );
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign In');
      AnalyticsService().capture('login_attempt', properties: {'method': 'google'});

      final redirectUrl = kIsWeb
          ? '${Uri.base.origin}/login-callback'
          : 'com.college.due-tonight://login-callback';

      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        scopes: 'email profile',
      );

      debugPrint('OAuth flow started');
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('Starting Email Sign In');
      AnalyticsService().capture('login_attempt', properties: {'method': 'email'});
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId != null) {
        AnalyticsService().trackUserSignedIn(
          method: 'email',
          userId: currentUserId,
          email: email.trim(),
        );
      }
      debugPrint('Email Sign In completed');
    } catch (e) {
      debugPrint('Email Sign in error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('Starting Email Sign Up');
      AnalyticsService().capture('signup_attempt', properties: {'method': 'email'});
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        AnalyticsService().trackUserSignedUp(
          method: 'email',
          userId: response.user!.id,
          email: email.trim(),
        );
      }
      debugPrint('Email Sign Up completed');
      return response;
    } catch (e) {
      debugPrint('Email Sign Up error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await AnalyticsService().trackUserSignedOut();
    state = null;
  }

  Future<void> updateFullName(String fullName) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      throw Exception('Full name is required');
    }

    await _client.from('profiles').upsert({'id': userId, 'full_name': trimmed});

    if (state != null) {
      state = state!.copyWith(fullName: trimmed);
    } else {
      await _fetchProfile(userId);
    }
  }
}
