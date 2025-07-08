import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:we_chat/screens/auth/login_screen.dart';
import 'package:we_chat/screens/home_screen.dart';
import '../main.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      ///exit full-screen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white,
          statusBarColor: Colors.white,
        ),
      );

      ///checking if the user is already logged in
      if (FirebaseAuth.instance.currentUser != null) {
        ///navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => HomeScreen(user: FirebaseAuth.instance.currentUser!),
          ),
        );
      } else {
        ///navigate to login screen if user not logged in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          ///Home screen image
          Positioned(
            top: mq.height * .18,
            left: mq.width * .21,
            child: SizedBox(
              width: mq.width * 0.55, // Fixed width so it doesn't shrink
              child: Image.asset('images/app_icon.png'),
            ),
          ),

          ///Home Screen Text
          Positioned(
            bottom: mq.width * .18,
            width: mq.width,
            child: Text(
              'Made By Sid❤️',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                letterSpacing: .5,
                fontSize: 27,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
