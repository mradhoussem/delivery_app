import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/reusable_widgets/rw_textview.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/views/user_views/package_item_card.dart';
import 'package:flutter/material.dart';

class PackagesListPage extends StatefulWidget {
  final String userId;

  const PackagesListPage({super.key, required this.userId});

  @override
  State<PackagesListPage> createState() => _PackagesListPageState();
}

class _PackagesListPageState extends State<PackagesListPage> {
  final PackageDB _db = PackageDB();
  final TextEditingController _searchController = TextEditingController();

  List<PackageModel> _allPackages = [];
  bool _isLoading = false;
  EPackageStatus? _selectedStatus;

  int _currentPage = 1;
  bool _hasMore = true;
  final List<DocumentSnapshot?> _pageStarts = [null];

  @override
  void initState() {
    super.initState();
    _fetchPage(1);
  }

  Future<void> _fetchPage(int page) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      String? phoneSearch = _searchController.text.trim();
      final snapshot = await _db.getPackagesByUserPaged(
        userId: widget.userId,
        exactPhone: phoneSearch.isEmpty ? null : phoneSearch,
        status: _selectedStatus?.name,
        startAt: _pageStarts[page - 1],
        limit: 10,
      );

      final newItems = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        _allPackages = newItems;
        _currentPage = page;
        _hasMore = newItems.length == 10;
        if (page == _pageStarts.length && _hasMore) {
          _pageStarts.add(snapshot.docs.last);
        }
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetAndReload() {
    _pageStarts.clear();
    _pageStarts.add(null);
    _fetchPage(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.background,
      body: Column(
        children: [
          _buildHeaderSection(),
          _buildStatusFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allPackages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allPackages.length,
                    itemBuilder: (context, index) =>
                        PackageItemCard(package: _allPackages[index]),
                  ),
          ),
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: RwTextview(
              controller: _searchController,
              backgroundColor: Colors.white,
              hint: "Rechercher Tél 1 ou Tél 2...",
              textNumeric: true,
              prefixIcon: Icons.phone_iphone,
              iconColor: Colors.blue,
              maxLength: 12,
            ),
          ),
          const SizedBox(width: 8),
          _buildSquareIconButton(Icons.search, _resetAndReload),
        ],
      ),
    );
  }

  Widget _buildSquareIconButton(IconData icon, VoidCallback onTap) {
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

  Widget _buildStatusFilterBar() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildStatusChip(
            "Tous",
            _selectedStatus == null,
            () => setState(() => _selectedStatus = null),
          ),
          ...EPackageStatus.values.map(
            (s) => _buildStatusChip(
              s.label,
              _selectedStatus == s,
              () => setState(() => _selectedStatus = s),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    String label,
    bool isSelected,
    VoidCallback onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            onSelected();
            _resetAndReload();
          }
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

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _currentPage > 1
                ? () => _fetchPage(_currentPage - 1)
                : null,
            icon: const Icon(Icons.arrow_back_ios, size: 14),
            label: const Text("Précédent"),
          ),
          Text(
            "Page $_currentPage",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: _hasMore ? () => _fetchPage(_currentPage + 1) : null,
            label: const Text("Suivant"),
            icon: const Icon(Icons.arrow_forward_ios, size: 14),
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
            "Aucun colis trouvé",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
