import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/dialogs/rd_print_save_payed_packages.dart';
import 'package:delivery_app/dialogs/rd_print_save_permenet_recieved_package.dart';
import 'package:delivery_app/dialogs/rd_print_save_waiting_package.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/init/loading_overlay.dart';
import 'package:delivery_app/reusable_widgets/rw_dropdown.dart';
import 'package:delivery_app/reusable_widgets/rw_expandable_widget.dart';
import 'package:delivery_app/reusable_widgets/rw_textview.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:delivery_app/views/user_views/package_item_card.dart';
import 'package:flutter/material.dart';

class PackagesAdminPage extends StatefulWidget {
  const PackagesAdminPage({super.key});

  @override
  State<PackagesAdminPage> createState() => _PackagesAdminPageState();
}

class _PackagesAdminPageState extends State<PackagesAdminPage> {
  final PackageDB _db = PackageDB();
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _phoneSearchController = TextEditingController();

  final Map<String, _CachedAdminPage> _cache = {};
  final List<DocumentSnapshot?> _pageStarts = [null];

  List<PackageModel> _packages = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isDescending = true;
  bool _isInitialized = false;

  final List<String> _sortOptions = ['décroissant', 'croissant'];

  @override
  void initState() {
    super.initState();
    RefreshNotifier().refreshCounter.addListener(_resetAndReload);
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _phoneSearchController.dispose();
    RefreshNotifier().refreshCounter.removeListener(_resetAndReload);
    super.dispose();
  }

  void initDataIfNeeded() {
    if (!_isInitialized) {
      _fetchPage(1);
      _isInitialized = true;
    }
  }

  Future<void> _fetchPage(int page) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final nameQuery = _userSearchController.text.trim();
      final phoneQuery = _phoneSearchController.text.trim();

      final snapshot = await _db.getAdminPackagesPaged(
        searchUsername: nameQuery.isEmpty ? null : nameQuery,
        searchPhone: phoneQuery.isEmpty ? null : phoneQuery,
        startAt: _pageStarts[page - 1],
        limit: 11,
        descending: _isDescending,
      );

      final hasMore = snapshot.docs.length == 11;
      final docs = hasMore ? snapshot.docs.take(10).toList() : snapshot.docs;
      final items = docs.map((d) => d.data()).toList();

      if (hasMore && page == _pageStarts.length) _pageStarts.add(docs.last);

      setState(() {
        _packages = items;
        _hasMore = hasMore;
        _currentPage = page;
      });
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetAndReload() {
    setState(() {
      _cache.clear();
      _pageStarts.clear();
      _pageStarts.add(null);
      _currentPage = 1;
    });
    _fetchPage(1);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) initDataIfNeeded();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          RwExpandableWidget(child: _buildSearchSection()),

          // --- Buttons Section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                _buildPrintBtn("Imprimer colis en attentes", Icons.history,
                    DefaultColors.secondary,
                        () => _handlePrint(EPackageStatus.waiting)),
                _buildPrintBtn(
                    "Imprimer colis de retours", Icons.keyboard_return,
                    DefaultColors.secondary,
                        () => _handlePrint(EPackageStatus.permanentReturn)),
                _buildPrintBtn(
                    "Imprimer colis payés", Icons.payments, DefaultColors.secondary,
                        () => _handlePrint(EPackageStatus.payed)),
              ],
            ),
          ),

          const Divider(height: 1),
          Expanded(child: _buildBody()),
          if (_packages.isNotEmpty) _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildPrintBtn(String label, IconData icon, Color color,
      VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(
          fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Future<Map<String, int>?> _showDateFilterDialog(BuildContext context) async {
    int selectedYear = DateTime
        .now()
        .year;
    int selectedMonth = DateTime
        .now()
        .month;

    // Liste des noms des mois
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
            title: const Text("Choisir la période"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown pour les MOIS (Noms au lieu de numéros)
                StatefulBuilder(
                  builder: (context, setStepState) =>
                      Column(
                        children: [
                          DropdownButton<int>(
                            value: selectedMonth,
                            isExpanded: true,
                            items: List.generate(12, (i) {
                              return DropdownMenuItem(
                                value: i + 1,
                                child: Text(
                                    monthNames[i]), // Affiche le nom du mois
                              );
                            }),
                            onChanged: (v) {
                              if (v != null) {
                                setStepState(() => selectedMonth = v);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          // Dropdown pour les ANNÉES
                          DropdownButton<int>(
                            value: selectedYear,
                            isExpanded: true,
                            items: [2024, 2025, 2026].map((y) {
                              return DropdownMenuItem(
                                value: y,
                                child: Text("Année: $y"),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setStepState(() => selectedYear = v);
                              }
                            },
                          ),
                        ],
                      ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("ANNULER"),
              ),
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

  Future<void> _handlePrint(EPackageStatus status) async {
    List<PackageModel> list = [];
    String periodLabel = "";

    try {
      // 1. If status is payed, ask for date first
      if (status == EPackageStatus.payed) {
        final dateResult = await _showDateFilterDialog(context);
        if (dateResult == null) return; // User cancelled

        periodLabel = "${dateResult['month'].toString().padLeft(
            2, '0')}/${dateResult['year']}";

        LoadingOverlay.show(context);
        list = await _db.getPaidPackagesForReport(
          year: dateResult['year']!,
          month: dateResult['month']!,
        );
      } else {
        // 2. Otherwise fetch by status normally
        LoadingOverlay.show(context);
        list = await _db.getAdminPackagesByStatus(status: status);
      }

      // 3. Hide the overlay now that data is ready
      if (mounted) LoadingOverlay.hide(context);

      if (list.isEmpty) {
        if (mounted) _showNoPackagesPopup(context, status.name);
        return;
      }

      // 4. Trigger the appropriate PDF logic
      if (status == EPackageStatus.waiting) {
        await RdPrintSaveWaitingPackages.show(context, list);
      } else if (status == EPackageStatus.permanentReturn) {
        await RdPrintSavePermanentReturn.show(context, list);
      } else if (status == EPackageStatus.payed) {
        // Pass the list and the period to your Payed Dialog
        await RdPrintSavePayedPackages.show(context, list, periodLabel);
      }
    } catch (e) {
      // Safety: Hide overlay if an error occurs
      if (mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Erreur lors de la récupération des données")),
        );
      }
      debugPrint("Print Fetch Error: $e");
    }
  }

  void _showNoPackagesPopup(BuildContext context, String status) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: const Text("Aucun colis"),
            content: Text("Aucun colis trouvé pour le statut: $status"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
            ],
          ),
    );
  }

  // ... (Keep existing _buildBody, _buildHeader, _buildSearchSection, etc. from your previous code)

  Widget _buildBody() {
    if (_isLoading && _packages.isEmpty)
      return const Center(child: CircularProgressIndicator());
    if (_hasError) return _buildErrorState();
    if (_packages.isEmpty) return _buildEmptyState();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _packages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          PackageItemCard(
              package: _packages[index], showSender: true, isAdmin: true),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Flux Global",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          IconButton(onPressed: _isLoading ? null : _resetAndReload,
              icon: const Icon(Icons.refresh, color: DefaultColors.primary)),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Column(
        children: [
          RwTextview(controller: _userSearchController,
              label: "Nom de l'expéditeur",
              prefixIcon: Icons.storefront),
          const SizedBox(height: 10),
          RwTextview(controller: _phoneSearchController,
              label: "Numéro de Téléphone",
              prefixIcon: Icons.phone_android,
              textNumeric: true),
          const SizedBox(height: 15),
          RwDropdown(
            label: "ORDRE DE TRI",
            value: _isDescending ? 'décroissant' : 'croissant',
            items: _sortOptions,
            onChanged: (val) {
              if (val != null) {
                setState(() => _isDescending = (val == 'décroissant'));
                _resetAndReload();
              }
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: _resetAndReload, child: const Text("RECHERCHER")),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_currentPage > 1) IconButton(icon: const Icon(Icons.chevron_left),
              onPressed: () => _fetchPage(_currentPage - 1)),
          Text("Page $_currentPage"),
          if (_hasMore) IconButton(icon: const Icon(Icons.chevron_right),
              onPressed: () => _fetchPage(_currentPage + 1)),
        ],
      ),
    );
  }

  Widget _buildErrorState() => Center(child: Text("Erreur de chargement"));

  Widget _buildEmptyState() => Center(child: Text("Aucun colis"));
}

class _CachedAdminPage {
  final List<PackageModel> packages;
  final bool hasMore;
  final DateTime cachedAt;

  _CachedAdminPage(
      {required this.packages, required this.hasMore, required this.cachedAt});
}