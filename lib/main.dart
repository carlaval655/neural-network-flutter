/// main.dart
import 'package:flutter/material.dart';
import 'screens/network_screen.dart';

void main() {
  runApp(const NeuralNetworkApp());
}

class NeuralNetworkApp extends StatelessWidget {
  const NeuralNetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Red Neuronal Visual',
      theme: ThemeData.dark(),
      home: const NetworkScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}