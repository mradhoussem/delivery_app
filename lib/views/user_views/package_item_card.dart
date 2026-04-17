import 'package:delivery_app/dialogs/rd_print_save_package.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:delivery_app/views/user_views/package_details_page.dart';
import 'package:delivery_app/views/user_views/update_package_page.dart';
import 'package:flutter/material.dart';

class PackageItemCard extends StatelessWidget {
  final PackageModel package;
  final bool showSender;
  final bool showReturnReceivedButton;
  final bool isAdmin;

  const PackageItemCard({
    super.key,
    required this.package,
    this.showSender = false,
    this.showReturnReceivedButton = false,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildInfo()),
                  _buildStatusBadge(package.status),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, thickness: 0.5),
              ),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runAlignment: WrapAlignment.end,
                  spacing: 20,
                  runSpacing: 12,
                  children: [
                    Text(
                      "${package.amount} TND",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: DefaultColors.primary,
                      ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 4,
                      children: [
                        // --- LOGIQUE ADMIN : Retour Dépôt -> Retour Définitif ---
                        if (isAdmin && package.status == EPackageStatus.returnFromDeposit)
                          OutlinedButton.icon(
                            onPressed: () => _confirmAdminPermanentReturn(context),
                            icon: const Icon(Icons.keyboard_double_arrow_right_rounded, size: 20),
                            label: const Text(
                              "RETOUR DÉFINITIF",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade800,
                              backgroundColor: Colors.orange.shade50,
                              side: BorderSide(color: Colors.orange.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),

                        // --- LOGIQUE USER : Retour Définitif -> Retour Reçu ---
                        if (!isAdmin && showReturnReceivedButton && package.status == EPackageStatus.permanentReturn)
                          OutlinedButton.icon(
                            onPressed: () => _confirmUserReturnReceived(context),
                            icon: const Icon(Icons.assignment_turned_in_outlined, size: 20),
                            label: const Text(
                              "RETOUR REÇU",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade700,
                              backgroundColor: Colors.green.shade50,
                              side: BorderSide(color: Colors.green.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),

                        if (package.status == EPackageStatus.waiting) ...[
                          _buildActionButton(
                            icon: Icons.delete_outline,
                            color: DefaultColors.error,
                            tooltip: "Supprimer",
                            onPressed: () => _confirmDelete(context),
                          ),
                          _buildActionButton(
                            icon: Icons.edit_outlined,
                            color: Colors.blue,
                            tooltip: "Editer",
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UpdatePackagePage(package: package),
                              ),
                            ),
                          ),
                        ],
                        _buildActionButton(
                          icon: Icons.print_outlined,
                          color: Colors.black87,
                          tooltip: "Imprimer",
                          onPressed: () => RdPrintSavePackage.show(context, package),
                        ),
                        _buildActionButton(
                          icon: Icons.visibility_outlined,
                          color: Colors.black87,
                          tooltip: "Détails",
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PackageDetailsPage(package: package),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action réservée à l'ADMIN
  Future<void> _confirmAdminPermanentReturn(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Action Admin"),
        content: const Text("Confirmez-vous le passage en 'Retour Définitif' pour ce colis ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ANNULER")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("CONFIRMER", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await PackageDB().updateStatus(package.id, EPackageStatus.permanentReturn);
      RefreshNotifier().notifyRefresh();
    }
  }

  // Action réservée à l'UTILISATEUR
  Future<void> _confirmUserReturnReceived(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation de réception"),
        content: const Text("Avez-vous bien reçu le retour de ce colis ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("NON")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("OUI, REÇU", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await PackageDB().updateStatus(package.id, EPackageStatus.returnReceived);
      RefreshNotifier().notifyRefresh();
    }
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSender) ...[
          Row(
            children: [
              const Icon(Icons.storefront, size: 14, color: DefaultColors.primary),
              const SizedBox(width: 4),
              Text(
                "Expéditeur: ${package.creatorUsername}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: DefaultColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Text(
          "${package.firstName} ${package.lastName}",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _infoRow(Icons.location_on_outlined, package.governorate.name),
        const SizedBox(height: 4),
        _infoRow(Icons.phone_outlined, "${package.phone1}${package.phone2 != null ? ' / ${package.phone2}' : ''}"),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DefaultColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: DefaultColors.textSecondary), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required String tooltip, required VoidCallback onPressed}) {
    return IconButton(onPressed: onPressed, tooltip: tooltip, visualDensity: VisualDensity.compact, icon: Icon(icon, color: color, size: 26));
  }

  Widget _buildStatusBadge(EPackageStatus status) {
    final Color baseColor = status.gradientColors.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Text(status.label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: baseColor)),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer l'expédition"),
        content: const Text("Voulez-vous vraiment supprimer ce colis ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ANNULER")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("SUPPRIMER", style: TextStyle(color: DefaultColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      await PackageDB().deletePackage(package.id);
      RefreshNotifier().notifyRefresh();
    }
  }
}