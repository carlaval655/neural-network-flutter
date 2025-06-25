/// screens/network_screen.dart
import 'dart:math';
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
  double sigmoid(double x) => 1 / (1 + exp(-x));

  final List<Node> nodes = [];
  final List<Edge> edges = [];
  final network = NeuralNetwork();
  int nextId = 0;

  Node? selectedNode;
  bool isConnecting = false;
  bool editMode = false;
  Map<Edge, double> animatedEdges = {};
  List<String> logHistory = [];

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

  Future<void> _animateEdge(Edge edge) async {
    for (double t = 0.0; t <= 1.0; t += 0.05) {
      setState(() {
        animatedEdges = {edge: t};
      });
      await Future.delayed(const Duration(milliseconds: 5));
    }
    setState(() {
      animatedEdges = {};
    });
  }

void _trainNetwork() async {
  if (nodes.length < 3) return;

  final input1 = nodes[0];
  final input2 = nodes[1];
  final output = nodes[2];

  // Reset valor del nodo de salida
  output.value = 0.0;

  for (final edge in edges) {
    await _animateEdge(edge);
    edge.to.value += edge.from.value * edge.weight;
  }

  output.value = sigmoid(output.value);

  setState(() {});

  // Mostrar salida obtenida
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Salida obtenida: ${output.value.toStringAsFixed(2)}'),
      duration: const Duration(seconds: 2),
    ),
  );
}

  void _reset() {
    setState(() {
      nodes.clear();
      edges.clear();
      network.reset();
      nextId = 0;
      selectedNode = null;
      isConnecting = false;
      logHistory.clear();
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
          // Tabla fija en esquina superior izquierda
          Positioned(
            top: 0,
            left: 0,
            width: 800, // Ajusta ancho según necesites
            height: 180, // Ajusta alto según necesites
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // <--- Scroll horizontal
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey[800]),
                  columns: const [
                    DataColumn(
                      label: Text('x1', style: TextStyle(color: Colors.white)),
                    ),
                    DataColumn(
                      label: Text('x2', style: TextStyle(color: Colors.white)),
                    ),
                    DataColumn(
                      label: Text('y_esp', style: TextStyle(color: Colors.white)),
                    ),
                    DataColumn(
                      label: Text('y_obt', style: TextStyle(color: Colors.white)),
                    ),
                    DataColumn(
                      label: Text('err', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  rows: logHistory.map((logEntry) {
                    final parts = logEntry.split(', ');
                    String x1 = parts.length > 0 ? parts[0].split('=').last : '';
                    String x2 = parts.length > 1 ? parts[1].split('=').last : '';
                    String yEsp = parts.length > 2 ? parts[2].split('=').last : '';
                    String yObt = parts.length > 3 ? parts[3].split('=').last : '';
                    String err = parts.length > 4 ? parts[4].split('=').last : '';

                    return DataRow(
                      cells: [
                        DataCell(Text(x1)),
                        DataCell(Text(x2)),
                        DataCell(Text(yEsp)),
                        DataCell(Text(yObt)),
                        DataCell(Text(err)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Aquí va el resto de la UI (red neuronal)
          Positioned.fill(
            top: 180,
            child: Stack(
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
                          ((tapPos.dx - from.dx) * dx +
                              (tapPos.dy - from.dy) * dy) /
                          lengthSquared;
                      if (t < 0.0 || t > 1.0) continue;

                      final proj = Offset(from.dx + t * dx, from.dy + t * dy);
                      final distance = (tapPos - proj).distance;

                      if (distance < 10) {
                        _editEdgeWeight(edge);
                        break;
                      }
                    }
                  },
                  child: CustomPaint(
                    painter: ConnectionPainter(
                      edges: edges,
                      animatedEdges: animatedEdges,
                    ),
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
            IconButton(
              onPressed: _crearEjemploDosCapas,
              icon: const Icon(Icons.auto_fix_high),
            ),
            IconButton(onPressed: _entrenarAND, icon: const Icon(Icons.bolt)),
          ],
        ),
      ),
    );
  }

 void _crearEjemploDosCapas() {
  setState(() {
    nodes.clear();
    edges.clear();
    network.reset();
    nextId = 0;

    final i1 = Node(id: nextId++, position: const Offset(50, 100));
    final i2 = Node(id: nextId++, position: const Offset(50, 200));
    final o1 = Node(id: nextId++, position: const Offset(300, 150));

    nodes.addAll([i1, i2, o1]);
    network.addNode(i1);
    network.addNode(i2);
    network.addNode(o1);

    i1.value = 0.0;
    i2.value = 0.0;

    final e1 = Edge(from: i1, to: o1, weight: 1.0);
    final e2 = Edge(from: i2, to: o1, weight: 1.0);

    edges.addAll([e1, e2]);
    network.addEdge(e1);
    network.addEdge(e2);
  });
}

  // Entrenamiento para compuerta lógica AND sin bias, tabla simple
  void _entrenarAND() async {
    const double learningRate = 2.0;
    const trainingData = [
      [0.0, 0.0, 0.0],
      [0.0, 1.0, 0.0],
      [1.0, 0.0, 0.0],
      [1.0, 1.0, 1.0],
    ];

    for (int epoch = 0; epoch < 100; epoch++) {
      for (final data in trainingData) {
        if (nodes.length < 3) return; // Se requieren 2 entradas y 1 salida
        final i1 = nodes[0];
        final i2 = nodes[1];
        final o1 = nodes[2];

        // Reset valor del nodo de salida
        o1.value = 0.0;

        i1.value = data[0];
        i2.value = data[1];
        final expected = data[2];

        // Propagación hacia adelante
        for (final edge in edges) {
          edge.to.value += edge.from.value * edge.weight;
        }

        o1.value = 1 / (1 + exp(-o1.value)); // aplicar sigmoide
        final obtained = o1.value;
        final error = expected - obtained;

        // Ajuste de pesos (solo conexiones hacia o1)
        for (final edge in edges.where((e) => e.to == o1)) {
          final delta = learningRate * error * edge.from.value;
          edge.weight += delta;
        }

        // Registrar para la tabla: x1, x2, y_esperado, y_obtenido, error
        logHistory.add(
          'x1=${i1.value}, x2=${i2.value}, y_esp=$expected, y_obt=${obtained.toStringAsFixed(2)}, err=${error.toStringAsFixed(2)}',
        );

        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {});
      }
    }
  }

  
}
