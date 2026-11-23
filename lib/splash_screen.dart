import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/presence_service.dart';

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
    final role = (prefs.getString('role') ?? '').toLowerCase().replaceAll('_', '').trim();

    if (!mounted) return;

    // Pastikan admin tidak bisa login (hanya tour leader dan muthawif)
    if (role == 'admin') {
      await ApiService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      return;
    }

    if (token != null && token.isNotEmpty) {
      NotificationService.setupSupabaseRealtime();
      NotificationService.checkAndTriggerPendingNotifications();
      PresenceService.start();

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
    final bool isActive = index == _activeDot;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive
            ? const Color(0xFFEAB308)
            : const Color(0x3DEAB308),
        boxShadow: isActive
            ? const [
                BoxShadow(
                  color: Color(0x99EAB308),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }

  // ================= ISLAMIC STAR MOTIF HELPER =================
  Widget _buildIslamicStarPattern({
    required double size,
    Color color = const Color(0xFFEAB308),
    double borderWidth = 1.0,
  }) {
    final double starSquareSize = size * 0.78;
    final double borderRadius = size * 0.08;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: borderWidth),
            ),
          ),
          // First square
          Container(
            width: starSquareSize,
            height: starSquareSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: color, width: borderWidth),
            ),
          ),
          // Second square rotated 45 degrees (Rub el Hizb 8-pointed star)
          Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(
              width: starSquareSize,
              height: starSquareSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: color, width: borderWidth),
              ),
            ),
          ),
          // Inner circle
          Container(
            width: size * 0.52,
            height: size * 0.52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: borderWidth * 0.8),
            ),
          ),
          // Center diamond
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius * 0.5),
                border: Border.all(color: color, width: borderWidth * 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1523),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Stack(
          children: [
            // ================= RADIAL GRADIENT GLOW BACKGROUND =================
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0D1523),
                gradient: RadialGradient(
                  center: Alignment(0, -0.18),
                  radius: 1.25,
                  colors: [
                    Color(0xFF1B3167), // rich primary navy glow
                    Color(0xFF131F35), // intermediate navy
                    Color(0xFF0D1523), // deep dark navy edge
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // ================= WATERMARK ISLAMIC GEOMETRIC PATTERNS =================
            Positioned(
              top: -65,
              right: -65,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.05,
                  child: _buildIslamicStarPattern(size: 260),
                ),
              ),
            ),
            Positioned(
              bottom: -65,
              left: -65,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.05,
                  child: _buildIslamicStarPattern(size: 260),
                ),
              ),
            ),

            // ================= MAIN CONTENT =================
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(),

                      // ================= LOGO WITH GOLDEN GLOW & ISLAMIC FRAME =================
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft golden glow container with BoxShadow
                          Container(
                            width: 170,
                            height: 170,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x38EAB308), // golden aura
                                  blurRadius: 55,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: Color(0x601B3167), // deep navy glow
                                  blurRadius: 75,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),

                          // Outer decorative circular ring
                          Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0x1FEAB308),
                                width: 1.0,
                              ),
                            ),
                          ),

                          // Islamic 8-pointed star motif behind the logo
                          Transform.rotate(
                            angle: 0.785398, // 45 degrees
                            child: Container(
                              width: 182,
                              height: 182,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0x28EAB308),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 182,
                            height: 182,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0x28EAB308),
                                width: 1.2,
                              ),
                            ),
                          ),

                          // Inner golden circular border with subtle radial sheen
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0x38EAB308),
                                width: 1.5,
                              ),
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0x1AEAB308),
                                  Color(0x051B3167),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          // Logo with breathing scale animation
                          ScaleTransition(
                            scale: _logoAnimation,
                            child: Container(
                              width: 135,
                              height: 135,
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                'assets/LogoRetali.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // ================= TEXT (ANIMATED SLIDE & FADE) =================
                      FadeTransition(
                        opacity: _textOpacityAnimation,
                        child: SlideTransition(
                          position: _textSlideAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Decorative gold accent divider
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 1,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Color(0x80EAB308),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Transform.rotate(
                                    angle: 0.785398,
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAB308),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 28,
                                    height: 1,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0x80EAB308),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // "retali sistem"
                              RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 3.5,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "retali ",
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    TextSpan(
                                      text: "sistem",
                                      style: TextStyle(
                                        color: Color(0xFFEAB308),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              // "Zero Complaint"
                              const Text(
                                "Zero Complaint",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                  height: 1.25,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x40EAB308),
                                      blurRadius: 18,
                                      offset: Offset(0, 3),
                                    ),
                                    Shadow(
                                      color: Color(0x80000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Glassmorphic Subtitle Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x80263754),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0x33EAB308),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  "UMRAH TRAVEL MANAGEMENT",
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ================= LOADING INDICATOR =================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (index) => buildDot(index),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "Memuat sistem...",
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ================= ELEGANT FOOTER =================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 0.8,
                            color: const Color(0x28EAB308),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "Amanah • Khidmat • Profesional",
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            width: 16,
                            height: 0.8,
                            color: const Color(0x28EAB308),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
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
