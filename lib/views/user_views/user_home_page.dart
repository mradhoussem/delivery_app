import 'package:delivery_app/reusable_widgets/rw_appbar.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar_item.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/views/user_views/dashboard_user_page.dart';
import 'package:delivery_app/views/user_views/packages_list_page.dart';
import 'package:delivery_app/views/user_views/packages_payed_list_page.dart';
import 'package:delivery_app/views/user_views/packages_recieved_list_page.dart';
import 'package:delivery_app/views/user_views/packages_waiting_list_page.dart';
import 'package:delivery_app/views/user_views/user_edit_password_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 0;
  final List<int> _history = [0];
  String _username = "Utilisateur";
  String? _userid;
  String? _selectedStatus;
  bool _isSidebarOpen = true;

  late List<bool> _activatedPages;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _activatedPages = List.generate(10, (index) => index == 0);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? "Expéditeur";
        _userid = prefs.getString('user_id');
      });
    }
  }

  void _navigateToTab(int index, {String? status}) {
    setState(() {
      _selectedIndex = index;
      _selectedStatus = status;
      _activatedPages[index] = true;
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
        page: DashboardUserPage(
          userId: _userid!,
          username: _username,
          onNavigate: _navigateToTab,
        ),
      ),
      RwSideBarItem(
        title: "Mes Colis",
        icon: Icons.inventory_2,
        page: PackagesListPage(
          // La Key force le widget à se reconstruire si le statut change
          key: ValueKey(_selectedStatus),
          userId: _userid!,
          initialStatus: _selectedStatus,
        ),
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
      RwSideBarItem(
        title: "Mettre à jour le mot de passe",
        icon: Icons.password,
        page: const UserEditPasswordPage(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 900;
    final items = _buildItems();

    return PopScope(
      canPop: _history.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_history.length > 1) {
          setState(() {
            // Remove the current page from history
            _history.removeLast();
            // Set the index to the new "last" page in history
            _selectedIndex = _history.last;
          });
        }
      },
      child: Scaffold(
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
                            children: items.map((item) {
                              int idx = items.indexOf(item);
                              return item.page != null
                                  ? (_activatedPages[idx]
                                        ? item.page!
                                        : const SizedBox.shrink())
                                  : const SizedBox.shrink();
                            }).toList(),
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

  Widget _buildSidebar(List<RwSideBarItem> items) {
    return RwSideBar(
      selectedIndex: _selectedIndex,
      items: items,
      primaryColor: DefaultColors.primary,
      backgroundColor: Colors.white,
      portalTitle: "MENU",
      onItemSelected: (index) {
        // Reset du statut si on clique manuellement sur le menu latéral
        _navigateToTab(index, status: null);
        _history.add(index);
      },
      onLogout: _handleLogout,
    );
  }
}