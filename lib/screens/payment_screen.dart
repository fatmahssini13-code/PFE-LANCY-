import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe/service/auth_service.dart';
import 'package:pfe/service/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final String projectId;
  final dynamic amount;
  final String projectTitle;
  final dynamic client;
  final dynamic freelancer;

  const PaymentScreen({
    super.key,
    required this.projectId,
    required this.amount,
    required this.projectTitle,
    required this.client,
    required this.freelancer,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  Widget build(BuildContext context) {
    const Color lancyPurple = Color(0xFF8E2DE2);
    const Color skyBlue = Color(0xFF74C0FC);

    // Extraction dynamique des noms
    final String clientName = (widget.client is Map) 
        ? (widget.client["name"] ?? "Client") 
        : "Fatma";
    
    final String freelancerName = (widget.freelancer is Map) 
        ? (widget.freelancer["name"] ?? "Freelancer") 
        : "ezzdin";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text("Paiement sécurisé", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [lancyPurple, skyBlue]),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Bannière Escrow
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lancyPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lancyPurple.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: lancyPurple, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Fonds sécurisés par le système Escrow.",
                      style: GoogleFonts.inter(color: lancyPurple, fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Carte Détails du Projet
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: lancyPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.work_outline, color: lancyPurple),
                      ),
                      const SizedBox(width: 15),
                      Text(widget.projectTitle, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 30),
                  _buildDetailRow(Icons.person_outline, "Client", clientName),
                  const SizedBox(height: 15),
                  _buildDetailRow(Icons.engineering_outlined, "Freelancer", freelancerName),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Carte Montant (Gradient comme sur ton image)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [lancyPurple, skyBlue]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text("TOTAL À RÉGLER", style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Text("${widget.amount} DT", style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Bouton Stripe
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));

  // Récupère le token (depuis ton AuthService ou SharedPreferences)
  final token = await AuthService.getToken(); 

  if (token != null) {
    Navigator.pop(context); // Ferme le loader
    await PaymentService.initAndPresentPaymentSheet(widget.projectId, token, context);
  }// Ici tu appelles ta fonction Stripe de ton backend Node.js
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Payer avec Stripe", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    const Icon(Icons.payment, color: Colors.amber, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text("Paiement crypté SSL et sécurisé", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text("$label : ", style: GoogleFonts.inter(color: Colors.grey[600])),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}