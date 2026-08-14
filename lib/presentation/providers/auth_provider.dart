import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user.dart' as app;

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
        state = app.User.fromJson(response);
      } else {
        debugPrint('No profile found, creating from auth user');
        final authUser = _client.auth.currentUser;
        state = app.User(
          id: userId,
          email: authUser?.email ?? '',
          fullName: '',
          avatarUrl: authUser?.userMetadata?['avatar_url'] as String?,
        );
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      final authUser = _client.auth.currentUser;
      state = app.User(
        id: userId,
        email: authUser?.email ?? '',
        fullName: '',
        avatarUrl: authUser?.userMetadata?['avatar_url'] as String?,
      );
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign In');

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
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('Email Sign In completed');
    } catch (e) {
      debugPrint('Email Sign in error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('Starting Email Sign Up');
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      debugPrint('Email Sign Up completed');
      return response;
    } catch (e) {
      debugPrint('Email Sign Up error: $e');
      rethrow;
    }
  }


  Future<void> signOut() async {
    await _client.auth.signOut();
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
