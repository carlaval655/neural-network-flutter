/// widgets/neuron_widget.dart
import 'package:flutter/material.dart';
import '../models/node.dart';

class NeuronWidget extends StatefulWidget {
  final Node node;
  final Function(Offset) onPositionChanged;
  final VoidCallback onTap;

  const NeuronWidget({super.key, required this.node, required this.onPositionChanged, required this.onTap});

  @override
  State<NeuronWidget> createState() => _NeuronWidgetState();
}

class _NeuronWidgetState extends State<NeuronWidget> {
  Offset offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    offset = widget.node.position;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: (details) {
          setState(() {
            offset += details.delta;
            widget.onPositionChanged(offset);
          });
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.node.value.toStringAsFixed(2),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
