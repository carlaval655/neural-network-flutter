/// screens/network_screen.dart
import 'package:flutter/material.dart';
import '../models/node.dart';
import '../models/edge.dart';
import '../widgets/neuron_widget.dart';
import '../widgets/connection_painter.dart';
import '../logic/neural_network.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  final List<Node> nodes = [];
  final List<Edge> edges = [];
  final network = NeuralNetwork();
  int nextId = 0;

  Node? selectedNode;
  bool isConnecting = false;
  bool editMode = false;
  Map<Edge, double> animatedEdges = {};

  void _addNode() {
    setState(() {
      final node = Node(id: nextId++, position: const Offset(100, 100));
      nodes.add(node);
      network.addNode(node);
    });
  }

  void _toggleConnectionMode() {
    setState(() {
      isConnecting = !isConnecting;
      selectedNode = null;
    });
  }

  void _onNodeTap(Node tappedNode) {
    if (isConnecting) {
      if (selectedNode == null) {
        selectedNode = tappedNode;
      } else if (selectedNode != tappedNode) {
        setState(() {
          final edge = Edge(from: selectedNode!, to: tappedNode);
          edges.add(edge);
          network.addEdge(edge);
          selectedNode = null;
        });
      }
    } else if (editMode) {
      _editNodeValue(tappedNode);
    }
  }

  void _editNodeValue(Node node) async {
    final controller = TextEditingController(text: node.value.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar valor del nodo"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Valor"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                Navigator.pop(context, value);
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => node.value = result);
    }
  }

  void _editEdgeWeight(Edge edge) async {
    final controller = TextEditingController(text: edge.weight.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar peso de conexión"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Peso"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                Navigator.pop(context, value);
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => edge.weight = result);
    }
  }

  void _animateForwardPass() async {
    for (final edge in edges) {
      for (double t = 0.0; t <= 1.0; t += 0.05) {
        setState(() {
          animatedEdges = {edge: t};
        });
        await Future.delayed(const Duration(milliseconds: 16));
      }
      setState(() {
        edge.to.value += edge.from.value * edge.weight;
        animatedEdges = {};
      });
    }
  }

  void _trainNetwork() {
    _animateForwardPass();
  }

  void _reset() {
    setState(() {
      nodes.clear();
      edges.clear();
      network.reset();
      nextId = 0;
      selectedNode = null;
      isConnecting = false;
    });
  }

  void _toggleEditMode() {
    setState(() => editMode = !editMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Red Neuronal Visual')),
      body: Stack(
        children: [
          GestureDetector(
            onTapUp: (details) {
              final tapPos = details.localPosition;
              for (final edge in edges) {
                final from = edge.from.position + const Offset(25, 25);
                final to = edge.to.position + const Offset(25, 25);

                final dx = to.dx - from.dx;
                final dy = to.dy - from.dy;
                final lengthSquared = dx * dx + dy * dy;
                if (lengthSquared == 0) continue;

                final t =
                    ((tapPos.dx - from.dx) * dx + (tapPos.dy - from.dy) * dy) /
                    lengthSquared;
                if (t < 0.0 || t > 1.0) continue;

                final proj = Offset(from.dx + t * dx, from.dy + t * dy);
                final distance = (tapPos - proj).distance;

                if (distance < 10) {
                  // sensibilidad del clic
                  _editEdgeWeight(edge);
                  break;
                }
              }
            },
            child: CustomPaint(
              painter: ConnectionPainter(edges: edges, animatedEdges: animatedEdges),
              child: Container(),
            ),
          ),
          ...nodes.map(
            (node) => NeuronWidget(
              node: node,
              onTap: () => _onNodeTap(node),
              onPositionChanged: (offset) {
                setState(() => node.position = offset);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(onPressed: _addNode, icon: const Icon(Icons.add_circle)),
            IconButton(
              onPressed: _toggleConnectionMode,
              icon: Icon(isConnecting ? Icons.link_off : Icons.link),
            ),
            IconButton(
              onPressed: _toggleEditMode,
              icon: Icon(editMode ? Icons.edit_off : Icons.edit),
            ),
            IconButton(
              onPressed: _trainNetwork,
              icon: const Icon(Icons.play_arrow),
            ),
            IconButton(onPressed: _reset, icon: const Icon(Icons.refresh)),
          ],
        ),
      ),
    );
  }
}
