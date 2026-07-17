import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/auth/full_name_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/rooms/room_create_screen.dart';
import '../presentation/screens/rooms/room_dashboard_screen.dart';
import '../presentation/screens/rooms/room_entry_screen.dart';
import '../presentation/screens/rooms/room_join_screen.dart';
import '../presentation/screens/rooms/subject_assignments_screen.dart';
import '../presentation/screens/rooms/room_assignment_detail_screen.dart';
import '../presentation/screens/auth/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RiverpodRouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RiverpodRouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RiverpodRouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      debugPrint(
        'Router redirect: isLoggedIn=${authState != null}, location=${state.matchedLocation}',
      );

      final isLoggedIn = authState != null;
      final needsName = isLoggedIn && authState.fullName.trim().isEmpty;
      final isSplashRoute = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation == '/login';
      final isCallbackRoute = state.matchedLocation == '/login-callback';
      final isSetupNameRoute = state.matchedLocation == '/setup-name';

      if (!isLoggedIn && !isAuthRoute && !isCallbackRoute && !isSplashRoute) {
        final target = state.uri.toString();
        Hive.openBox<String>('auth_redirect').then((box) {
          box.put('redirectTo', target);
        });
        return '/login?redirectTo=${Uri.encodeComponent(target)}';
      }

      if (isLoggedIn && needsName && !isSetupNameRoute && !isSplashRoute) {
        return '/setup-name';
      }

      if (isLoggedIn &&
          !needsName &&
          (isAuthRoute || isCallbackRoute || isSetupNameRoute)) {
        String? redirectTo = state.uri.queryParameters['redirectTo'];

        if (redirectTo == null || redirectTo.isEmpty) {
          if (Hive.isBoxOpen('auth_redirect')) {
            final box = Hive.box<String>('auth_redirect');
            redirectTo = box.get('redirectTo');
            box.delete('redirectTo');
          }
        }

        if (redirectTo != null && redirectTo.isNotEmpty) {
          try {
            return Uri.decodeComponent(redirectTo);
          } catch (_) {
            return redirectTo;
          }
        }
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/rooms',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const RoomEntryScreen(),
        ),
      ),
      GoRoute(
        path: '/rooms/create',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const RoomCreateScreen(),
        ),
      ),
      GoRoute(
        path: '/rooms/join',
        pageBuilder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return _buildPageWithTransition(
            state: state,
            child: RoomJoinScreen(initialCode: code),
          );
        },
      ),
      GoRoute(
        path: '/rooms/:roomId',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: RoomDashboardScreen(roomId: state.pathParameters['roomId']!),
        ),
      ),
      GoRoute(
        path: '/rooms/:roomId/subjects/:subjectId',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: SubjectAssignmentsScreen(
            roomId: state.pathParameters['roomId']!,
            subjectId: state.pathParameters['subjectId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/rooms/:roomId/assignments/:assignmentId',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: RoomAssignmentDetailScreen(
            roomId: state.pathParameters['roomId']!,
            assignmentId: state.pathParameters['assignmentId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/setup-name',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const FullNameScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/login-callback',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      ),
    ],
  );
});

CustomTransitionPage _buildPageWithTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: ValueKey(state.uri.toString()),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.15), // Start slightly below (15% of screen height)
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}
