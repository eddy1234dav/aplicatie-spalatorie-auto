import 'package:flutter/material.dart';

class BluetoothTab extends StatelessWidget {
  const BluetoothTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth')),
      body: const Center(
        child: Text(
          'Conectare prin bluetooth.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
