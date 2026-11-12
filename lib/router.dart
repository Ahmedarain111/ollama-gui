import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/chat/chat_screen.dart';
import 'features/modelfile/modelfile_screen.dart';
import 'features/models/models_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/app_shell.dart';

Page<dynamic> _buildSmoothPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.012),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/chat',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) {
            final id = state.uri.queryParameters['id'];
            final convId = id != null ? int.tryParse(id) : null;
            return _buildSmoothPage(
              key: state.pageKey,
              child: ChatScreen(initialConversationId: convId),
            );
          },
        ),
        GoRoute(
          path: '/models',
          pageBuilder: (context, state) => _buildSmoothPage(
            key: state.pageKey,
            child: const ModelsScreen(),
          ),
        ),
        GoRoute(
          path: '/modelfile',
          pageBuilder: (context, state) => _buildSmoothPage(
            key: state.pageKey,
            child: const ModelfileScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _buildSmoothPage(
            key: state.pageKey,
            child: const SettingsScreen(),
          ),
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    if (state.uri.path == '/') return '/chat';
    return null;
  },
);
