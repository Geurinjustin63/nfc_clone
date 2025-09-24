import 'package:flutter/material.dart';

class CardDetailsScreen extends StatelessWidget {
  const CardDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Details'),
      ),
      body: const Center(
        child: Text('Card details screen will be implemented here'),
      ),
    );
  }
}