import 'package:delivery_app/firestore/models/m_user.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/views/admin_views/edit_password_page.dart';
import 'package:flutter/material.dart';

class UsersViewPage extends StatelessWidget {
  final List<UserModel>? users;
  final Future<void> Function() onManualRefresh;
  final bool isRefreshing;

  const UsersViewPage({
    super.key,
    required this.users,
    required this.onManualRefresh,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DefaultColors.primary,
        onPressed: () async {
          // Si la page d'ajout retourne 'true', on rafraîchit la liste
          final result = await Navigator.pushNamed(context, '/addUser');
          if (result == true) {
            onManualRefresh();
          }
        },
        // Utilisation de label + icon pour un rendu propre
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Ajouter utilisateur",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: const Text(
                    "Gestion des Utilisateurs",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                // Manual Refresh Group
                Container(
                  padding: const EdgeInsets.only(left: 15),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: GestureDetector(
                    onTap: isRefreshing ? null : onManualRefresh,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Charger ",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          isRefreshing
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: DefaultColors.primary,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  onPressed:
                                      null, // Tap handled by GestureDetector
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: DefaultColors.primary,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: users == null
                ? const Center(child: CircularProgressIndicator())
                : users!.isEmpty
                ? const Center(child: Text("Aucun utilisateur disponible"))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    itemCount: users!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = users![index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          onTap: () => _showUserDetails(context, user),
                          leading: CircleAvatar(
                            backgroundColor: DefaultColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : "?",
                              style: TextStyle(color: DefaultColors.primary),
                            ),
                          ),
                          title: Text(user.username),
                          subtitle: Text(user.phone1),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.lock_reset,
                              color: Colors.grey,
                            ),
                            onPressed: () async {
                              final edited = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditPasswordPage(
                                    userId: user.id,
                                    userName: user.username,
                                  ),
                                ),
                              );
                              if (edited == true) onManualRefresh();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.person, color: DefaultColors.primary),
            const SizedBox(width: 10),
            const Text("Détails"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Identifiant:", user.username),
            _detailRow("Téléphone 1:", user.phone1),
            _detailRow(
              "Téléphone 2:",
              user.phone2.isEmpty ? "N/A" : user.phone2,
            ),
            _detailRow("Rôle:", user.role.toUpperCase()),
            const SizedBox(height: 10),
            Text(
              "Créé le: ${user.createdAt?.toString().split(' ')[0] ?? 'N/A'}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("FERMER"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        children: [
          TextSpan(
            text: "$label ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}
