import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe/config/api_config.dart';
import 'package:pfe/screens/payment_screen.dart';
import 'package:pfe/screens/profilescreen.dart';
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

  final Color lancyBlue = const Color(0xFF00AEEF);
  final Color lancyPurple = const Color(0xFF8E2DE2);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => loading = false);
      return;
    }
    try {
      final data = await service.getProposals(token, widget.projectId);
      if (!mounted) return;
      setState(() {
        proposals = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  String _proposalId(dynamic p) => p['_id']?.toString() ?? '';

  String _freelancerName(dynamic p) {
    final f = p['freelancer'];
    if (f is Map) return f['name']?.toString() ?? 'Freelance';
    return 'Freelance';
  }

  Future<void> handleAction(String id, bool isAccept) async {
    if (id.isEmpty) return;

    final token = await AuthService.getToken();
    if (token == null) return;

    if (isAccept) {
      final confirm = await _showConfirmDialog();
      if (confirm != true) return;
    }

    final (bool ok, String message) = isAccept
        ? await service.acceptProposal(token, id)
        : await service.rejectProposal(token, id);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      load(); // On rafraîchit la liste pour voir le bouton "Payer"
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
      );
    }
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: const StadiumBorder()),
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
    final String freelancerName = _freelancerName(p);
    final String pid = _proposalId(p);
    final String initial = freelancerName.isNotEmpty ? freelancerName[0].toUpperCase() : '?';
final freelancer = p['freelancer'] is Map ? p['freelancer'] : {};
    final String? avatarUrl = freelancer['avatar'];
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
            Row(
              children: [
      GestureDetector(
onTap: () {
  print("Navigation vers le profil de: $freelancerName");
  // Utilise Get.to directement sans Navigator.push
  Get.to(() => ProfileScreen(email: freelancer['email'])); 
},
  child: CircleAvatar(
  radius: 22,
  backgroundColor: Colors.blue.shade100, // Fond par défaut (ce qu'on voit sur ta capture)
  backgroundImage: (freelancer['profilePicture'] != null && freelancer['profilePicture'].isNotEmpty)
      ? NetworkImage(freelancer['profilePicture']) // Charge l'image si l'URL existe
      : null, // Sinon, rien en background
  child: (freelancer['profilePicture'] == null || freelancer['profilePicture'].isEmpty)
      ? Text(
          freelancer['name'][0].toUpperCase(), // Affiche l'initiale "E" si pas de photo
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        )
      : null,
)
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
            Text(
              "Lettre de motivation",
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            const SizedBox(height: 4),
            Text(
              p["coverLetter"] ?? "Aucun détail fourni.",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailTile(Icons.payments_outlined, "${p["price"] ?? 0} DT", "Budget proposé"),
                _buildDetailTile(Icons.timer_outlined, "${p["deliveryTime"] ?? 0} jours", "Délai"),
              ],
            ),

            // --- SECTION ACTIONS CORRIGÉE ---
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
                      onPressed: () => handleAction(pid, false),
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
                      onPressed: () => handleAction(pid, true),
                      child: const Text("Accepter", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ] else if (status == "accepted") ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(
                          projectId: widget.projectId,
                          amount: p["price"], projectTitle: '', client: null, freelancer: null,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                  label: const Text("Procéder au paiement séquestre", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
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