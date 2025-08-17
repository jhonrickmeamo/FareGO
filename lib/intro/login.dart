import 'package:flutter/material.dart';
import 'sign_up.dart';
import 'package:farego/home/homepage.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Future<void> _preloadSignUpImages(BuildContext context) async {
    await precacheImage(
      const AssetImage('assets/images/top-circle_1.png'),
      context,
    );
    await precacheImage(
      const AssetImage('assets/images/top-circle_2.png'),
      context,
    );
    await precacheImage(
      const AssetImage('assets/images/bottom_1.png'),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF13D4D4), Color(0xFFF3F3F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Top-right circles
            Positioned(
              top: -160,
              right: -215,
              child: Image.asset(
                'assets/images/top-circle_1.png',
                height: 500,
                width: 500,
              ),
            ),
            Positioned(
              top: -160,
              right: -240,
              child: Image.asset(
                'assets/images/top-circle_2.png',
                height: 500,
                width: 500,
              ),
            ),
            // Bottom wave
            Positioned(
              bottom: -215,
              left: 0,
              right: -50,
              child: Image.asset(
                'assets/images/bottom_1.png',
                fit: BoxFit.cover,
              ),
            ),
            // Main content
            Positioned(
              left: 0,
              right: 0,
              bottom: 160,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LOG IN',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            await _preloadSignUpImages(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUp(),
                              ),
                            );
                          },
                          child: const Text(
                            "create account",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      decoration: InputDecoration(
                        hintText: '+69',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Homepage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
