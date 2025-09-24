import 'package:flutter/material.dart';

class CardsListScreen extends StatelessWidget {
  const CardsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cards'),
      ),
      body: const Center(
        child: Text('Cards list screen will be implemented here'),
      ),
    );
  }
}