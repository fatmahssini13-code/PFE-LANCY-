import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe/service/auth_service.dart';
import 'package:pfe/service/proposal_service.dart';

class SendProposalScreen extends StatefulWidget {
  final String token;
  final String projectId;
  final String? projectTitle;

  const SendProposalScreen({
    super.key,
    required this.token,
    required this.projectId,
    this.projectTitle,
  });

  @override
  State<SendProposalScreen> createState() => _SendProposalScreenState();
}

class _SendProposalScreenState extends State<SendProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _timeController = TextEditingController();
  final _messageController = TextEditingController();

  final ProposalService service = ProposalService();
  bool loading = false;

  // Couleurs Lancy
  final Color primaryBlue = const Color(0xFF00AEEF);
  final Color primaryPurple = const Color(0xFF8E2DE2);

  // --- STYLE DES CHAMPS ---
  InputDecoration _buildInputStyle(
    String label,
    IconData icon, {
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
      prefixIcon: Icon(icon, color: primaryBlue, size: 20),
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: primaryPurple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

Future<void> send() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => loading = true);

  final token = await AuthService.getToken();

  final ok = await service.createProposal(
    token: token!,
    projectId: widget.projectId,
    coverLetter: _messageController.text,
    price: int.parse(_priceController.text),
    deliveryTime: int.parse(_timeController.text),
  );

  setState(() => loading = false);

  if (ok) {
    // ✅ snackbar صغيرة
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Proposition envoyée ✅"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // ✅ يرجع للـ Home بعد شوية صغيرة
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context);
    });

  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Erreur lors de l'envoi ❌"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: isError ? Colors.redAccent : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Nouvelle Proposition",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Détails de votre offre",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Soyez précis pour augmenter vos chances d'être retenu.",
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),

              const SizedBox(height: 30),

              // --- CHAMP MESSAGE ---
              Text(
                "Lettre de motivation",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: _buildInputStyle(
                  "Expliquez pourquoi vous êtes le meilleur...",
                  Icons.edit_note,
                ),
                validator: (v) => v!.length < 20
                    ? "Détaillez un peu plus votre message"
                    : null,
              ),

              const SizedBox(height: 20),

              // --- LIGNE PRIX ET DÉLAI ---
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Prix",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: _buildInputStyle(
                            "000",
                            Icons.payments_outlined,
                            suffix: "DT",
                          ),
                          validator: (v) => v!.isEmpty ? "Requis" : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Délai",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _timeController,
                          keyboardType: TextInputType.number,
                          decoration: _buildInputStyle(
                            "00",
                            Icons.timer_outlined,
                            suffix: "Jours",
                          ),
                          validator: (v) => v!.isEmpty ? "Requis" : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // --- BOUTON ENVOYER ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : send,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, primaryPurple],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Envoyer l'offre",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
