import 'package:go_router/go_router.dart';

import 'features/chat/chat_screen.dart';
import 'features/modelfile/modelfile_screen.dart';
import 'features/models/models_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/app_shell.dart';

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
            return NoTransitionPage(
              child: ChatScreen(initialConversationId: convId),
            );
          },
        ),
        GoRoute(
          path: '/models',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ModelsScreen(),
          ),
        ),
        GoRoute(
          path: '/modelfile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ModelfileScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
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
