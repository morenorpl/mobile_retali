import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:mobile_retali/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  final _emailC = TextEditingController();
  final _passC = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final email = _emailC.text.trim();
    final pass = _passC.text;

    setState(() => _loading = true);

    final result = await ApiService.login(email, pass);

    if (!mounted) return;

    setState(() => _loading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            result['message'] ?? 'Login gagal',
          ),
        ),
      );
    }
  }

  InputDecoration customInput({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 15,
      ),

      prefixIcon: Icon(
        icon,
        color: const Color(0xFF8B2F6B),
      ),

      suffixIcon: suffixIcon,

      filled: false,

      contentPadding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 0,
      ),

      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Colors.grey.shade300,
          width: 1.2,
        ),
      ),

      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: Color(0xFF8B2F6B),
          width: 2,
        ),
      ),

      border: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: FadeTransition(
        opacity: _fadeAnim,

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 20,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // ================= LOGO =================
                  Hero(
                    tag: 'logo',

                    child: Image.asset(
                      'assets/LogoZero.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // ================= TITLE =================
                  const Text(
                    "Selamat Datang",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B2F6B),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Silahkan masukkan akun anda",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 55),

                  // ================= EMAIL =================
                  TextField(
                    controller: _emailC,
                    keyboardType: TextInputType.emailAddress,

                    decoration: customInput(
                      hint: "Masukan Email",
                      icon: Icons.email_outlined,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ================= PASSWORD =================
                  TextField(
                    controller: _passC,
                    obscureText: _obscurePassword,

                    decoration: customInput(
                      hint: "Masukan Password",
                      icon: Icons.lock_outline,

                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },

                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 45),

                  // ================= BUTTON LOGIN =================
                  SizedBox(
                    width: double.infinity,
                    height: 58,

                    child: ElevatedButton(
                      onPressed: _loading ? null : _doLogin,

                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF8B2F6B),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),

                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,

                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              "Masuk",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ================= FOOTER =================
                  Text(
                    "Zero Complaint",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}