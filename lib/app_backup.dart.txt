import 'package:flutter/material.dart';

class HydrofixApp extends StatelessWidget {
  const HydrofixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydrofix',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087E8B),
        ),
        useMaterial3: true,
      ),

      home: const Scaffold(
        body: Center(
          child: Text(
            'Welcome to Hydrofix',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}