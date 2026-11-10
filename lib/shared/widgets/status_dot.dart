import 'package:flutter/material.dart';

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
    this.size = 10,
  });

  final ConnectionStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status) {
      case ConnectionStatus.connected:
        color = const Color(0xFF22C55E); // Green
        break;
      case ConnectionStatus.disconnected:
        color = const Color(0xFFEF4444); // Red
        break;
      case ConnectionStatus.loading:
        color = const Color(0xFFEAB308); // Yellow/Amber
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
