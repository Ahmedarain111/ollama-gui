import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

class ModelfileScreen extends StatelessWidget {
  const ModelfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modelfile Editor'),
      ),
      body: Center(
        child: EmptyState(
          icon: Icons.code_rounded,
          title: 'Modelfile Editor',
          subtitle: 'Visual and raw editor for building custom model variants.',
          action: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Text(
              'Planned for Phase 2',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
