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
      _status = 'Initiating download...';
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
            content: Text('Downloaded $modelName'),
            duration: const Duration(seconds: 2),
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
      title: const Text('Pull Model', style: TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              enabled: !_isPulling,
              autofocus: true,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: 'e.g. llama3.2:3b, qwen2.5:7b',
                prefixIcon: Icon(Icons.download_rounded, size: 16),
              ),
              onSubmitted: (_) => _isPulling ? null : _startPull(),
            ),
            const SizedBox(height: 14),
            Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _popularModels.map((m) {
                return InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: _isPulling ? null : () => _controller.text = m,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      m,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_isPulling) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _status ?? 'Downloading...',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_progress != null)
                    Text(
                      '${(_progress! * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
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
                style: TextStyle(fontSize: 11.5, color: colorScheme.error),
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
        FilledButton(
          onPressed: _isPulling ? null : _startPull,
          child: Text(_isPulling ? 'Downloading...' : 'Download'),
        ),
      ],
    );
  }
}
