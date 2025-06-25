/// screens/network_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  bool isTraining = false;
  int currentEpoch = 0;
  List<FlSpot> errorPoints = [];

  late Node biasNode;

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
      isTraining = false;
      currentEpoch = 0;
      errorPoints.clear();
    });
  }

  void _toggleEditMode() {
    setState(() => editMode = !editMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Red Neuronal Visual'),
        actions: [
          if (isTraining)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () {
                setState(() => isTraining = false);
              },
            )
        ],
      ),
      body: Stack(
        children: [
          // Mostrar epoch encima de la tabla y gráfico
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Epoch: $currentEpoch',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Tabla de valores y gráfico de error, uno al lado del otro
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            height: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tabla de valores
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Valores por epoch',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 600),
                              child: IntrinsicWidth(
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowColor: MaterialStatePropertyAll(Colors.grey),
                                    columns: const [
                                      DataColumn(label: Text('x1', style: TextStyle(color: Colors.white))),
                                      DataColumn(label: Text('x2', style: TextStyle(color: Colors.white))),
                                      DataColumn(label: Text('y_esp', style: TextStyle(color: Colors.white))),
                                      DataColumn(label: Text('y_obt', style: TextStyle(color: Colors.white))),
                                      DataColumn(label: Text('err', style: TextStyle(color: Colors.white))),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Gráfico de error
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Evolución del error promedio',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              lineBarsData: [
                                LineChartBarData(
                                  spots: errorPoints,
                                  isCurved: true,
                                  color: Colors.orange,
                                  barWidth: 2,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.2)),
                                )
                              ],
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: true),
                              gridData: FlGridData(show: true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Aquí va el resto de la UI (red neuronal)
          Positioned.fill(
            top: 360,
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
                      edges: edges.where((e) => e.from != biasNode).toList(),
                      animatedEdges: animatedEdges,
                    ),
                    child: Container(),
                  ),
                ),
                ...nodes.where((n) => n != biasNode).map(
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
            IconButton(
              onPressed: _entrenarOR,
              icon: const Icon(Icons.lightbulb),
            ),
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
    final rand = Random();
    final bias = Node(id: nextId++, position: const Offset(50, 50));
    bias.value = 1.0;

    nodes.addAll([i1, i2, o1]);
    network.addNode(i1);
    network.addNode(i2);
    network.addNode(o1);
    network.addNode(bias);
    this.biasNode = bias;

    i1.value = 0.0;
    i2.value = 0.0;

    final e1 = Edge(from: i1, to: o1, weight: rand.nextDouble() * 2 - 1);
    final e2 = Edge(from: i2, to: o1, weight: rand.nextDouble() * 2 - 1);
    final e3 = Edge(from: bias, to: o1, weight: 0.5); // sesgo inicial para ayudar

    edges.addAll([e1, e2, e3]);
    // e3 (bias) ahora se agrega a edges para estar incluido en retropropagación, pero se mantiene oculto visualmente
    network.addEdge(e1);
    network.addEdge(e2);
    network.addEdge(e3); // mantener la conexión lógica del bias
  });
}

  // Entrenamiento para compuerta lógica AND sin bias, tabla simple
  void _entrenarAND() async {
    const double learningRate = 0.5;
    const trainingData = [
      [0.0, 0.0, 0.0],
      [0.0, 1.0, 0.0],
      [1.0, 0.0, 0.0],
      [1.0, 1.0, 1.0],
    ];

    isTraining = true;
    currentEpoch = 0;
    errorPoints.clear();

    List<List<String>> history = trainingData.map((data) => [
      data[0].toString(),
      data[1].toString(),
      data[2].toString(),
      '',
      '',
    ]).toList();

    for (int epoch = 0; epoch < 3000 && isTraining; epoch++) {
      currentEpoch = epoch + 1;

      for (int i = 0; i < trainingData.length; i++) {
        final data = trainingData[i];
        if (nodes.length < 3) return;
        final i1 = nodes[0];
        final i2 = nodes[1];
        final o1 = nodes[2];
        final bias = biasNode;

        for (final n in nodes) {
          if (n != i1 && n != i2 && n != bias) n.value = 0.0;
        }

        i1.value = data[0];
        i2.value = data[1];
        final expected = data[2];

        for (final edge in edges) {
          await _animateEdge(edge);
          edge.to.value += edge.from.value * edge.weight;
        }

        o1.value = 1 / (1 + exp(-o1.value));
        final obtained = o1.value.clamp(0.0, 1.0);
        final error = expected - obtained;

        if (expected == 1.0 && obtained < 0.9) {
          //logHistory.add('Advertencia: salida incorrecta para caso (1,1) en epoch $currentEpoch: ${obtained.toStringAsFixed(2)}');
        }

        for (final edge in edges.where((e) => e.to == o1)) {
          final derivative = obtained * (1 - obtained); // derivada del sigmoide
          final delta = learningRate * error * derivative * edge.from.value;
          final oldWeight = edge.weight;
          edge.weight += delta;
          edge.weight = edge.weight.clamp(-1.0, 1.0);
          if ((edge.weight - oldWeight).abs() > 0.0001) {
            //logHistory.add('Epoch $currentEpoch - Peso actualizado ${edge.from.id}->${edge.to.id}: ${oldWeight.toStringAsFixed(3)} → ${edge.weight.toStringAsFixed(3)}');
            final reverseEdge = Edge(from: edge.to, to: edge.from);
            await _animateEdge(reverseEdge);
          }
        }

        history[i][3] = obtained.toStringAsFixed(2);
        history[i][4] = error.toStringAsFixed(2);
      }

      await Future.delayed(const Duration(milliseconds: 150));
      logHistory = history.map((row) => 'x1=${row[0]}, x2=${row[1]}, y_esp=${row[2]}, y_obt=${row[3]}, err=${row[4]}').toList();

      double avgError = history.map((row) => double.tryParse(row[4])?.abs() ?? 0.0).reduce((a, b) => a + b) / history.length;
      errorPoints.add(FlSpot(currentEpoch.toDouble(), avgError));
      logHistory.add('Epoch $currentEpoch - Error promedio: ${avgError.toStringAsFixed(4)}');

      if (avgError <= 0.01) {
        logHistory.add('Entrenamiento detenido automáticamente por bajo error promedio.');
        break;
      }

      setState(() {});
    }

    isTraining = false;
  }

  void _entrenarOR() async {
    const double learningRate = 0.5;
    const trainingData = [
      [0.0, 0.0, 0.0],
      [0.0, 1.0, 1.0],
      [1.0, 0.0, 1.0],
      [1.0, 1.0, 1.0],
    ];

    isTraining = true;
    currentEpoch = 0;
    errorPoints.clear();

    List<List<String>> history = trainingData.map((data) => [
      data[0].toString(),
      data[1].toString(),
      data[2].toString(),
      '',
      '',
    ]).toList();

    for (int epoch = 0; epoch < 3000 && isTraining; epoch++) {
      currentEpoch = epoch + 1;

      for (int i = 0; i < trainingData.length; i++) {
        final data = trainingData[i];
        if (nodes.length < 3) return;
        final i1 = nodes[0];
        final i2 = nodes[1];
        final o1 = nodes[2];
        final bias = biasNode;

        for (final n in nodes) {
          if (n != i1 && n != i2 && n != bias) n.value = 0.0;
        }

        i1.value = data[0];
        i2.value = data[1];
        final expected = data[2];

        for (final edge in edges) {
          await _animateEdge(edge);
          edge.to.value += edge.from.value * edge.weight;
        }

        o1.value = 1 / (1 + exp(-o1.value));
        final obtained = o1.value.clamp(0.0, 1.0);
        final error = expected - obtained;

        for (final edge in edges.where((e) => e.to == o1)) {
          final derivative = obtained * (1 - obtained);
          final delta = learningRate * error * derivative * edge.from.value;
          final oldWeight = edge.weight;
          edge.weight += delta;
          edge.weight = edge.weight.clamp(-1.0, 1.0);
          if ((edge.weight - oldWeight).abs() > 0.0001) {
            final reverseEdge = Edge(from: edge.to, to: edge.from);
            await _animateEdge(reverseEdge);
          }
        }

        history[i][3] = obtained.toStringAsFixed(2);
        history[i][4] = error.toStringAsFixed(2);
      }

      await Future.delayed(const Duration(milliseconds: 150));
      logHistory = history.map((row) => 'x1=${row[0]}, x2=${row[1]}, y_esp=${row[2]}, y_obt=${row[3]}, err=${row[4]}').toList();

      double avgError = history.map((row) => double.tryParse(row[4])?.abs() ?? 0.0).reduce((a, b) => a + b) / history.length;
      errorPoints.add(FlSpot(currentEpoch.toDouble(), avgError));
      logHistory.add('Epoch $currentEpoch - Error promedio: ${avgError.toStringAsFixed(4)}');

      if (avgError <= 0.01) {
        logHistory.add('Entrenamiento detenido automáticamente por bajo error promedio.');
        break;
      }

      setState(() {});
    }

    isTraining = false;
  }
  
}
