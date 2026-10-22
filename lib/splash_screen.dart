import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ================= LOGO =================
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  // ================= TEXT =================
  late AnimationController _textController;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;

  // ================= LOADING =================
  int _activeDot = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();

    // ================= LOGO =================
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.97, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.97).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
    ]).animate(_logoController);

    _logoController.repeat(reverse: true);

    // ================= TEXT =================
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    _textOpacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _textController.forward();
      }
    });

    // ================= LOADING =================
    Future.delayed(const Duration(milliseconds: 900), () {
      _startLoadingAnimation();
    });

    // ================= LOGIN CHECK =================
    _checkLogin();
  }

  void _startLoadingAnimation() {
    _dotTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (timer) {
        if (!mounted) return;

        setState(() {
          _activeDot = (_activeDot + 1) % 5;
        });
      },
    );
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(milliseconds: 2400));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _dotTimer?.cancel();
    super.dispose();
  }

  // ================= LOADING DOT =================
  Widget buildDot(int index) {
    bool isActive = index == _activeDot;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: isActive ? 11 : 7,
      height: isActive ? 11 : 7,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF9B3C7D)
            : const Color(0xFFD8A8C6),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // ================= LOGO =================
                ScaleTransition(
                  scale: _logoAnimation,

                  child: Image.asset(
                    'assets/LogoRetali.png',
                    width: 170,
                    height: 170,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 28),

                // ================= TEXT =================
                FadeTransition(
                  opacity: _textOpacityAnimation,

                  child: SlideTransition(
                    position: _textSlideAnimation,

                    child: const Text(
                      "Retali Mustajab Travel",
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8D3B70),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 45),
                // ================= DOT LOADING =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => buildDot(index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}