import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/reusable_widgets/rw_textview.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/views/user_views/package_item_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class PackagesListPage extends StatefulWidget {
  final String userId;
  final ValueNotifier<EPackageStatus?> filterNotifier;

  const PackagesListPage({
    super.key,
    required this.userId,
    required this.filterNotifier,
  });

  @override
  State<PackagesListPage> createState() => _PackagesListPageState();
}

class _PackagesListPageState extends State<PackagesListPage> {
  final PackageDB _db = PackageDB();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _filterScrollController = ScrollController();
  final Map<String, _CachedPage> _cache = {};
  final List<DocumentSnapshot?> _pageStarts = [null];

  List<PackageModel> _allPackages = [];
  EPackageStatus? _selectedStatus;
  String? _lastPhone;
  EPackageStatus? _lastStatus;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.filterNotifier.value;
    _lastStatus = _selectedStatus;
    widget.filterNotifier.addListener(_onFilterChanged);
    _searchController.addListener(_onPhoneTextChanged);
    _fetchPage(1);
  }

  @override
  void dispose() {
    widget.filterNotifier.removeListener(_onFilterChanged);
    _searchController.removeListener(_onPhoneTextChanged);
    _searchController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  // ── Listeners ─────────────────────────────────────────────────────────────

  void _onFilterChanged() {
    if (!mounted) return;
    final newStatus = widget.filterNotifier.value;
    if (newStatus == _lastStatus) return;
    setState(() => _selectedStatus = newStatus);
    _lastStatus = newStatus;
    _resetAndReload();
  }

  void _onPhoneTextChanged() {
    final isEmpty = _searchController.text.trim().isEmpty;
    final hadPhone = _lastPhone != null && _lastPhone!.isNotEmpty;
    if (isEmpty && hadPhone) {
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

  // ── Data ──────────────────────────────────────────────────────────────────

  String _cacheKey(int page) {
    final phone = _searchController.text.trim();
    final status = _selectedStatus?.name ?? '';
    return '$status|$phone|$page';
  }

  Future<void> _fetchPage(int page) async {
    if (_isLoading) return;

    // Check connectivity first
    // Fetch the list
    List<ConnectivityResult> connectivity = await Connectivity()
        .checkConnectivity();

    // Check if 'none' is in the list
    if (connectivity.contains(ConnectivityResult.none)) {
      setState(() => _hasError = true);
      return;
    }

    // Cache hit (skip if expired)
    final key = _cacheKey(page);
    if (_cache.containsKey(key) && !_cache[key]!.isExpired) {
      final hit = _cache[key]!;
      setState(() {
        _allPackages = hit.packages;
        _hasMore = hit.hasMore;
        _currentPage = page;
        _hasError = false;
        if (page >= _pageStarts.length && hit.nextCursor != null) {
          _pageStarts.add(hit.nextCursor);
        }
      });
      return;
    }

    _cache.remove(key); // remove stale entry if any
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final phone = _searchController.text.trim();
      final snapshot = await _db.getPackagesByUserPaged(
        userId: widget.userId,
        exactPhone: phone.isEmpty ? null : phone,
        status: _selectedStatus?.name,
        startAt: _pageStarts[page - 1],
        limit: 11, // fetch one extra to detect if there's a next page
      );

      final hasMore = snapshot.docs.length == 11;
      final docs = hasMore ? snapshot.docs.take(10).toList() : snapshot.docs;
      final items = docs.map((d) => d.data()).toList();
      final nextCursor = hasMore ? docs.last : null;

      _cache[key] = _CachedPage(
        packages: items,
        hasMore: hasMore,
        nextCursor: nextCursor,
        cachedAt: DateTime.now(),
      );

      setState(() {
        _allPackages = items;
        _hasMore = hasMore;
        _currentPage = page;
        if (page == _pageStarts.length && hasMore && nextCursor != null) {
          _pageStarts.add(nextCursor);
        }
      });
    } catch (e) {
      debugPrint('Fetch error: $e');
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetAndReload() {
    _cache.clear();
    _pageStarts
      ..clear()
      ..add(null);
    _currentPage = 1;
    _hasError = false;
    _fetchPage(1);
    setState(() {});
  }

  void _invalidateCurrentPage() {
    _cache.remove(_cacheKey(_currentPage));
    _fetchPage(_currentPage);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(child: _buildBody()),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return _buildErrorState();
    }
    if (_allPackages.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: () async {
        _cache.remove(_cacheKey(_currentPage));
        await _fetchPage(_currentPage);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allPackages.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () async {
            // Pop returns true if the package was updated
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => PackageItemCard(package: _allPackages[i]),
              ),
            );
            if (updated == true) _invalidateCurrentPage();
          },
          child: PackageItemCard(package: _allPackages[i]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
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
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 50,
      child: Listener(
        onPointerSignal: (signal) {
          if (signal is PointerScrollEvent) {
            _filterScrollController.jumpTo(
              (_filterScrollController.offset + signal.scrollDelta.dy).clamp(
                0.0,
                _filterScrollController.position.maxScrollExtent,
              ),
            );
          }
        },
        child: ListView(
          controller: _filterScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          physics: const BouncingScrollPhysics(),
          children: [
            _statusChip(
              'Tous',
              _selectedStatus == null,
              () => widget.filterNotifier.value = null,
            ),
            ...EPackageStatus.values.map(
              (s) => _statusChip(
                s.label,
                _selectedStatus == s,
                () => widget.filterNotifier.value = s,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: _currentPage > 1
                ? TextButton.icon(
                    onPressed: () => _fetchPage(_currentPage - 1),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    label: const Text(
                      'Précédent',
                      style: TextStyle(color: Colors.black),
                    ),
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
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'Suivant',
                      style: TextStyle(color: Colors.black),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Aucun colis trouvé',
            style: TextStyle(color: Colors.grey),
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
          Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Erreur de chargement',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() => _hasError = false);
              _fetchPage(_currentPage);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Container(
      height: 50,
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

  Widget _statusChip(String label, bool isSelected, VoidCallback onSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) onSelected();
        },
        selectedColor: DefaultColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Cache model ───────────────────────────────────────────────────────────────

class _CachedPage {
  final List<PackageModel> packages;
  final bool hasMore;
  final DocumentSnapshot? nextCursor;
  final DateTime cachedAt;

  const _CachedPage({
    required this.packages,
    required this.hasMore,
    required this.cachedAt,
    this.nextCursor,
  });

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > const Duration(minutes: 3);
}
