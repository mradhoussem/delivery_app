import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
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

  // Gestion de la pagination et du cache
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

  String _cacheKey(int page) {
    final name = _userSearchController.text.trim();
    final phone = _phoneSearchController.text.trim();
    return '$name|$phone|$page|$_isDescending';
  }

  Future<void> _fetchPage(int page) async {
    if (_isLoading) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    final key = _cacheKey(page);
    if (_cache.containsKey(key) && !_cache[key]!.isExpired) {
      final hit = _cache[key]!;
      if (mounted) {
        setState(() {
          _packages = hit.packages;
          _hasMore = hit.hasMore;
          _currentPage = page;
          _hasError = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final nameQuery = _userSearchController.text.trim();
      final phoneQuery = _phoneSearchController.text.trim();

      // On demande 11 éléments pour vérifier s'il y a une page suivante (hasMore)
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

      // Sauvegarder le curseur pour la page suivante si nécessaire
      if (hasMore && page == _pageStarts.length) {
        _pageStarts.add(docs.last);
      }

      _cache[key] = _CachedAdminPage(
        packages: items,
        hasMore: hasMore,
        cachedAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _packages = items;
          _hasMore = hasMore;
          _currentPage = page;
        });
      }
    } catch (e) {
      debugPrint("Admin Pagination Error: $e");
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetAndReload() {
    if (!mounted) return;
    setState(() {
      _cache.clear();
      _pageStarts.clear();
      _pageStarts.add(null);
      _currentPage = 1;
      _hasError = false;
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
    if (_isLoading && _packages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) return _buildErrorState();
    if (_packages.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _packages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return PackageItemCard(
          package: _packages[index],
          showSender: true,
          isAdmin: true,
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Flux Global",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: _isLoading ? null : _resetAndReload,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, color: DefaultColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Column(
        children: [
          RwTextview(
            controller: _userSearchController,
            label: "Nom de l'expéditeur",
            prefixIcon: Icons.storefront,
          ),
          const SizedBox(height: 10),
          RwTextview(
            controller: _phoneSearchController,
            label: "Numéro de Téléphone",
            prefixIcon: Icons.phone_android,
            textNumeric: true,
          ),
          const SizedBox(height: 15),
          RwDropdown(
            label: "ORDRE DE TRI",
            prefixIcon: Icons.swap_vert_rounded,
            iconColor: DefaultColors.primary,
            value: _isDescending ? 'décroissant' : 'croissant',
            items: _sortOptions,
            itemLabelBuilder: (val) => val == 'décroissant'
                ? "PLUS RÉCENT (NOUVEAU → ANCIEN)"
                : "PLUS ANCIEN (ANCIEN → NOUVEAU)",
            onChanged: (String? newValue) {
              if (newValue == null) return;
              final shouldBeDesc = (newValue == 'décroissant');
              if (shouldBeDesc != _isDescending) {
                setState(() => _isDescending = shouldBeDesc);
                _resetAndReload();
              }
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _resetAndReload,
              style: ElevatedButton.styleFrom(
                backgroundColor: DefaultColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.search_rounded),
              label: const Text("LANCER LA RECHERCHE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: _currentPage > 1
                ? TextButton.icon(
              onPressed: () => _fetchPage(_currentPage - 1),
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              label: const Text('Précédent'),
            )
                : null,
          ),
          Expanded(
            child: Text(
              'Page $_currentPage',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 120,
            child: _hasMore
                ? TextButton.icon(
              onPressed: () => _fetchPage(_currentPage + 1),
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              label: const Text('Suivant'),
            )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const Text("Une erreur est survenue"),
          TextButton(onPressed: _resetAndReload, child: const Text("Réessayer")),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
          const Text("Aucun colis trouvé", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _CachedAdminPage {
  final List<PackageModel> packages;
  final bool hasMore;
  final DateTime cachedAt;
  const _CachedAdminPage({required this.packages, required this.hasMore, required this.cachedAt});
  bool get isExpired => DateTime.now().difference(cachedAt) > const Duration(minutes: 5);
}