import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe/screens/home.dart';

class RegisterScreen extends StatefulWidget {
  final String email;
  final String role;

  const RegisterScreen({super.key, required this.email, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Palette de couleurs Premium
  final Color mintCrystal = const Color(0xFF81E38F);
  final Color skyBlue = const Color(0xFF74C0FC);
  final Color backgroundLight = const Color(0xFFF9FBFF);
  final Color darkText = const Color(0xFF1A1C1E);

  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final skillsC = TextEditingController();
  final bioC = TextEditingController();

  bool hidePassword = true;

  @override
  void initState() {
    super.initState();
    emailC.text = widget.email;
  }

  @override
  void dispose() {
    nameC.dispose(); emailC.dispose(); passC.dispose();
    skillsC.dispose(); bioC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isFreelancer = widget.role == "freelancer";

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Text(
                isFreelancer ? "Join as\nExpert" : "Start as\nClient",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Create your account to bridge your skills.",
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 15),
              ),
              const SizedBox(height: 35),

              // --- CHAMPS COMMUNS ---
              _buildModernField(
                controller: nameC,
                hint: "Full Name",
                icon: Icons.person_outline_rounded,
                validator: (v) => v == null || v.isEmpty ? "Name required" : null,
              ),
              const SizedBox(height: 20),
              
              _buildModernField(
                controller: emailC,
                hint: "Email Address",
                icon: Icons.alternate_email_rounded,
                validator: (v) => v == null || !v.contains("@") ? "Valid email required" : null,
              ),
              const SizedBox(height: 20),

              _buildModernField(
                controller: passC,
                hint: "Password",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                validator: (v) => v == null || v.length < 6 ? "Min 6 characters" : null,
              ),

              // --- CHAMPS FREELANCER ---
              if (isFreelancer) ...[
                const SizedBox(height: 20),
                _buildModernField(
                  controller: skillsC,
                  hint: "Skills (e.g. Flutter, Design)",
                  icon: Icons.auto_awesome_outlined,
                  validator: (v) => v == null || v.isEmpty ? "Skills required" : null,
                ),
                const SizedBox(height: 20),
                _buildModernField(
                  controller: bioC,
                  hint: "Brief Bio",
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? "Bio required" : null,
                ),
              ],

              const SizedBox(height: 40),

              // --- BOUTON DE VALIDATION ---
              _buildSubmitButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Widget de champ stylisé
  Widget _buildModernField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? hidePassword : false,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.inter(color: darkText, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
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

  // Bouton dégradé Premium
  Widget _buildSubmitButton() {
    return InkWell(
      onTap: () {
        if (_formKey.currentState!.validate()) {
          // Logique de création de compte ici
          Get.offAll(() => HomeScreen(email: emailC.text, role: widget.role));
        }
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [skyBlue, mintCrystal]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: skyBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "CREATE ACCOUNT",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}