import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ollama_process_manager.dart';
import 'core/providers.dart';
import 'core/theme.dart';
import 'router.dart';

class OllamaApp extends ConsumerStatefulWidget {
  const OllamaApp({super.key});

  @override
  ConsumerState<OllamaApp> createState() => _OllamaAppState();
}

class _OllamaAppState extends ConsumerState<OllamaApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // Ensure Ollama is running and notify Riverpod providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OllamaProcessManager().startIfNeeded(ref: ref);
    });

    // Clean up background daemon process on app exit if spawned by us
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        OllamaProcessManager().stopIfSpawned();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Ollama GUI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
