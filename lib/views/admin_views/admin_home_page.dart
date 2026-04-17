import 'package:delivery_app/reusable_widgets/rw_appbar.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar_item.dart';
import 'package:delivery_app/views/admin_views/packages_admin_page.dart';
import 'package:delivery_app/views/admin_views/scanner_admin_page.dart';
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

  // null = still loading, true = ready to show content
  bool? _isReady;

  late List<bool> _activatedPages;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _activatedPages = List.generate(4, (index) => index == 0);
    _initAdmin();
  }

  Future<void> _initAdmin() async {
    // This async gap mirrors _loadUserInfo() in UserHomePage.
    // It ensures the first build() sees _isReady == null,
    // so IndexedStack is not constructed until _isReady flips to true.
    // Without this, _buildItems() returns real widgets on the very first
    // build(), and any later setState recreates them — causing blank pages.
    final prefs = await SharedPreferences.getInstance();
    final bool loggedIn = prefs.getBool('is_admin_logged_in') ?? false;
    if (mounted) {
      setState(() => _isReady = loggedIn);
    }
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
        title: "Confirmer Statut",
        icon: Icons.qr_code_2,
        page: const AdminScannerPage(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 900;

    // Same local variable used for both drawer and body —
    // guarantees both get the exact same widget instances in one frame.
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
                  child: _isReady == null
                      ? const Center(child: CircularProgressIndicator())
                      : IndexedStack(
                    index: _selectedIndex,
                    children: items.asMap().entries.map((entry) {
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
      portalTitle: "PORTAIL ADMIN",
      selectedIndex: _selectedIndex,
      items: items,
      primaryColor: Colors.white,
      backgroundColor: DefaultColors.accent,
      unselectedColor: Colors.white70,
      onItemSelected: (index) {
        setState(() {
          _selectedIndex = index;
          _activatedPages[index] = true;
        });
      },
      onLogout: _handleLogout,
    );
  }
}