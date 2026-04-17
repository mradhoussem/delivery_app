import 'package:delivery_app/reusable_widgets/rw_sidebar_item.dart';
import 'package:delivery_app/views/user_views/packages_payed_list_page.dart';
import 'package:delivery_app/views/user_views/packages_recieved_list_page.dart';
import 'package:delivery_app/views/user_views/packages_waiting_list_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/reusable_widgets/rw_appbar.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar.dart';
import 'package:delivery_app/views/user_views/dashboard_user_page.dart';
import 'package:delivery_app/views/user_views/packages_list_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 0;
  String _username = "Utilisateur";
  String? _userid;
  bool _isSidebarOpen = true;

  // NEW: Track which indices have been visited
  late List<bool> _activatedPages;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Initialize with first page active, others false
    _activatedPages = List.generate(6, (index) => index == 0);
    _loadUserInfo();
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

  List<RwSideBarItem> _buildItems() {
    if (_userid == null) return [];

    return [
      RwSideBarItem(
        title: "Tableau de bord",
        icon: Icons.dashboard,
        page: DashboardUserPage(userId: _userid!, username: _username),
      ),
      RwSideBarItem(
        title: "Mes Colis",
        icon: Icons.inventory_2,
        page: PackagesListPage(userId: _userid!),
      ),
      RwSideBarItem(
        title: "Colis en attente",
        icon: Icons.pending_actions,
        page: PackagesWaitingListPage(userId: _userid!),
      ),
      RwSideBarItem(
        title: "Mes paiements",
        icon: Icons.monetization_on,
        page: PackagesPayedListPage(userId: _userid!),
      ),
      RwSideBarItem(
        title: "Mes retours",
        icon: Icons.inventory_outlined,
        page: PackagesReceivedListPage(userId: _userid!),
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
                  child: _userid == null
                      ? const Center(child: CircularProgressIndicator())
                      : IndexedStack(
                          index: _selectedIndex,
                          // Only show the real page if it has been activated, otherwise show empty
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
      selectedIndex: _selectedIndex,
      items: items,
      primaryColor: DefaultColors.primary,
      backgroundColor: Colors.white,
      portalTitle: "",
      onItemSelected: (index) {
        setState(() {
          _selectedIndex = index;
          _activatedPages[index] = true; // Activate the page when clicked
        });
      },
      onLogout: _handleLogout,
    );
  }
}
