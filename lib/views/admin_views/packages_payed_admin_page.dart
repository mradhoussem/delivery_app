import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/reusable_widgets/rw_dropdown.dart';
import 'package:delivery_app/reusable_widgets/rw_expandable_widget.dart';
import 'package:delivery_app/reusable_widgets/rw_textview.dart';
import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:delivery_app/views/user_views/package_item_card.dart';
import 'package:flutter/material.dart';

class PackagesPayedAdminPage extends StatefulWidget {
  const PackagesPayedAdminPage({super.key});

  @override
  State<PackagesPayedAdminPage> createState() => _PackagesPayedAdminPageState();
}

class _PackagesPayedAdminPageState extends State<PackagesPayedAdminPage> {
  final PackageDB _db = PackageDB();
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _phoneSearchController = TextEditingController();

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

      // Utilisation du filtre Payed Status
      final snapshot = await _db.getAdminPackagesPaged(
        status: EPackageStatus.payed,
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
          const Divider(height: 1),
          Expanded(child: _buildBody()),
          if (_packages.isNotEmpty) _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _packages.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_hasError) return Center(child: Text("Erreur de chargement"));
    if (_packages.isEmpty) return Center(child: Text("Aucun colis payé trouvé"));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _packages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => PackageItemCard(
        package: _packages[index],
        showSender: true,
        isAdmin: true,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child:
          const Text("Colis Payés", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Column(
        children: [
          RwTextview(controller: _userSearchController, label: "Nom de l'expéditeur", prefixIcon: Icons.storefront),
          const SizedBox(height: 10),
          RwTextview(controller: _phoneSearchController, label: "Numéro de Téléphone", prefixIcon: Icons.phone_android, textNumeric: true),
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
            child: ElevatedButton(onPressed: _resetAndReload, child: const Text("RECHERCHER")),
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
          if (_currentPage > 1) IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _fetchPage(_currentPage - 1)),
          Text("Page $_currentPage"),
          if (_hasMore) IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _fetchPage(_currentPage + 1)),
        ],
      ),
    );
  }
}