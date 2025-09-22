import 'dart:async';
import 'package:farego/home/homepage.dart';
import 'package:flutter/material.dart';

class Intro2 extends StatefulWidget {
  const Intro2({super.key});

  @override
  State<Intro2> createState() => _Intro2State();
}

class _Intro2State extends State<Intro2> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> pages = [
    {
      "image": "assets/images/qr-code_1.png",
      "text":
          "QR code scanners use pattern recognition technology to capture data from a QR code image and convert it into text or other formats.",
    },
    {
      "image": "assets/images/distance_1.png",
      "text":
          "Distance traveled is the total length of the path an object covers during its movement, from its initial point to its final point.",
    },
    {
      "image": "assets/images/cashless-payment_1.png",
      "text":
          "A passenger scans the QR code displayed by the merchant using their smartphone's camera.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentPage < pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _timer?.cancel(); // Stop auto scroll on last page
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF13D4D4), Color(0xFFF3F3F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(pages[index]["image"]!, height: 250),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          pages[index]["text"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // Smooth transition between dots and button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _currentPage == pages.length - 1
                  ? ElevatedButton(
                      key: const ValueKey("button"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3ADDBC),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Homepage()),
                        );
                      },
                      child: const Text(
                        "Get Started",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    )
                  : Row(
                      key: const ValueKey("dots"),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(pages.length, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 12 : 8,
                          height: _currentPage == index ? 12 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.teal
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
