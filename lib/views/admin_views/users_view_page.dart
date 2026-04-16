import 'package:delivery_app/firestore/models/m_user.dart';
import 'package:delivery_app/firestore/user_db.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:delivery_app/views/admin_views/edit_password_page.dart';
import 'package:flutter/material.dart';

class UsersViewPage extends StatefulWidget {
  const UsersViewPage({super.key});

  @override
  State<UsersViewPage> createState() => _UsersViewPageState();
}

class _UsersViewPageState extends State<UsersViewPage> {
  final UserDB _userRepo = UserDB();
  List<UserModel>? _users;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    // Listening to the RefreshNotifier singleton
    RefreshNotifier().refreshCounter.addListener(_fetchUsers);
  }

  @override
  void dispose() {
    // Crucial: remove listener to prevent memory leaks
    RefreshNotifier().refreshCounter.removeListener(_fetchUsers);
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _userRepo.getAllUsers();
      if (mounted) {
        setState(() {
          _users = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $e"),
            backgroundColor: DefaultColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Let AdminHomePage handle the background
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DefaultColors.primary,
        onPressed: () => Navigator.pushNamed(context, '/addUser'),
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text(
          "NOUVEAU COMPTE",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading && _users == null
                ? const Center(child: CircularProgressIndicator())
                : _users == null || _users!.isEmpty
                ? const Center(child: Text("Aucun utilisateur trouvé"))
                : _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Gestion des Utilisateurs",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.separated(
      padding: const EdgeInsets.only(left: 30, right: 30, bottom: 100),
      itemCount: _users!.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _users![index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            onTap: () => _showUserDetails(context, user),
            leading: CircleAvatar(
              backgroundColor: DefaultColors.primary.withValues(alpha: 0.1),
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : "?",
                style: const TextStyle(
                  color: DefaultColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              "${user.firstName} ${user.lastName}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text("@${user.username} • ${user.phone1}"),
            trailing: IconButton(
              tooltip: "Réinitialiser mot de passe",
              icon: const Icon(Icons.lock_reset, color: Colors.grey),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditPasswordPage(
                    userId: user.id,
                    userName: user.username,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showUserDetails(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.badge_outlined, color: DefaultColors.primary),
            const SizedBox(width: 10),
            const Text("Profil"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Identifiant:", "@${user.username}"),
            _detailRow("Nom complet:", "${user.firstName} ${user.lastName}"),
            _detailRow("Téléphone 1:", user.phone1),
            if (user.phone2.isNotEmpty) _detailRow("Téléphone 2:", user.phone2),
            _detailRow("Frais Livraison:", "${user.deliveryCosts} TND"),
            _detailRow("Rôle:", user.role.toUpperCase()),
            const Divider(height: 30),
            Text(
              "Créé le: ${user.createdAt.toString().split(' ')[0]}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("FERMER", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label ",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    ),
  );
}
