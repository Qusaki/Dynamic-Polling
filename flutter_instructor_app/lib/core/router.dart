import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import your screen files here
import 'package:flutter_instructor_app/features/splash/splash_screen.dart';
import 'package:flutter_instructor_app/features/auth/login_screen.dart';
import 'package:flutter_instructor_app/features/dashboard/dashboard_screen.dart';
import 'package:flutter_instructor_app/features/live_session/live_session_screen.dart'; // Corrected import
import 'package:flutter_instructor_app/features/create_poll/create_multi_question_poll_screen.dart';
import 'package:flutter_instructor_app/features/poll_management/poll_management_screen.dart'; // New import


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/create-poll',
        builder: (context, state) => const CreateMultiQuestionPollScreen(),
      ),
      GoRoute(
        path: '/poll/:id', // This path now correctly leads to the live session
        builder: (context, state) {
          final pollId = state.pathParameters['id']!;
          return LiveSessionScreen(pollId: pollId);
        },
        routes: [ // Nested route for poll management
          GoRoute(
            path: 'manage',
            builder: (context, state) {
              final pollId = state.pathParameters['id']!;
              return PollManagementScreen(pollId: pollId);
            },
          ),
        ],
      ),
    ],
  );
});
