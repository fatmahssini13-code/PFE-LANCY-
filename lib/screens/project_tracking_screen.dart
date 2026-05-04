import 'package:flutter/material.dart';
import 'package:pfe/service/project_service.dart';


class ProjectTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  final String userRole; // 'client' ou 'freelancer'

  ProjectTrackingScreen({required this.project, required this.userRole});

  @override
  _ProjectTrackingScreenState createState() => _ProjectTrackingScreenState();
}

class _ProjectTrackingScreenState extends State<ProjectTrackingScreen> {
  final ProjectService _projectService = ProjectService();
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    String status = widget.project['status'] ?? 'open';

    return Scaffold(
      appBar: AppBar(title: Text("Suivi du Projet")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Titre et Budget
            _buildHeader(status),
            Divider(height: 40),

            // Section Dynamique selon le rôle et le statut
            if (widget.userRole == 'freelancer' && status == 'in_progress')
              _buildFreelancerDeliveryForm(),
            
            if (widget.userRole == 'client' && status == 'delivered')
              _buildClientApprovalSection(),

            if (status == 'completed')
              _buildSuccessState(),

            // Infos complémentaires (Optionnel)
            SizedBox(height: 30),
            _buildProjectDetails(),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE COMPOSANTS ---

  Widget _buildHeader(String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.project['title'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Row(
          children: [
            Chip(
              label: Text(status.toUpperCase()),
              backgroundColor: _getStatusColor(status).withOpacity(0.2),
              labelStyle: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text("${widget.project['budget']} DT", style: TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildFreelancerDeliveryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Livrer votre travail", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 15),
        TextField(
          controller: _linkController,
          decoration: InputDecoration(
            labelText: "Lien (Google Drive, Figma, ZIP)",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
          onPressed: _isLoading ? null : _handleDelivery,
          child: _isLoading ? CircularProgressIndicator() : Text("ENVOYER LA LIVRAISON"),
        ),
      ],
    );
  }

  Widget _buildClientApprovalSection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              Text("Le freelancer a livré le projet !", style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () {}, // Ajouter ouverture de lien
                icon: Icon(Icons.open_in_new),
                label: Text(widget.project['delivery']['link'] ?? "Voir le travail"),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: Size(double.infinity, 50)),
          onPressed: _isLoading ? null : _handleApproval,
          child: _isLoading ? CircularProgressIndicator() : Text("APPROUVER ET PAYER", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 100, color: Colors.green),
          SizedBox(height: 10),
          Text("Projet Terminé", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
          Text("Le paiement a été libéré."),
        ],
      ),
    );
  }

  Widget _buildProjectDetails() {
    return Card(
      child: ListTile(
        title: Text("Description"),
        subtitle: Text(widget.project['description'] ?? "Aucune description"),
      ),
    );
  }

  // --- LOGIQUE DES ACTIONS ---

  void _handleDelivery() async {
    if (_linkController.text.isEmpty) return;
    setState(() => _isLoading = true);
    bool ok = await _projectService.deliverProject(widget.project['_id'], _linkController.text, "Travail terminé");
    setState(() => _isLoading = false);
    if (ok) Navigator.pop(context, true);
  }

  void _handleApproval() async {
    setState(() => _isLoading = true);
    bool ok = await _projectService.releasePayment(widget.project['_id']);
    setState(() => _isLoading = false);
    if (ok) Navigator.pop(context, true);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress': return Colors.orange;
      case 'delivered': return Colors.blue;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }
}