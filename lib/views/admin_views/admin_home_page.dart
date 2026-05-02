import 'package:delivery_app/dialogs/rd_print_save_payed_packages.dart';
import 'package:delivery_app/dialogs/rd_print_save_permenet_recieved_package.dart';
import 'package:delivery_app/dialogs/rd_print_save_waiting_package.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/models/m_user.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/init/loading_overlay.dart';
import 'package:delivery_app/reusable_widgets/rw_appbar.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar_item.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/views/admin_views/admin_use_selection_page.dart';
import 'package:delivery_app/views/admin_views/packages_admin_page.dart';
import 'package:delivery_app/views/admin_views/packages_payed_admin_page.dart';
import 'package:delivery_app/views/admin_views/packages_waiting_admin_page.dart';
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
  bool? _isReady;
  final List<int> _history = [0];
  final PackageDB _db = PackageDB();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initAdmin();
  }

  Future<void> _initAdmin() async {
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


  // --- Logique d'impression ---

  Future<void> _handlePrintByUser(EPackageStatus status, UserModel user) async {
    List<PackageModel> list = [];
    String periodLabel = "";

    try {
      if (status == EPackageStatus.payed) {
        final dateResult = await _showDateFilterDialog(context);
        if (dateResult == null) return;

        periodLabel = "${dateResult['month'].toString().padLeft(
            2, '0')}/${dateResult['year']}";
        if (mounted) {
          LoadingOverlay.show(context);
        }
        // Utilisation du filtre userId (creatorId)
        final snapshot = await _db.getAdminPackagesPaged(
          status: EPackageStatus.payed,
          searchUsername: user.username,
          // Ou filtrez par ID si votre DB le supporte
          limit: 500,
          // On prend une large limite pour le rapport
          descending: true,
        );
        list = snapshot.docs.map((d) => d.data()).toList();
      } else {
        LoadingOverlay.show(context);
        // Récupération filtrée par statut et utilisateur
        final snapshot = await _db.getAdminPackagesPaged(
          status: status,
          searchUsername: user.username,
          limit: 500,
          descending: true,
        );
        list = snapshot.docs.map((d) => d.data()).toList();
      }

      if (mounted) LoadingOverlay.hide(context);

      if (list.isEmpty) {
        _showNoPackagesPopup("${status.name} pour ${user.username}");
        return;
      }

      // Appel des dialogues PDF existants
      if(mounted){
      if (status == EPackageStatus.waiting) {
        await RdPrintSaveWaitingPackages.show(context, list);
      } else if (status == EPackageStatus.permanentReturn) {
        await RdPrintSavePermanentReturn.show(context, list);
      } else if (status == EPackageStatus.payed) {
        await RdPrintSavePayedPackages.show(context, list, periodLabel);
      }}
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e")),
        );
      }
    }
  }

  Future<Map<String, int>?> _showDateFilterDialog(BuildContext context) async {
    int selectedYear = DateTime
        .now()
        .year;
    int selectedMonth = DateTime
        .now()
        .month;
    final List<String> monthNames = [
      "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
      "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
    ];

    return showDialog<Map<String, int>>(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            title: const Text("Période des rapports"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatefulBuilder(
                  builder: (context, setStepState) =>
                      Column(
                        children: [
                          DropdownButton<int>(
                            value: selectedMonth,
                            isExpanded: true,
                            items: List.generate(12, (i) =>
                                DropdownMenuItem(value: i + 1, child: Text(
                                    monthNames[i]))),
                            onChanged: (v) =>
                                setStepState(() => selectedMonth = v!),
                          ),
                          const SizedBox(height: 10),
                          DropdownButton<int>(
                            value: selectedYear,
                            isExpanded: true,
                            items: [2024, 2025, 2026].map((y) =>
                                DropdownMenuItem(value: y, child: Text(
                                    "Année: $y"))).toList(),
                            onChanged: (v) =>
                                setStepState(() => selectedYear = v!),
                          ),
                        ],
                      ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: const Text("ANNULER")),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(
                        ctx, {"month": selectedMonth, "year": selectedYear}),
                child: const Text("CONFIRMER"),
              ),
            ],
          ),
    );
  }

  void _showNoPackagesPopup(String status) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: const Text("Aucun colis"),
            content: Text("Aucun colis trouvé pour cette catégorie."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
            ],
          ),
    );
  }

  List<RwSideBarItem> _buildItems() {
    return [
      RwSideBarItem(
        title: "Tableau de bord",
        icon: Icons.dashboard,
        page: const PackagesAdminPage(),
      ),
      RwSideBarItem(
        title: "Colis en attente",
        icon: Icons.pending_actions,
        page: const PackagesWaitingAdminPage(),
      ),
      RwSideBarItem(
        title: "Colis payé",
        icon: Icons.monetization_on,
        page: const PackagesPayedAdminPage(),
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
      RwSideBarItem(
        title: "Imprimer Retours",
        icon: Icons.print,
        page: AdminUserSelectionPage(
          status: EPackageStatus.permanentReturn,
          onUserSelected: (user) =>
              _handlePrintByUser(EPackageStatus.permanentReturn, user),
        ),
      ),
      RwSideBarItem(
        title: "Imprimer Payés",
        icon: Icons.print,
        page: AdminUserSelectionPage(
          status: EPackageStatus.payed,
          onUserSelected: (user) =>
              _handlePrintByUser(EPackageStatus.payed, user),
        ),
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
                      children: items.map((item) {
                        return item.page ?? const SizedBox.shrink();
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
      portalTitle: "PORTAIL ADMIN",
      selectedIndex: _selectedIndex,
      items: items,
      primaryColor: Colors.white,
      backgroundColor: DefaultColors.accent,
      unselectedColor: Colors.white70,
      onItemSelected: (index) {
        setState(() {
          _selectedIndex = index;
          _history.add(index);
        });
      },
      onLogout: _handleLogout,
    );
  }
}