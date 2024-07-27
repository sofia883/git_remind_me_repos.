import 'package:flutter/material.dart';
import 'home_page.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    // Navigate to RemindersPage after 6 seconds
    Future.delayed(Duration(seconds: 6), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RemindersPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/wlcm_page.jpg',
            fit: BoxFit.cover,
          ),
          Center(
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
        ],
      ),
    );
  }
}
