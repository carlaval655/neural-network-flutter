/// widgets/connection_painter.dart
import 'package:flutter/material.dart';
import '../models/edge.dart';

class ConnectionPainter extends CustomPainter {
  final List<Edge> edges;
  final Map<Edge, double> animatedEdges;

  ConnectionPainter({required this.edges, this.animatedEdges = const {}});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    for (final edge in edges) {
      final from = edge.from.position + const Offset(25, 25);
      final to = edge.to.position + const Offset(25, 25);
      canvas.drawLine(from, to, paint);

      if (animatedEdges.containsKey(edge)) {
        final progress = animatedEdges[edge]!;
        final point = Offset(
          from.dx + (to.dx - from.dx) * progress,
          from.dy + (to.dy - from.dy) * progress,
        );
        canvas.drawCircle(point, 5, Paint()..color = const Color.fromARGB(255, 255, 59, 59));
      }

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