import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pfe/service/user_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final UserService _userService = UserService();

  final Color skyBlue     = const Color(0xFF74C0FC);
  final Color mintCrystal = const Color(0xFF81E38F);
  final Color darkText    = const Color(0xFF1A1C1E);

  late Future<Map<String, dynamic>> _walletFuture;

  @override
  void initState() {
    super.initState();
    _walletFuture = _userService.getWallet();
  }

  void _reload() {
    setState(() => _walletFuture = _userService.getWallet());
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy', 'fr_FR').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _walletFuture,
        builder: (context, snap) {
          final isLoading = snap.connectionState == ConnectionState.waiting;
          final balance   = snap.data?['balance'] ?? 0;
          final transactions =
              snap.data?['transactions'] as List? ?? [];

          return RefreshIndicator(
            color: skyBlue,
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── App Bar ──────────────────────────────
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: skyBlue,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [skyBlue, mintCrystal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              20, 56, 20, 20),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisAlignment:
                                MainAxisAlignment.end,
                            children: [
                              Text("Solde disponible",
                                  style: GoogleFonts.inter(
                                      color: Colors.white
                                          .withOpacity(0.85),
                                      fontSize: 14)),
                              const SizedBox(height: 8),
                              isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child:
                                          CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2))
                                  : Text(
                                      "$balance DT",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 42,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.5,
                                      ),
                                    ),
                              const SizedBox(height: 10),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(99),
                                ),
                                child: Text(
                                  "${transactions.length} mission${transactions.length != 1 ? 's' : ''} complétée${transactions.length != 1 ? 's' : ''}",
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    title: Text("Mon Wallet",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Colors.white)),
                    titlePadding: const EdgeInsets.only(
                        left: 56, bottom: 14),
                  ),
                ),

                // ── Stats ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        16, 20, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.check_circle_outline_rounded,
                            label: "Missions",
                            value: "${transactions.length}",
                            color: skyBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            icon: Icons.payments_outlined,
                            label: "Total gagné",
                            value: "$balance DT",
                            color: mintCrystal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Transactions ─────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 20, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text("Historique des paiements",
                          style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: darkText)),
                      const SizedBox(height: 12),

                      if (isLoading)
                        const Center(
                            child: CircularProgressIndicator())
                      else if (transactions.isEmpty)
                        _buildEmpty()
                      else
                        ...transactions
                            .map((t) => _buildTxCard(t))
                            .toList(),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Stat card ─────────────────────────────────────────
  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ── Transaction card ──────────────────────────────────
  Widget _buildTxCard(dynamic t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: mintCrystal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check_circle_outline_rounded,
                color: Colors.green.shade600, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['title'] ?? 'Projet',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: darkText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  _formatDate(t['createdAt']),
                  style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "+${t['budget']} DT",
            style: GoogleFonts.poppins(
              color: Colors.green.shade600,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────
  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text("Aucune transaction",
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          Text(
            "Complète des missions pour voir tes paiements ici.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}