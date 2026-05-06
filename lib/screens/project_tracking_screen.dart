import 'dart:io';
import 'package:file_picker/file_picker.dart' as picker; // Importation correcte
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:pfe/config/api_config.dart';
import 'package:pfe/service/project_service.dart';
import 'package:pfe/service/auth_service.dart';
import 'package:pfe/service/payment_service.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ProjectTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  final String userRole;

  const ProjectTrackingScreen({
    super.key,
    required this.project,
    required this.userRole,
  });

  @override
  State<ProjectTrackingScreen> createState() => _ProjectTrackingScreenState();
}

class _ProjectTrackingScreenState extends State<ProjectTrackingScreen> {
  final ProjectService _projectService = ProjectService();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  File? selectedFile;

  final Color lancyPurple = const Color(0xFF8E2DE2);
  final Color skyBlue = const Color(0xFF74C0FC);
  Future<void> _pickFile() async {
  // 2. Utilisez l'alias 'picker'
  picker.FilePickerResult? result = await picker.FilePicker.platform.pickFiles(
    type: picker.FileType.any, 
  );

  if (result != null && result.files.single.path != null) {
    setState(() {
      selectedFile = File(result.files.single.path!);
    });
  }
}
  @override
  void dispose() {
    _linkController.dispose();
    _messageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    String status = widget.project['status'] ?? 'open';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Suivi du Projet",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(status),
            const SizedBox(height: 20),
            _buildProgressBar(status),
            const SizedBox(height: 24),

            // ✅ Freelancer — formulaire livraison
            if (widget.userRole == 'freelancer' && status == 'in_progress')
              _buildFreelancerDeliveryForm(),

            // ✅ Freelancer — en attente de validation
            if (widget.userRole == 'freelancer' && status == 'delivered')
              _buildWaitingValidation(),

            // ✅ Client — section approbation
            if (widget.userRole == 'client' && status == 'delivered')
              _buildClientApprovalSection(),

            // ✅ Terminé
            if (status == 'completed')
              _buildSuccessState(),

            const SizedBox(height: 24),
            _buildProjectDetails(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // =====================
  // HEADER
  // =====================
  Widget _buildHeader(String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.project['title'] ?? "Sans titre",
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "${widget.project['budget']} DT",
                style: const TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================
  // PROGRESS BAR
  // =====================
  Widget _buildProgressBar(String status) {
    int step = 0;
    if (status == "in_progress") step = 1;
    if (status == "delivered") step = 2;
    if (status == "completed") step = 3;

    final steps = ["Démarré", "En cours", "Livré", "Payé"];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                return Expanded(
                  child: Container(
                    height: 3,
                    color: i ~/ 2 < step
                        ? Colors.green
                        : Colors.grey.shade200,
                  ),
                );
              }
              final idx = i ~/ 2;
              final isActive = idx <= step;
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: isActive ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[idx],
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? Colors.green : Colors.grey,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // =====================
  // FREELANCER — LIVRAISON
  // =====================
  Widget _buildFreelancerDeliveryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bloc escrow
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.lock, color: Colors.green.shade600, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Paiement sécurisé en escrow — libéré après validation client",
                  style: GoogleFonts.inter(
                      color: Colors.green.shade700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text("Livrer votre travail",
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),

        // Lien
        TextField(
          controller: _linkController,
          decoration: InputDecoration(
            labelText: "Lien (Drive, GitHub, Figma...)",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 12),

        // Message
        TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: "Message au client (optionnel)",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.message_outlined),
          ),
        ),
        const SizedBox(height: 12),

        // Fichier
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.attach_file),
          label: Text(selectedFile != null
              ? "📎 ${selectedFile!.path.split('/').last}"
              : "Choisir un fichier"),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        // Bouton livrer
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: lancyPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _handleDelivery,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.upload, color: Colors.white),
            label: Text(
              _isLoading ? "Envoi en cours..." : "Marquer comme livré",
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // =====================
  // FREELANCER — EN ATTENTE
  // =====================
  Widget _buildWaitingValidation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_top, color: Colors.blue.shade600, size: 48),
          const SizedBox(height: 12),
          Text(
            "En attente de validation",
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            "Le client est en train de vérifier votre travail. Le paiement sera libéré après validation.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: Colors.blue.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // =====================
  // CLIENT — APPROBATION
  // =====================
  Widget _buildClientApprovalSection() {
    final delivery = widget.project['delivery'];
    final file = delivery?['file'];
    final link = delivery?['link'];
    final message = delivery?['message'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Travail livré 📦",
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 10)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message != null && message.isNotEmpty) ...[
                Text("Message du freelancer :",
                    style: GoogleFonts.inter(
                        color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(message,
                    style: GoogleFonts.inter(fontSize: 14)),
                const SizedBox(height: 12),
              ],
              if (link != null && link.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(link);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: const Icon(Icons.link),
                  label: const Text("Ouvrir le lien"),
                ),
              if (file != null && file.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    final url =
                        Uri.parse("${ApiConfig.origin}/uploads/$file");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  icon: const Icon(Icons.insert_drive_file),
                  label: const Text("Télécharger le fichier"),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ✅ Bouton approuver
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _handleApproval,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle, color: Colors.white),
            label: Text(
              _isLoading ? "Traitement..." : "Valider et libérer le paiement",
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ✅ Bouton litige
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _showDisputeDialog(),
            icon: const Icon(Icons.warning_amber),
            label: Text("Ouvrir un litige",
                style: GoogleFonts.poppins()),
          ),
        ),
      ],
    );
  }

  // =====================
  // SUCCÈS
  // =====================
  Widget _buildSuccessState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 12),
          Text("Projet Terminé ! 🎉",
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
          const SizedBox(height: 6),
          Text(
            widget.userRole == 'client'
                ? "Le paiement a été libéré au freelancer."
                : "Vous avez reçu le paiement sur votre wallet !",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }

  // =====================
  // DÉTAILS PROJET
  // =====================
  Widget _buildProjectDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Description",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            widget.project['description'] ?? "Aucune description",
            style: GoogleFonts.inter(
                color: Colors.grey.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }

  // =====================
  // ACTIONS
  // =====================
  Future<void> _handleDelivery() async {
    if (_linkController.text.isEmpty && selectedFile == null) {
      Get.snackbar("Erreur", "Ajoute un lien ou un fichier",
          backgroundColor: Colors.red.shade100);
      return;
    }

    setState(() => _isLoading = true);

    final bool ok = await _projectService.deliverProject(
      widget.project['_id'],
      _linkController.text,
      _messageController.text,
    );

    setState(() => _isLoading = false);

    if (ok) {
      Get.snackbar(
        "Livraison envoyée ! 📦",
        "Le client va vérifier votre travail",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Navigator.pop(context, true);
    } else {
      Get.snackbar("Erreur", "Impossible d'envoyer la livraison",
          backgroundColor: Colors.red.shade100);
    }
  }

  Future<void> _handleApproval() async {
    setState(() => _isLoading = true);

    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse(
            '${ApiConfig.baseURL}/projects/${widget.project["_id"]}/approve'),
        headers: {'Authorization': 'Bearer $token'},
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        Get.snackbar(
          "Paiement libéré ! 💸",
          "Le freelancer a été payé avec succès",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Navigator.pop(context, true);
      } else {
        Get.snackbar("Erreur", "Impossible de valider",
            backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar("Erreur", e.toString());
    }
  }

  void _showDisputeDialog() {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text("Ouvrir un litige",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Expliquez le problème :",
                style: GoogleFonts.inter(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Décrivez le problème...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final token = await AuthService.getToken();
              await http.put(
                Uri.parse(
                    '${ApiConfig.baseURL}/escrow/dispute/${widget.project["_id"]}'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: '{"reason": "${reasonCtrl.text}"}',
              );
              Navigator.pop(context);
              Get.snackbar(
                "Litige ouvert",
                "L'administrateur va intervenir",
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            },
            child: const Text("Confirmer",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  // =====================
  // HELPERS
  // =====================
  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress': return Colors.orange;
      case 'delivered': return Colors.blue;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'open': return 'Ouvert';
      case 'in_progress': return 'En cours';
      case 'delivered': return 'Livré';
      case 'completed': return 'Terminé';
      default: return status;
    }
  }
}