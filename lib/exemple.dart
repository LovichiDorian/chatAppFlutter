import 'package:flutter/material.dart';

class Exemple extends StatelessWidget {
  const Exemple({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
