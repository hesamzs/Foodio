import 'dart:async';
import 'package:flutter/material.dart';

import 'main.dart';

class SplashScreenWithAnimation extends StatefulWidget {
  const SplashScreenWithAnimation({super.key});

  @override
  _SplashScreenWithAnimationState createState() =>
      _SplashScreenWithAnimationState();
}

class _SplashScreenWithAnimationState extends State<SplashScreenWithAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Define a fade animation
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    // Start the animation
    _animationController.forward();

    // Navigate to the main page after the animation duration
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ContactListPage()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Expanded(flex: 1,child: SizedBox(),),

              // App logo with animation
              Image.asset('assets/icon.png', width: 150),
              const SizedBox(height: 20),

              // Text under the logo
              const Text(
                "Created by 💚 HesamZs",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              const Text(
                "v0.1",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
              ),
              const Expanded(flex: 2,child: SizedBox(),),
            ],
          ),
        ),
      ),
    );
  }
}
