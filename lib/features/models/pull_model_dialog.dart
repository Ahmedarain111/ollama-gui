import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import 'models_providers.dart';

class PullModelDialog extends ConsumerStatefulWidget {
  const PullModelDialog({super.key});

  @override
  ConsumerState<PullModelDialog> createState() => _PullModelDialogState();
}

class _PullModelDialogState extends ConsumerState<PullModelDialog> {
  final _controller = TextEditingController();
  bool _isPulling = false;
  String? _status;
  double? _progress;
  String? _errorMessage;

  static const _popularModels = [
    'llama3.2:3b',
    'llama3.2:1b',
    'qwen2.5:7b',
    'qwen2.5:3b',
    'deepseek-r1:7b',
    'phi4-mini',
    'mistral',
    'nomic-embed-text',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startPull() async {
    final modelName = _controller.text.trim();
    if (modelName.isEmpty) return;

    setState(() {
      _isPulling = true;
      _status = 'Starting pull...';
      _progress = null;
      _errorMessage = null;
    });

    try {
      final client = ref.read(ollamaClientProvider);
      await client.pullModel(
        modelName,
        onProgress: (PullProgress p) {
          if (!mounted) return;
          setState(() {
            _status = p.status;
            if (p.total != null && p.total! > 0 && p.completed != null) {
              _progress = p.completed! / p.total!;
            }
          });
        },
      );

      if (mounted) {
        ref.read(modelsNotifierProvider.notifier).refresh();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully pulled $modelName!'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPulling = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Pull Model from Ollama'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a model name or tag from the Ollama library:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              enabled: !_isPulling,
              decoration: InputDecoration(
                hintText: 'e.g. llama3.2:3b, qwen2.5:7b',
                prefixIcon: const Icon(Icons.download_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (_) => _isPulling ? null : _startPull(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Popular models:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _popularModels.map((m) {
                return ActionChip(
                  label: Text(m, style: const TextStyle(fontSize: 11)),
                  onPressed: _isPulling
                      ? null
                      : () {
                          _controller.text = m;
                        },
                );
              }).toList(),
            ),
            if (_isPulling) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _progress,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _status ?? 'Downloading...',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_progress != null)
                    Text(
                      '${(_progress! * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isPulling ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text(_isPulling ? 'Pulling...' : 'Pull Model'),
          onPressed: _isPulling ? null : _startPull,
        ),
      ],
    );
  }
}
