import 'dart:ui';

/// models/node.dart
class Node {
  final int id;
  Offset position;
  double value;

  Node({required this.id, required this.position, this.value = 0.0});
}
