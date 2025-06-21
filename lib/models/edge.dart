/// models/edge.dart
import 'node.dart';

class Edge {
  final Node from;
  final Node to;
  double weight;

  Edge({required this.from, required this.to, this.weight = 1.0});
}
