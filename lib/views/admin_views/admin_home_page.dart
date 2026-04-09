import 'package:delivery_app/firestore/models/m_user.dart';
import 'package:delivery_app/firestore/user_db.dart';
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
    _fetchUsers(); // Initial fetch on startup
  }

  /// Centralized fetch method to update the cache
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de chargement: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 900;

    // Define pages and inject dependencies
    final List<Widget> pages = [
      const DashboardAdminPage(),
      UsersViewPage(
        users: _cachedUsers,
        onManualRefresh: _fetchUsers,
        isRefreshing: _isReloading,
      ),
    ];

    return PopScope(
      // Allow the app to close/pop only if we are on the first tab (Dashboard)
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If user is on Users tab, pressing back button takes them to Dashboard
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: DefaultColors.background,
        // On Web, the sidebar is part of the body Row. On Mobile, it's a Drawer.
        drawer: isWeb ? null : _buildSidebar(context),
        body: Row(
          children: [
            if (isWeb && _isSidebarOpen) _buildSidebar(context),
            Expanded(
              child: Column(
                children: [
                  // --- TOP BAR ---
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu,
                              color: DefaultColors.primary, size: 30),
                          onPressed: () {
                            if (isWeb) {
                              setState(() => _isSidebarOpen = !_isSidebarOpen);
                            } else {
                              _scaffoldKey.currentState?.openDrawer();
                            }
                          },
                        ),
                        const Spacer(),
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 20),
                        const Icon(Icons.notifications_none, color: Colors.grey),
                        const SizedBox(width: 20),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: DefaultColors.primary,
                          child: const Text("A",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),

                  // --- PAGE CONTENT ---
                  // This Expanded contains whichever tab is currently selected
                  Expanded(child: pages[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sidebar UI Component
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DefaultColors.primary.withValues(red: 0.6),
            DefaultColors.primary,
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Text("L", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                const Text(
                  "LOGO",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _sidebarItem(0, Icons.home_filled, "Tableau de bord"),
          _sidebarItem(1, Icons.people_alt_rounded, "utilisateurs"),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text(
              "Déconnexion",
              style: TextStyle(color: Colors.white70),
            ),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_admin_logged_in', false); // Clear admin flag
                // await prefs.clear(); // Or clear everything if preferred

                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/loginAdmin');
                }
              }
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Sidebar Navigation Item
  Widget _sidebarItem(int index, IconData icon, String title) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        // On mobile/small screens, close the drawer after selection
        if (MediaQuery.of(context).size.width <= 900) {
          Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}