import 'package:flutter/material.dart';
import '../../core/theme.dart';

enum ConnectionStatus {
  connected,
  disconnected,
  loading,
}

/// A small colored dot indicating connection status.
class StatusDot extends StatelessWidget {
  const StatusDot({
    super.key,
    required this.status,
    this.size = 8,
  });

  final ConnectionStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final Color color;
    switch (status) {
      case ConnectionStatus.connected:
        color = colors.success;
        break;
      case ConnectionStatus.disconnected:
        color = colors.error;
        break;
      case ConnectionStatus.loading:
        color = colors.warning;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
