/// logic/neural_network.dart
import '../models/node.dart';
import '../models/edge.dart';
import 'dart:math';

class NeuralNetwork {
  final List<Node> _nodes = [];
  final List<Edge> _edges = [];

  void addNode(Node node) => _nodes.add(node);
  void addEdge(Edge edge) => _edges.add(edge);

  void reset() {
    _nodes.clear();
    _edges.clear();
  }

  void forwardPropagation() {

    for (final edge in _edges) {
      edge.to.value += edge.from.value * edge.weight;
    }
  }
}