import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/AuthGate.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {

  @override
  void initState() {
    Timer(const Duration(seconds: 3), () => Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const AuthGate())));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green[50],
      child: const Center(
        child: Text("Exam Scheduler 201177", style: TextStyle(
            color: Colors.deepPurple,
            decoration: TextDecoration.none
        ),),
      ),
    );
  }
}