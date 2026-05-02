import 'package:delivery_app/dialogs/rd_print_save_package.dart';
import 'package:delivery_app/firestore/enums/e_governorate.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PackageDetailsPage extends StatelessWidget {
  final PackageModel package;
  const PackageDetailsPage({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.pagesBackground,
      appBar: AppBar(
        title: const Text("Détails du Colis"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: ElevatedButton.icon(
          onPressed: () => RdPrintSavePackage.show(context, package),
          icon: const Icon(Icons.print),
          label: const Text("IMPRIMER L'ÉTIQUETTE", style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: DefaultColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSection(
                title: "Destinataire",
                children: [
                  _infoRow(Icons.person, "Nom Complet", "${package.firstName} ${package.lastName}"),
                  _infoRow(Icons.phone, "Contacts", "${package.phone1}${package.phone2 != null ? ' / ${package.phone2}' : ''}"),
                  _infoRow(Icons.location_city, "Gouvernorat", package.governorate.label),
                  _infoRow(Icons.map, "Adresse", package.address),
                ],
              ),
              const SizedBox(height: 20),
              _buildSection(
                title: "Détails du Colis",
                children: [
                  _infoRow(Icons.payments_outlined, "Montant à collecter", "${package.amount} TND", isHighlight: true),
                  _infoRow(Icons.swap_horiz, "Type", package.isExchange ? "Échange" : "Normal"),
                  _infoRow(Icons.inventory_2_outlined, "Désignation", package.packageDesignation ?? "Non spécifié"),
                  _infoRow(Icons.description_outlined, "Commentaire", package.comment ?? "Aucun"),
                ],
              ),
              const SizedBox(height: 20),
              _buildSection(
                title: "Historique",
                children: [
                  _infoRow(Icons.calendar_month, "Date de création", DateFormat('dd/MM/yyyy HH:mm').format(package.createdAt)),
                  _infoRow(Icons.admin_panel_settings_outlined, "Créé par", package.creatorUsername),
                  _infoRow(Icons.assignment_ind_outlined, "Matricule Fiscale", package.creatorTaxId), // Added Tax ID
                  _infoRow(Icons.info_outline, "Status actuel", package.status.label),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DefaultColors.primary, width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: DefaultColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                    color: isHighlight ? DefaultColors.primary : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}