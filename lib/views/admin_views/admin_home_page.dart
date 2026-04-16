import 'package:delivery_app/reusable_widgets/rw_appbar.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar_item.dart';
import 'package:delivery_app/views/admin_views/packages_admin_page.dart';
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

  // NEW: Track which pages have been visited to avoid loading everything at once
  late List<bool> _activatedPages;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // We have 3 items in the sidebar. Index 0 is active by default.
    _activatedPages = [true, false, false];
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin_logged_in', false);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/loginAdmin');
    }
  }

  List<RwSideBarItem> _buildItems() {
    return [
      RwSideBarItem(
        title: "Tableau de bord",
        icon: Icons.dashboard,
        page: const PackagesAdminPage(),
      ),
      RwSideBarItem(
        title: "Utilisateurs",
        icon: Icons.people,
        page: const UsersViewPage(),
      ),
      RwSideBarItem(
        title: "Paramètres",
        icon: Icons.settings,
        page: const Center(child: Text("Paramètres Admin")),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 900;
    final items = _buildItems();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: DefaultColors.pagesBackground,
      drawer: isWeb ? null : _buildSidebar(items),
      body: Row(
        children: [
          if (isWeb && _isSidebarOpen) _buildSidebar(items),
          Expanded(
            child: Column(
              children: [
                RwAppbar(
                  username: "Administrateur",
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
                    index: _selectedIndex,
                    children: items.asMap().entries.map((entry) {
                      // Optimization: If not activated yet, show empty box
                      return _activatedPages[entry.key]
                          ? entry.value.page
                          : const SizedBox.shrink();
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(List<RwSideBarItem> items) {
    return RwSideBar(
      portalTitle: "ADMIN PORTAL",
      selectedIndex: _selectedIndex,
      items: items,
      primaryColor: Colors.white,
      // Standard admin theme
      backgroundColor: DefaultColors.primary,
      unselectedColor: Colors.white70,
      onItemSelected: (index) {
        setState(() {
          _selectedIndex = index;
          _activatedPages[index] = true; // Activate the page on first visit
        });

        // Close drawer automatically on mobile
        if (MediaQuery.of(context).size.width <= 900) {
          _scaffoldKey.currentState?.closeDrawer();
        }
      },
      onLogout: _handleLogout,
    );
  }
}
