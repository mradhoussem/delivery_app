import 'package:delivery_app/reusable_widgets/rw_appbar.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/views/user_views/dashboard_user_page.dart';
import 'package:delivery_app/views/user_views/packages_list_page.dart' show PackagesListPage;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = true;
  String _username = "Utilisateur";
  String? _userid;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _username = prefs.getString('username') ?? "Expéditeur");
    setState(() => _userid = prefs.getString('user_id') ?? "Expéditeur");
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 900;

    final List<Widget> pages = [
      DashboardUserPage(username: _username),
      _userid != null ? PackagesListPage(userId: _userid!) :  const Center(child: Text("Aucun utilisateur est connecté")),
      const Center(child: Text("Paramètres")),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: DefaultColors.background,
      // --- SIDEBAR MOBILE (Drawer) ---
      drawer: isWeb
          ? null
          : RwSideBar(
              selectedIndex: _selectedIndex,
              primaryColor: DefaultColors.primary,
              backgroundColor: DefaultColors.background,
              onItemSelected: (index) => setState(() => _selectedIndex = index),
              onLogout: _handleLogout,
            ),
      body: Row(
        children: [
          // --- SIDEBAR WEB (Fixe) ---
          if (isWeb && _isSidebarOpen)
            RwSideBar(
              selectedIndex: _selectedIndex,
              primaryColor: DefaultColors.primary,
              backgroundColor: DefaultColors.background,
              onItemSelected: (index) => setState(() => _selectedIndex = index),
              onLogout: _handleLogout,
            ),

          Expanded(
            child: Column(
              children: [
                // --- TOP BAR ---
                RwAppbar(
                  username: _username,
                  primaryColor: DefaultColors.primary,
                  onMenuPressed: () {
                    if (isWeb) {
                      setState(() => _isSidebarOpen = !_isSidebarOpen);
                    } else {
                      _scaffoldKey.currentState?.openDrawer();
                    }
                  },
                ),

                // --- CONTENU ---
                Expanded(
                  child: IndexedStack(index: _selectedIndex, children: pages),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
