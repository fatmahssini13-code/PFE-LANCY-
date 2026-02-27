import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe/screens/auth/ChooseRoleScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();

  final Color mintCrystal = const Color(0xFF81E38F);
  final Color skyBlue = const Color(0xFF74C0FC);
  final Color backgroundLight = const Color(0xFFF9FBFF);
  final Color darkText = const Color(0xFF1A1C1E);

  String msg = "";
  bool loading = false;
  bool hidePassword = true;

  Future<void> doLogin() async {
    if (!formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      msg = "";
    });

    // Simulation API
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        loading = false;
        msg = "Login success (test)";
      });
    }
  }

  @override
  void dispose() {
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- ICON LOGO ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: skyBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Icon(Icons.shield_moon_rounded, size: 50, color: skyBlue),
                  ),
                  const SizedBox(height: 30),

                  // --- TITRES ---
                  Text(
                    "Welcome Back",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your credentials to continue",
                    style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 15),
                  ),
                  const SizedBox(height: 40),

                  // --- EMAIL FIELD ---
                  _buildModernField(
                    controller: emailC,
                    hint: "Email Address",
                    icon: Icons.alternate_email_rounded,
                    validator: (v) => v == null || !v.contains("@") ? "Valid email required" : null,
                  ),
                  const SizedBox(height: 20),

                  // --- PASSWORD FIELD ---
                  _buildModernField(
                    controller: passC,
                    hint: "Password",
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator: (v) => v == null || v.length < 6 ? "Min 6 characters" : null,
                  ),

                  // --- FORGOT PASSWORD ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        "Forgot Password?",
                        style: GoogleFonts.inter(
                          color: skyBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  if (msg.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Text(msg, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),

                  const SizedBox(height: 10),

                  // --- LOGIN BUTTON ---
                  _buildGradientButton(),

                  const SizedBox(height: 30),

                  // --- REGISTER LINK ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don’t have an account? ", style: GoogleFonts.inter(color: Colors.grey[600])),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChooseRoleScreen())),
                        child: Text(
                          "Create one",
                          style: GoogleFonts.inter(
                            color: darkText,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? hidePassword : false,
        validator: validator,
        style: GoogleFonts.inter(color: darkText, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: skyBlue, size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildGradientButton() {
    return InkWell(
      onTap: loading ? null : doLogin,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [skyBlue, mintCrystal]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: skyBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  "LOGIN",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
        ),
      ),
    );
  }
}