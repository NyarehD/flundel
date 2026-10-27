import 'package:flundel/features/debug/debug_audio_screen.dart';
import 'package:flundel/features/debug/generative_visual_debug_screen.dart';
import 'package:flundel/features/focus/focus_screen.dart';
import 'package:flundel/features/home/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/focus',
        name: 'focus',
        builder: (context, state) => const FocusScreen(),
      ),
      GoRoute(
        path: '/debug-audio',
        name: 'debug-audio',
        builder: (context, state) => const DebugAudioScreen(),
      ),
      GoRoute(
        path: '/generative-debug',
        name: 'generative-debug',
        builder: (context, state) => const GenerativeVisualDebugScreen(),
      ),
    ],
  );
});
