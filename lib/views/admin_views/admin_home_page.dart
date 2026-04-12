import 'package:delivery_app/firestore/models/m_user.dart';
import 'package:delivery_app/firestore/user_db.dart';
import 'package:delivery_app/reusable_widgets/rw_appbar.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/views/admin_views/dashboard_admin_page.dart';
import 'package:delivery_app/views/admin_views/users_view_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Database Logic
  final UserDB _userRepo = UserDB();
  List<UserModel>? _cachedUsers;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isReloading = true);
    try {
      final users = await _userRepo.getAllUsers();
      setState(() {
        _cachedUsers = users;
        _isReloading = false;
      });
    } catch (e) {
      setState(() => _isReloading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de chargement: $e")));
      }
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin_logged_in', false);
    if (mounted) Navigator.pushReplacementNamed(context, '/loginAdmin');
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 900;

    // ÉTAPE 1 : Vérifiez que l'index correspond bien aux pages définies ici
    final List<Widget> pages = [
      const DashboardAdminPage(),
      // Index 0
      UsersViewPage(
        // Index 1
        users: _cachedUsers,
        onManualRefresh: _fetchUsers,
        isRefreshing: _isReloading,
      ),
      const Center(child: Text("Paramètres")),
      // Index 2 (AJOUTÉ pour correspondre à la Sidebar)
    ];

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Sécurité : évite de dépasser l'index si on revient au dashboard
        if (_selectedIndex != 0) setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: DefaultColors.background,
        drawer: isWeb ? null : _buildSidebar(),
        body: Row(
          children: [
            if (isWeb && _isSidebarOpen) _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  RwAppbar(
                    username: "Admin",
                    primaryColor: DefaultColors.primary,
                    onMenuPressed: () {
                      if (isWeb) {
                        setState(() => _isSidebarOpen = !_isSidebarOpen);
                      } else {
                        _scaffoldKey.currentState?.openDrawer();
                      }
                    },
                  ),
                  Expanded(
                    child: IndexedStack(
                      // ÉTAPE 2 : On s'assure que l'index est toujours valide avant de l'afficher
                      index: _selectedIndex < pages.length ? _selectedIndex : 0,
                      children: pages,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper pour éviter la répétition du widget Sidebar
  Widget _buildSidebar() {
    return RwSideBar(
      portalTitle: "ADMIN PORTAL",
      selectedIndex: _selectedIndex,
      primaryColor: Colors.white,
      backgroundColor: DefaultColors.primary,
      unselectedColor: Colors.white70,
      onItemSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      onLogout: _handleLogout,
    );
  }
}
