import 'package:delivery_app/firestore/models/m_user.dart';
import 'package:delivery_app/firestore/user_db.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:delivery_app/views/admin_views/add_user_page.dart';
import 'package:delivery_app/views/admin_views/edit_password_page.dart';
import 'package:flutter/material.dart';

class UsersViewPage extends StatefulWidget {
  const UsersViewPage({super.key});

  @override
  State<UsersViewPage> createState() => _UsersViewPageState();
}

class _UsersViewPageState extends State<UsersViewPage> {
  final UserDB _userRepo = UserDB();

  // Cache System statique pour préserver les données entre les onglets
  static final Map<String, _UserCache> _globalCache = {};

  List<UserModel>? _users;
  bool _isLoading = false;

  // 1. Variable pour suivre l'initialisation
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 2. Écouter les rafraîchissements globaux (ex: après ajout user ou scan)
    RefreshNotifier().refreshCounter.addListener(_resetAndReload);
  }

  @override
  void dispose() {
    // 3. Nettoyage de l'écouteur
    RefreshNotifier().refreshCounter.removeListener(_resetAndReload);
    super.dispose();
  }

  // 4. MÉTHODE DE RÉFÉRENCE : Appellée par le parent quand l'onglet devient visible
  void initDataIfNeeded() {
    if (!_isInitialized) {
      _fetchUsers();
      _isInitialized = true;
    }
  }

  // --- Logique de Gestion des Données ---

  void _resetAndReload() {
    if (!mounted) return;
    _globalCache.clear(); // On vide le cache car une donnée a changé en DB
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    const cacheKey = "all_users_list";

    // Vérifier si on a un cache valide (moins de 5 minutes)
    if (_globalCache.containsKey(cacheKey) &&
        !_globalCache[cacheKey]!.isExpired) {
      if (mounted) {
        setState(() {
          _users = _globalCache[cacheKey]!.users;
          _isLoading = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _userRepo.getAllUsers();

      // Mettre en cache
      _globalCache[cacheKey] = _UserCache(
        users: data,
        cachedAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _users = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar("Erreur lors du chargement: $e");
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DefaultColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    // 5. Sécurité : Initialisation si build est appelé directement
    if (!_isInitialized) {
      initDataIfNeeded();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DefaultColors.primary,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddUserPage()),
          );
          // Le RefreshNotifier dans AddUserPage déclenchera la mise à jour ici
        },
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text(
          "NOUVEAU expéditeur",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading && (_users == null || _users!.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : _users == null || _users!.isEmpty
                ? _buildEmptyState()
                : _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(10),
      child: Text(
        "Gestion des Utilisateurs",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 100),
        Center(child: Text(
            "Aucun utilisateur trouvé", style: TextStyle(color: Colors.grey))),
      ],
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
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            onTap: () => _showUserDetails(context, user),
            leading: CircleAvatar(
              backgroundColor: DefaultColors.primary.withOpacity(0.1),
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
              onPressed: () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditPasswordPage(
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
        title: const Row(
          children: [
            Icon(Icons.badge_outlined, color: DefaultColors.primary),
            SizedBox(width: 10),
            Text("Profil"),
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

class _UserCache {
  final List<UserModel> users;
  final DateTime cachedAt;

  _UserCache({required this.users, required this.cachedAt});

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > const Duration(minutes: 5);
}