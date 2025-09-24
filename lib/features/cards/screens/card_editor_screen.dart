import 'package:flutter/material.dart';

class CardEditorScreen extends StatelessWidget {
  const CardEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Card'),
      ),
      body: const Center(
        child: Text('Card editor screen will be implemented here'),
      ),
    );
  }
}