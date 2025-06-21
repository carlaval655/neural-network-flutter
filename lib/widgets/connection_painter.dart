/// widgets/connection_painter.dart
import 'package:flutter/material.dart';
import '../models/edge.dart';

class ConnectionPainter extends CustomPainter {
  final List<Edge> edges;

  ConnectionPainter({required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    for (final edge in edges) {
      canvas.drawLine(edge.from.position + const Offset(25, 25), edge.to.position + const Offset(25, 25), paint);

      final mid = Offset(
        (edge.from.position.dx + edge.to.position.dx) / 2,
        (edge.from.position.dy + edge.to.position.dy) / 2,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: edge.weight.toStringAsFixed(1),
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, mid);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}