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
          icon: Icons.edit_note_rounded,
          title: 'Modelfile Visual & Raw Editor',
          subtitle:
              'Customize base models, system prompts, context parameters, and create new models via Modelfile.',
          action: OutlinedButton.icon(
            icon: const Icon(Icons.code_rounded),
            label: const Text('Planned for Phase 2'),
            onPressed: null,
          ),
        ),
      ),
    );
  }
}
