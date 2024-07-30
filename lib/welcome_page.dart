import 'package:flutter/material.dart';
import 'main.dart'; // Ensure this is the correct import path

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _fadeInAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeIn,
    );

    _controller?.forward();

    Future.delayed(Duration(seconds: 6), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()), // Correct target
      );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/white.jpg',
            fit: BoxFit.cover,
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeInAnimation!,
              child: RichText(
                text: TextSpan(
                  text: 'Welcome to ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 20.0,
                        color: Colors.black,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Remind',
                      style: TextStyle(color: Colors.yellow),
                    ),
                    TextSpan(
                      text: ' Me',
                      style: TextStyle(color: Colors.yellow),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
