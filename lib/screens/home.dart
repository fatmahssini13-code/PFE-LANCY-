import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  final String role;

  const HomeScreen({super.key, required this.email, required this.role});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Palette de couleurs Premium
  final Color mintCrystal = const Color(0xFF81E38F);
  final Color skyBlue = const Color(0xFF74C0FC);
  final Color backgroundLight = const Color(0xFFF9FBFF);
  final Color darkText = const Color(0xFF1A1C1E);

  @override
  Widget build(BuildContext context) {
    bool isClient = widget.role == "client";

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          "LANCY",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: darkText,
          ),
        ),
        iconTheme: IconThemeData(color: darkText),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: CircleAvatar(
              backgroundColor: skyBlue.withOpacity(0.1),
              child: Icon(Icons.notifications_none_rounded, color: skyBlue),
            ),
          ),
        ],
      ),
      drawer: _buildModernDrawer(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER DE BIENVENUE ---
            _buildWelcomeHeader(isClient),
            const SizedBox(height: 30),

            // --- SECTION STATISTIQUES ---
            _buildStatRow(isClient),
            const SizedBox(height: 35),

            // --- SECTION ACTIONS / CONTENU ---
            Text(
              isClient ? "Manage Projects" : "Recommended for You",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 15),
            
            isClient ? _buildClientActions() : _buildProjectList(),
          ],
        ),
      ),
    );
  }

  // --- COMPOSANTS UI ---

  Widget _buildWelcomeHeader(bool isClient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hello, ${widget.email.split('@')[0]}!",
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        Text(
          isClient ? "Find the best AI talent today." : "Explore new opportunities.",
          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildStatRow(bool isClient) {
    return Row(
      children: [
        _buildStatCard("Active", isClient ? "3" : "12", skyBlue),
        const SizedBox(width: 15),
        _buildStatCard("Pending", isClient ? "1" : "4", mintCrystal),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildClientActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [skyBlue, skyBlue.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 15),
          Text(
            "Have a new idea?",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            "Post a project and get proposals within hours.",
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: skyBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text("Post a Project", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildProjectList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                height: 50, width: 50,
                decoration: BoxDecoration(color: mintCrystal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.auto_awesome, color: mintCrystal),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("AI Model Fine-tuning", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    Text("\$500 - \$1200", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernDrawer() {
    return Drawer(
      backgroundColor: backgroundLight,
      child: Column(
        children: [
          _buildDrawerHeader(),
          const SizedBox(height: 20),
          _drawerItem(Icons.grid_view_rounded, "Dashboard", active: true),
          _drawerItem(Icons.message_outlined, "Messages"),
          _drawerItem(Icons.account_balance_wallet_outlined, "Payments"),
          _drawerItem(Icons.settings_outlined, "Settings"),
          const Spacer(),
          const Divider(indent: 20, endIndent: 20),
          _drawerItem(Icons.logout_rounded, "Logout", color: Colors.redAccent, onTap: () => Get.offAllNamed("/login")),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, bottom: 25, right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [skyBlue, mintCrystal]),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, size: 35)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.role.toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(widget.email, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, {bool active = false, Color? color, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? (active ? skyBlue : Colors.grey[600])),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: color ?? (active ? skyBlue : darkText),
          fontWeight: active ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      horizontalTitleGap: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
    );
  }
}