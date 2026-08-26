import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/phone_auth_screen.dart';
import '../../features/auth/screens/player_setup_screen.dart';
import '../../features/auth/screens/join_or_build_screen.dart';
import '../../features/auth/screens/invite_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/league/screens/league_screen.dart';
import '../../features/main/main_shell.dart';
import '../../features/organizer/screens/organizer_home_screen.dart';
import '../../features/player/screens/profile_screen.dart';
import '../../features/player/screens/player_profile_screen.dart';
import '../../features/player/screens/player_card_screen.dart';
import '../../features/scorer/screens/open_session_screen.dart';
import '../../features/scorer/screens/session_qr_screen.dart';
import '../../features/scorer/screens/team_assignment_screen.dart';
import '../../features/scorer/screens/active_scorer_screen.dart';
import '../../features/scorer/screens/innings_transition_screen.dart';
import '../../features/scorer/screens/post_match_screen.dart';
import '../../features/scorer/screens/mvp_screen.dart';
import '../../features/scorer/screens/witness_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    // Splash — no shell
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // Onboarding flow — no shell
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/auth/phone',
      builder: (context, state) => const PhoneAuthScreen(),
    ),
    GoRoute(
      path: '/auth/setup',
      builder: (context, state) => const PlayerSetupScreen(),
    ),
    GoRoute(
      path: '/auth/join-or-build',
      builder: (context, state) => const JoinOrBuildScreen(),
    ),
    GoRoute(
      path: '/auth/invite',
      builder: (context, state) => const InviteScreen(),
    ),

    // Shell routes — with bottom nav
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/league',
          builder: (context, state) => const LeagueScreen(),
        ),
        GoRoute(
          path: '/play',
          builder: (context, state) => const OpenSessionScreen(),
        ),
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
        ),
        GoRoute(
          path: '/me',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // Full-screen routes — no nav
    GoRoute(
      path: '/organizer',
      builder: (context, state) => const OrganizerHomeScreen(),
    ),
    GoRoute(
      path: '/session/qr',
      builder: (context, state) => const SessionQrScreen(),
    ),
    GoRoute(
      path: '/session/teams',
      builder: (context, state) => const TeamAssignmentScreen(),
    ),
    GoRoute(
      path: '/match/scorer',
      builder: (context, state) => const ActiveScorerScreen(),
    ),
    GoRoute(
      path: '/match/innings-transition',
      builder: (context, state) => const InningsTransitionScreen(),
    ),
    GoRoute(
      path: '/match/witness',
      builder: (context, state) => const WitnessScreen(),
    ),
    GoRoute(
      path: '/match/post-match',
      builder: (context, state) => const PostMatchScreen(),
    ),
    GoRoute(
      path: '/match/mvp',
      builder: (context, state) {
        final name = state.uri.queryParameters['name'] ?? 'Roshan KC';
        final stats = state.uri.queryParameters['stats'] ?? '58*(39)  ·  3/24';
        return MvpScreen(playerName: name, stats: stats);
      },
    ),
    GoRoute(
      path: '/player/:id',
      builder: (context, state) {
        final playerId = state.pathParameters['id'] ?? '';
        return PlayerProfileScreen(playerId: playerId);
      },
    ),
    GoRoute(
      path: '/player/:id/card',
      builder: (context, state) {
        final playerId = state.pathParameters['id'] ?? '';
        return PlayerCardScreen(playerId: playerId);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.error}'),
    ),
  ),
);
