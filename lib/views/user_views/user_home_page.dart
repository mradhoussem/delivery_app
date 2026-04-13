import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/reusable_widgets/rw_appbar.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar.dart';
import 'package:delivery_app/views/user_views/dashboard_user_page.dart';
import 'package:delivery_app/views/user_views/packages_list_page.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  // Notifiers that will be passed down to children
  final ValueNotifier<int> _indexNotifier = ValueNotifier<int>(0);
  final ValueNotifier<EPackageStatus?> _filterNotifier = ValueNotifier<EPackageStatus?>(null);

  bool _isSidebarOpen = true;
  String _username = "Utilisateur";
  String? _userid;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _indexNotifier.dispose();
    _filterNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "Expéditeur";
      _userid = prefs.getString('user_id');
    });
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: isWeb ? null : _buildSidebar(false),
      body: Row(
        children: [
          if (isWeb && _isSidebarOpen) _buildSidebar(true),
          Expanded(
            child: Column(
              children: [
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
                Expanded(
                  // ValueListenableBuilder listens to index changes to switch pages
                  child: ValueListenableBuilder<int>(
                    valueListenable: _indexNotifier,
                    builder: (context, selectedIndex, _) {
                      return IndexedStack(
                        index: selectedIndex,
                        children: [
                          _userid != null
                              ? DashboardUserPage(
                            userId: _userid!,
                            username: _username,
                            indexNotifier: _indexNotifier,
                            filterNotifier: _filterNotifier,
                          )
                              : const Center(child: Text("Chargement...")),
                          _userid != null
                              ? PackagesListPage(
                            userId: _userid!,
                            // We'll pass the notifier so the list reacts to changes
                            filterNotifier: _filterNotifier,
                          )
                              : const Center(child: Text("Chargement...")),
                          const Center(child: Text("Paramètres")),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isFixed) {
    return ValueListenableBuilder<int>(
      valueListenable: _indexNotifier,
      builder: (context, index, _) {
        return RwSideBar(
          selectedIndex: index,
          primaryColor: DefaultColors.primary,
          backgroundColor: Colors.white,
          onItemSelected: (i) => _indexNotifier.value = i,
          onLogout: _handleLogout,
        );
      },
    );
  }
}