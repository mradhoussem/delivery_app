import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/reusable_widgets/rw_dropdown.dart';
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

  List<PackageModel> _packages = [];
  bool _isLoading = true;
  bool _isDescending = true;

  final List<String> _sortOptions = ['décroissant', 'croissant'];

  @override
  void initState() {
    super.initState();
    _fetchPackages();
    // Listen for global data changes via the singleton
    RefreshNotifier().refreshCounter.addListener(_fetchPackages);
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _phoneSearchController.dispose();
    RefreshNotifier().refreshCounter.removeListener(_fetchPackages);
    super.dispose();
  }

  Future<void> _fetchPackages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Clean inputs to avoid empty string issues
    final nameQuery = _userSearchController.text.trim();
    final phoneQuery = _phoneSearchController.text.trim();

    try {
      final snapshot = await _db.getAdminPackagesPaged(
        searchUsername: nameQuery,
        searchPhone: phoneQuery,
        descending: _isDescending,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _packages = snapshot.docs.map((doc) => doc.data()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Dual-Filter Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchSection(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading && _packages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _packages.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _fetchPackages,
              color: DefaultColors.primary,
              child: _buildPackageList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Flux Global des Colis",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          // Large, Full-Width Sort Dropdown
          SizedBox(
            width: double.infinity,
            child: RwDropdown(
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
                  _fetchPackages();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          RwTextview(
            controller: _userSearchController,
            label: "Nom de l'Utilisateur / Boutique",
            prefixIcon: Icons.storefront,
          ),
          const SizedBox(height: 10),
          RwTextview(
            controller: _phoneSearchController,
            label: "Numéro de Téléphone (Exact)",
            prefixIcon: Icons.phone_android,
          ),
          const SizedBox(height: 15),
          // --- Search & Refresh Action Button ---
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchPackages,
              style: ElevatedButton.styleFrom(
                backgroundColor: DefaultColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.search_rounded),
              label: const Text(
                "LANCER LA RECHERCHE",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _packages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return PackageItemCard(package: _packages[index],showSender: true,);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text(
            "Aucun résultat trouvé",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}