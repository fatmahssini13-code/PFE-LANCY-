import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Pour la gestion simplifiée des Snackbars et de la navigation
import 'package:google_fonts/google_fonts.dart'; // Pour une typographie moderne
import 'package:pfe/service/api_service.dart'; // Service pour communiquer avec Node.js
import 'otp_verification_screen.dart'; // Écran suivant pour valider l'inscription

class RegisterScreen extends StatefulWidget {
  final String email; // Email récupéré éventuellement d'une étape précédente
  final String role;  // Rôle choisi : 'freelancer' ou 'client'

  const RegisterScreen({super.key, required this.email, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Clé globale pour valider le formulaire
  final _formKey = GlobalKey<FormState>();

  // Palette de couleurs spécifique à l'identité Lancy
  final Color mintCrystal = const Color(0xFF81E38F);
  final Color skyBlue = const Color(0xFF74C0FC);
  final Color backgroundLight = const Color(0xFFF9FBFF);
  final Color darkText = const Color(0xFF1A1C1E);

  // Contrôleurs de texte pour récupérer les saisies
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final confirmPassC = TextEditingController();
  final skillsC = TextEditingController(); // Spécifique Freelancer
  final bioC = TextEditingController();   // Spécifique Freelancer
  
  bool hidePassword = true; // État pour masquer/afficher le mot de passe
  bool loading = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplissage de l'email si passé en paramètre
    emailC.text = widget.email;
  }

  @override
  void dispose() {
    // Nettoyage des contrôleurs pour éviter les fuites de mémoire
    nameC.dispose();
    emailC.dispose();
    passC.dispose();
    confirmPassC.dispose();
    skillsC.dispose();
    bioC.dispose();
    super.dispose();
  }

  // --- LOGIQUE D'INSCRIPTION ---
  Future<void> _doRegister() async {
    // 1. Validation locale du formulaire (champs vides, etc.)
    if (!_formKey.currentState!.validate()) return;

    // 2. Vérification de la correspondance des mots de passe
    if (passC.text != confirmPassC.text) {
      Get.snackbar("Erreur 🌸", "Les mots de passe ne correspondent pas",
          backgroundColor: Colors.redAccent.withOpacity(0.8), colorText: Colors.white);
      return;
    }

    // Préparation du corps de la requête JSON
    Map<String, dynamic> userData = {
      "name": nameC.text.trim(),
      "email": emailC.text.trim(),
      "password": passC.text,
      "role": widget.role,
      // Ajout des données conditionnelles selon le rôle
      "skills": widget.role == "freelancer" ? skillsC.text.trim() : "",
      "bio": widget.role == "freelancer" ? bioC.text.trim() : "",
    };

    try {
      // Affichage d'un indicateur de chargement modal
      Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.white)), barrierDismissible: false);

      // 3. Appel de la méthode statique du service API (Backend Node.js)
      await ApiService.register(userData);

      if (!mounted) return;
      if (Get.isDialogOpen!) Get.back(); // Fermer le chargement

      // 4. Notification de succès et redirection vers l'OTP
      Get.snackbar("Presque fini ! ✨", "Un code de vérification a été envoyé.",
          backgroundColor: mintCrystal.withOpacity(0.9), colorText: Colors.white);

      Get.to(() => OTPVerificationScreen(
            email: emailC.text.trim(),
            isFromRegister: true, // Indique qu'on vient de l'inscription
          ));

    } catch (e) {
      if (Get.isDialogOpen!) Get.back();
      Get.snackbar("Erreur ❌", e.toString().replaceAll("Exception: ", ""),
          backgroundColor: Colors.redAccent.withOpacity(0.8), colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Variable pour simplifier l'affichage conditionnel
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
              // Titre dynamique selon le rôle
              Text(
                isFreelancer ? "Join as\nExpert 🌸" : "Start as\nClient ✨",
                style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: darkText, height: 1.1),
              ),
              const SizedBox(height: 10),
              Text(
                "Créez votre compte pour commencer l'aventure.",
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 15),
              ),
              const SizedBox(height: 35),

              // Champ : Nom Complet
              _buildModernField(
                controller: nameC,
                hint: "Nom Complet",
                icon: Icons.person_outline_rounded,
                validator: (v) => v == null || v.isEmpty ? "Nom requis" : null,
              ),
              const SizedBox(height: 20),

              // Champ : Email
              _buildModernField(
                controller: emailC,
                hint: "Adresse Email",
                icon: Icons.alternate_email_rounded,
                validator: (v) => v == null || !v.contains("@") ? "Email invalide" : null,
              ),
              const SizedBox(height: 20),

              // Champ : Mot de passe
              _buildModernField(
                controller: passC,
                hint: "Mot de passe",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                validator: (v) => v == null || v.length < 6 ? "Min 6 caractères" : null,
              ),
              const SizedBox(height: 20),

              // Champ : Confirmation
              _buildModernField(
                controller: confirmPassC,
                hint: "Confirmer le mot de passe",
                icon: Icons.lock_reset_rounded,
                isPassword: true,
                validator: (v) => v != passC.text ? "Mots de passe différents" : null,
              ),

              // CHAMPS SPÉCIFIQUES AU FREELANCER (Affichage conditionnel)
              if (isFreelancer) ...[
                const SizedBox(height: 20),
                _buildModernField(
                  controller: skillsC,
                  hint: "Compétences (ex: Flutter, Design)",
                  icon: Icons.auto_awesome_outlined,
                  validator: (v) => v == null || v.isEmpty ? "Compétences requises" : null,
                ),
                const SizedBox(height: 20),
                _buildModernField(
                  controller: bioC,
                  hint: "Biographie courte",
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? "Bio requise" : null,
                ),
              ],

              const SizedBox(height: 40),
              _buildSubmitButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET RÉUTILISABLE POUR LES CHAMPS DE SAISIE ---
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
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

  // --- BOUTON DE SOUMISSION GRADIENT ---
  Widget _buildSubmitButton() {
    return InkWell(
      onTap: _doRegister,
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
          child: Text(
            "CRÉER MON COMPTE",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
        ),
      ),
    );
  }
}