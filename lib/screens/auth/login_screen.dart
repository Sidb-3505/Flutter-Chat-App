import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:we_chat/helper/dialogs.dart';
import 'package:we_chat/screens/home_screen.dart';
import '../../main.dart';
import '../../network/apis.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimate = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isAnimate = true;
      });
    });
  }

  _handleGoogleBtnClick() async {
    ///for showing progress bar while loading
    Dialogs.showProgressIndicator(context);

    /// Attempt to sign in with Google
    User? user = await APIs.authService.signInWithGoogle(context).then((
      user,
    ) async {
      ///for hiding progress bar
      Navigator.pop(context);

      /// If sign-in is successful, navigate to the HomeScreen
      if (user != null) {
        if (await APIs.userExists()) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
          );
        } else {
          await APIs.createUser().then((value) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
            );
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Scaffold(
      /// App Bar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Welcome to We Chat',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w400),
        ),
      ),

      body: Stack(
        children: [
          ///login screen image
          AnimatedPositioned(
            duration: const Duration(seconds: 3),
            top: mq.height * .15,
            left: _isAnimate ? mq.width * .21 : mq.width,
            child: SizedBox(
              width: mq.width * 0.55, // Fixed width so it doesn't shrink
              child: Image.asset('images/app_icon.png'),
            ),
          ),

          ///login with google button
          Positioned(
            left: mq.width * .05,
            bottom: mq.width * .3,
            height: mq.height * .06,
            width: mq.width * .9,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreenAccent.shade100,
                shape: const StadiumBorder(),
                elevation: 1,
              ),
              onPressed: () async {
                _handleGoogleBtnClick();
              },
              icon: Image.asset('images/google_image.png'),
              label: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 22),
                  children: [
                    TextSpan(text: 'Login with '),
                    TextSpan(
                      text: 'Google',
                      style: TextStyle(fontWeight: FontWeight.w500),
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
