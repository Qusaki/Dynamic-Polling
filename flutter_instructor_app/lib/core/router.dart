import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_instructor_app/features/auth/login_screen.dart';
import 'package:flutter_instructor_app/features/dashboard/dashboard_screen.dart';
import 'package:flutter_instructor_app/features/live_session/live_session_screen.dart';
import 'package:flutter_instructor_app/features/create_poll/create_multi_question_poll_screen.dart';
import 'package:flutter_instructor_app/features/poll_management/poll_management_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(), // Changed to LoginScreen
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
        path: '/poll/:id',
        builder: (context, state) {
          final pollId = state.pathParameters['id']!;
          return LiveSessionScreen(pollId: pollId);
        },
        routes: [
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
