import 'package:flutter/material.dart';

class NFCScannerScreen extends StatelessWidget {
  const NFCScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Scanner'),
      ),
      body: const Center(
        child: Text('NFC Scanner screen will be implemented here'),
      ),
    );
  }
}