import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget Function() onInitializationComplete;

  const SplashScreen({super.key, required this.onInitializationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return widget.onInitializationComplete();
    } else {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
