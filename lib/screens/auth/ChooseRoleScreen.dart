import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:google_fonts/google_fonts.dart'; // Optionnel : installe google_fonts pour un look pro
import 'register.dart';

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> with SingleTickerProviderStateMixin {
  // Couleurs du projet
  final Color mintCrystal = const Color(0xFF81E38F);
  final Color skyBlue = const Color(0xFF74C0FC);
  final Color backgroundLight = const Color(0xFFF9FBFF);
  final Color darkText = const Color(0xFF1A1C1E);

  String selectedRole = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Stack(
        children: [
          // Formes décoratives en arrière-plan
          Positioned(
            top: -100,
            right: -50,
            child: _buildCircle(300, skyBlue.withOpacity(0.05)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildCircle(200, mintCrystal.withOpacity(0.08)),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Icon(Icons.arrow_back_ios_new, color: skyBlue, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Badge dynamique
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: skyBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            "STEP 1 OF 2",
                            style: TextStyle(color: skyBlue, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        Text(
                          "How would you like to use the platform?",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Carte Client
                        _premiumRoleCard(
                          title: "I'm a Client",
                          subtitle: "I want to hire talent for my projects",
                          role: "client",
                          mainColor: skyBlue,
                          icon: Icons.business_center_rounded,
                        ),

                        const SizedBox(height: 20),

                        // Carte Freelancer
                        _premiumRoleCard(
                          title: "I'm a Freelancer",
                          subtitle: "I'm looking for work and AI opportunities",
                          role: "freelancer",
                          mainColor: mintCrystal,
                          icon: Icons.bolt_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumRoleCard({
    required String title,
    required String subtitle,
    required String role,
    required Color mainColor,
    required IconData icon,
  }) {
    bool isSelected = selectedRole == role;

    return GestureDetector(
      onTapDown: (_) => setState(() => selectedRole = role),
      onTap: () {
        Future.delayed(const Duration(milliseconds: 250), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RegisterScreen(role: role, email: '')),
          );
        });
      },
      child: AnimatedScale(
        scale: isSelected ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? mainColor : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected 
                    ? mainColor.withOpacity(0.3) 
                    : Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Box
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [mainColor.withOpacity(0.2), mainColor.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: mainColor, size: 30),
              ),
              const SizedBox(width: 20),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: darkText.withOpacity(0.5),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Radio Indicator
              Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? mainColor : Colors.grey.shade300,
                    width: isSelected ? 7 : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}