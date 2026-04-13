import 'package:delivery_app/dialogs/rd_print_save_package.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/views/user_views/package_details_page.dart';
import 'package:flutter/material.dart';

class PackageItemCard extends StatelessWidget {
  final PackageModel package;
  const PackageItemCard({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text("${package.firstName} ${package.lastName}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    _buildStatusBadge(package.status),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on_outlined, package.governorate.name, trailing: "${package.amount} TND"),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone_outlined, "${package.phone1}${package.phone2 != null ? ' / ${package.phone2}' : ''}"),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {String? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.black87)),
        if (trailing != null) ...[
          const Spacer(),
          Text(trailing, style: TextStyle(fontWeight: FontWeight.w900, color: DefaultColors.primary)),
        ]
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: () => RdPrintSavePackage.show(context, package),
            icon: const Icon(Icons.print_outlined),
            label: const Text("Imprimer"),
          ),
          const VerticalDivider(width: 1),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PackageDetailsPage(package: package)),
            ),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text("Détails"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(EPackageStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: DefaultColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DefaultColors.primary),
      ),
    );
  }
}