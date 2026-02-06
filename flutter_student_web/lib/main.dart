
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// Import screens (to be created)
import 'features/join/join_screen.dart';
import 'features/vote/vote_screen.dart';

void main() {
  runApp(const ProviderScope(child: StudentWebApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const JoinScreen(),
      ),
      GoRoute(
        path: '/vote/:accessCode',
        builder: (context, state) {
          final accessCode = state.pathParameters['accessCode']!;
          return VoteScreen(accessCode: accessCode);
        },
      ),
    ],
  );
});

class StudentWebApp extends ConsumerWidget {
  const StudentWebApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Dynamic Polling - Student',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      routerConfig: router,
    );
  }
}
