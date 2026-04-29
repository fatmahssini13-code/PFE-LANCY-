import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe/service/proposal_service.dart';
import 'package:pfe/service/auth_service.dart';

class ProposalsListScreen extends StatefulWidget {
  final String projectId;

  const ProposalsListScreen({super.key, required this.projectId});

  @override
  State<ProposalsListScreen> createState() => _ProposalsListScreenState();
}

class _ProposalsListScreenState extends State<ProposalsListScreen> {
  final ProposalService service = ProposalService();
  List proposals = [];
  bool loading = true;

  // Couleurs Lancy
  final Color lancyBlue = const Color(0xFF00AEEF);
  final Color lancyPurple = const Color(0xFF8E2DE2);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    final data = await service.getProposals(token, widget.projectId);
    setState(() {
      proposals = data;
      loading = false;
    });
  }

  // --- ACTIONS ---
  Future<void> handleAction(String id, bool isAccept) async {
    final token = await AuthService.getToken();
    if (isAccept) {
      final confirm = await _showConfirmDialog();
      if (confirm != true) return;
      await service.acceptProposal(token!, id);
Navigator.pop(context, true);
    } else {
      await service.rejectProposal(token!, id);
    }
    load();
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Confirmer", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text("Voulez-vous confier cette mission à ce freelance ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: StadiumBorder()),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Accepter", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Propositions reçues", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: lancyPurple))
          : proposals.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: proposals.length,
                  itemBuilder: (context, index) => _buildProposalCard(proposals[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Aucune proposition pour le moment", style: GoogleFonts.inter(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProposalCard(dynamic p) {
    String status = p["status"] ?? "pending";
    String freelancerName = p["freelancer"]["name"] ?? "Freelance";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Nom + Badge Statut
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: lancyBlue.withOpacity(0.1),
                  child: Text(freelancerName[0].toUpperCase(), style: TextStyle(color: lancyBlue, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(freelancerName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Freelance vérifié", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const Divider(height: 30),
            
            // Lettre de motivation
            Text(
              "Lettre de motivation",
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            const SizedBox(height: 4),
            Text(
              p["coverLetter"] ?? "",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 20),

            // Détails Prix / Délai
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailTile(Icons.payments_outlined, "${p["price"]} DT", "Budget proposé"),
                _buildDetailTile(Icons.timer_outlined, "${p["deliveryTime"]} jours", "Délai"),
              ],
            ),
            
            // Actions si "pending"
            if (status == "pending") ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => handleAction(p["_id"], false),
                      child: const Text("Refuser", style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF81E38F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => handleAction(p["_id"], true),
                      child: const Text("Accepter", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case "accepted": color = Colors.green; label = "Acceptée"; break;
      case "rejected": color = Colors.red; label = "Refusée"; break;
      default: color = Colors.orange; label = "En attente";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailTile(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: lancyPurple),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}