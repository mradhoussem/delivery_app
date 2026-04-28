import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/reusable_widgets/rw_dropdown.dart';
import 'package:delivery_app/reusable_widgets/rw_empty_packages.dart';
import 'package:delivery_app/reusable_widgets/rw_expandable_widget.dart';
import 'package:delivery_app/reusable_widgets/rw_textview.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:delivery_app/views/user_views/package_item_card.dart';
import 'package:flutter/material.dart';

class PackagesReceivedListPage extends StatefulWidget {
  final String userId;
  const PackagesReceivedListPage({super.key, required this.userId});

  @override
  State<PackagesReceivedListPage> createState() => _PackagesReceivedListPageState();
}

class _PackagesReceivedListPageState extends State<PackagesReceivedListPage> {
  final PackageDB _db = PackageDB();
  final TextEditingController _searchController = TextEditingController();

  final Map<String, _CachedPage> _cache = {};
  final List<DocumentSnapshot?> _pageStarts = [null];

  List<PackageModel> _allPackages = [];
  final List<String> _sortOptions = ['décroissant', 'croissant'];

  String? _lastPhone;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isDescending = true;

  static const List<EPackageStatus> _statuses = [
    EPackageStatus.permanentReturn,
    EPackageStatus.returnReceived,
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onPhoneTextChanged);
    RefreshNotifier().refreshCounter.addListener(_resetAndReload);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPage(1));
  }

  @override
  void dispose() {
    _searchController.removeListener(_onPhoneTextChanged);
    RefreshNotifier().refreshCounter.removeListener(_resetAndReload);
    _searchController.dispose();
    super.dispose();
  }

  void _onPhoneTextChanged() {
    final text = _searchController.text.trim();
    if (text.isEmpty && _lastPhone != null && _lastPhone!.isNotEmpty) {
      _lastPhone = '';
      _resetAndReload();
    }
  }

  void _onSearchPressed() {
    final phone = _searchController.text.trim();
    if (phone == (_lastPhone ?? '')) return;
    _lastPhone = phone;
    _resetAndReload();
  }

  String _cacheKey(int page) =>
      '${_lastPhone ?? ""}|$page|$_isDescending|${_statuses.map((e) => e.name).join(',')}';

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
          _allPackages = hit.packages;
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
      final phone = _searchController.text.trim();

      final snapshot = await _db.getPackagesByUserByStatusPaged(
        userId: widget.userId,
        statuses: _statuses,
        exactPhone: phone.isEmpty ? null : phone,
        startAt: _pageStarts[page - 1],
        limit: 11,
        descending: _isDescending,
      );

      final hasMore = snapshot.docs.length == 11;
      final docs = hasMore ? snapshot.docs.take(10).toList() : snapshot.docs;
      final items = docs.map((d) => d.data()).toList();

      if (hasMore && page == _pageStarts.length) {
        _pageStarts.add(docs.last);
      }

      _cache[key] = _CachedPage(
        packages: items,
        hasMore: hasMore,
        cachedAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _allPackages = items;
          _hasMore = hasMore;
          _currentPage = page;
        });
      }
    } catch (e) {
      debugPrint('FIRESTORE ERROR: $e');
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
    return Scaffold(
      backgroundColor: DefaultColors.pagesBackground,
      body: Column(
        children: [
          _buildHeader(),
          const Divider(),
          Expanded(child: _buildBody()),
          if (_allPackages.isNotEmpty) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Colis retournés",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: DefaultColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          RwExpandableWidget(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RwTextview(
                        controller: _searchController,
                        backgroundColor: Colors.white,
                        hint: 'Rechercher Tél 1 ou Tél 2...',
                        textNumeric: true,
                        prefixIcon: Icons.phone_iphone,
                        iconColor: Colors.blue,
                        maxLength: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _iconButton(Icons.search, _onSearchPressed),
                  ],
                ),
                const SizedBox(height: 12),
                RwDropdown(
                  label: "Trier par date",
                  prefixIcon: Icons.sort,
                  iconColor: Colors.blueGrey,
                  value: _isDescending ? 'décroissant' : 'croissant',
                  items: _sortOptions,
                  itemLabelBuilder: (val) => val == 'décroissant'
                      ? "Plus récent (Nouveau → Ancien)"
                      : "Plus ancien (Ancien → Nouveau)",
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    final shouldBeDesc = (newValue == 'décroissant');
                    if (shouldBeDesc != _isDescending) {
                      setState(() => _isDescending = shouldBeDesc);
                      _resetAndReload();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hasError) return const Center(child: Text("Erreur de chargement"));
    if (_allPackages.isEmpty) return const EmptyStateWidget();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allPackages.length,
      itemBuilder: (_, i) => PackageItemCard(
        package: _allPackages[i],
        showReturnReceivedButton: true, // Pour confirmer la réception du retour
        isAdmin: false,
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
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

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: DefaultColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}

class _CachedPage {
  final List<PackageModel> packages;
  final bool hasMore;
  final DateTime cachedAt;
  const _CachedPage({required this.packages, required this.hasMore, required this.cachedAt});
  bool get isExpired => DateTime.now().difference(cachedAt) > const Duration(minutes: 5);
}