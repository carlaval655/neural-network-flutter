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

      for (final animEntry in animatedEdges.entries) {
  final animEdge = animEntry.key;
  final progress = animEntry.value;

  // Coincide en dirección directa o inversa
  final matchesForward = animEdge.from == edge.from && animEdge.to == edge.to;
  final matchesBackward = animEdge.from == edge.to && animEdge.to == edge.from;

  if (matchesForward || matchesBackward) {
    final start = matchesBackward ? to : from;
    final end = matchesBackward ? from : to;

    final point = Offset(
      start.dx + (end.dx - start.dx) * progress,
      start.dy + (end.dy - start.dy) * progress,
    );
    final color = matchesBackward
        ? const Color.fromARGB(255, 59, 246, 72) // Azul para retropropagación
        : const Color.fromARGB(255, 255, 59, 59); // Rojo para propagación directa
    canvas.drawCircle(point, 5, Paint()..color = color);
  }
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