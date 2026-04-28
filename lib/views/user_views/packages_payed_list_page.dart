import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/reusable_widgets/rw_dropdown.dart';
import 'package:delivery_app/reusable_widgets/rw_empty_packages.dart';
import 'package:delivery_app/reusable_widgets/rw_expandable_widget.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:delivery_app/views/user_views/package_payed_item_card.dart';
import 'package:flutter/material.dart';

class PackagesPayedListPage extends StatefulWidget {
  final String userId;

  const PackagesPayedListPage({super.key, required this.userId});

  @override
  State<PackagesPayedListPage> createState() => _PackagesPayedListPageState();
}

class _PackagesPayedListPageState extends State<PackagesPayedListPage> {
  final PackageDB _db = PackageDB();

  final Map<String, _CachedPage> _cache = {};
  final List<DocumentSnapshot?> _pageStarts = [null];
  List<PackageModel> _allPackages = [];

  Map<String, double>? _monthlyTotals;
  bool _isTotalsLoading = false;

  final List<String> _years = List.generate(
    5,
        (index) =>
        (DateTime
            .now()
            .year - index).toString(),
  );
  final List<String> _months = [
    "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
    "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre",
  ];

  late String _selectedYear;
  late String _selectedMonth;

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isDescending = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year.toString();
    _selectedMonth = _months[DateTime.now().month - 1];
    RefreshNotifier().refreshCounter.addListener(_resetAndReload);
  }

  @override
  void dispose() {
    RefreshNotifier().refreshCounter.removeListener(_resetAndReload);
    super.dispose();
  }

  void initDataIfNeeded() {
    if (!_isInitialized) {
      _fetchPage(1);
      _isInitialized = true;
    }
  }

  String _cacheKey(int page) =>
      '$_selectedYear|$_selectedMonth|$page|$_isDescending';

  Future<void> _fetchPage(int page) async {
    if (_isLoading) return;
    if (_monthlyTotals == null) _loadMonthlyTotals();

    final key = _cacheKey(page);
    if (_cache.containsKey(key) && !_cache[key]!.isExpired) {
      final hit = _cache[key]!;
      setState(() {
        _allPackages = hit.packages;
        _hasMore = hit.hasMore;
        _currentPage = page;
        _hasError = false;
      });
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      setState(() => _hasError = true);
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final snapshot = await _db.getPaidPackagesByDatePaged(
        userId: widget.userId,
        yearStr: _selectedYear,
        monthStr: _selectedMonth,
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

      setState(() {
        _allPackages = items;
        _hasMore = hasMore;
        _currentPage = page;
      });
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMonthlyTotals() async {
    setState(() => _isTotalsLoading = true);
    try {
      final totals = await _db.getPaidTotalsByMonth(
        userId: widget.userId,
        yearStr: _selectedYear,
        monthStr: _selectedMonth,
      );
      if (mounted) setState(() => _monthlyTotals = totals);
    } catch (e) {
      debugPrint("Error loading totals: $e");
    } finally {
      if (mounted) setState(() => _isTotalsLoading = false);
    }
  }

  void _resetAndReload() {
    if (!mounted) return;
    setState(() {
      _cache.clear();
      _pageStarts.clear();
      _pageStarts.add(null);
      _currentPage = 1;
      _monthlyTotals = null;
    });
    _fetchPage(1);
  }

  @override
  Widget build(BuildContext context) {
    initDataIfNeeded();
    return Scaffold(
      backgroundColor: DefaultColors.pagesBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 900;

          return Column(
            children: [
              const Text(
                "Colis Payées",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: DefaultColors.textPrimary,
                ),
              ),
              const SizedBox(height: 15),

              // 1. RW EXPANDABLE (Contient Header sur Mobile, Header + Table sur Web)
              RwExpandableWidget(
                child: isWideScreen
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildHeader(isWideScreen)),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildSummaryTable()),
                  ],
                )
                    : _buildHeader(isWideScreen),
              ),

              // 2. MODE MOBILE : Summary Table à l'extérieur (toujours visible)
              if (!isWideScreen)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSummaryTable(),
                ),

              const Divider(height: 1),

              // 3. LA LISTE (BODY)
              Expanded(
                child: _buildBody(),
              ),

              if (_allPackages.isNotEmpty) _buildPagination(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryTable() {
    if (_isTotalsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final count = _monthlyTotals?['count']?.toInt() ?? 0;
    final total = _monthlyTotals?['totalAmount'] ?? 0.0;
    final delivery = _monthlyTotals?['totalDelivery'] ?? 0.0;
    final net = _monthlyTotals?['net'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "RÉCAPITULATIF : $_selectedMonth $_selectedYear".toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.blueGrey),
            ),
          ),
          Table(
            border: TableBorder.all(color: Colors.grey.shade200, width: 1),
            children: [
              _buildTableRow("Total Colis", "$count", isBold: true),
              _buildTableRow("Contre remboursement", total.toStringAsFixed(3)),
              _buildTableRow(
                  "Frais Livraison", "- ${delivery.toStringAsFixed(3)}",
                  valueColor: Colors.red),
              _buildTableRow("NET À PAYER", net.toStringAsFixed(3),
                  valueColor: Colors.green, isLast: true),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String value,
      {bool isBold = false, Color? valueColor, bool isLast = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(label, style: TextStyle(fontSize: 11,
              fontWeight: isLast || isBold ? FontWeight.bold : FontWeight
                  .normal)),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w900,
                color: valueColor ?? DefaultColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mes paiements",
          style: TextStyle(fontSize: 22,
              fontWeight: FontWeight.bold,
              color: DefaultColors.textPrimary),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: RwDropdown(
                label: "Année",
                value: _selectedYear,
                items: _years,
                onChanged: (val) {
                  if (val != null && val != _selectedYear) {
                    setState(() => _selectedYear = val);
                    _resetAndReload();
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RwDropdown(
                label: "Mois",
                value: _selectedMonth,
                items: _months,
                onChanged: (val) {
                  if (val != null && val != _selectedMonth) {
                    setState(() => _selectedMonth = val);
                    _resetAndReload();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        RwDropdown(
          label: "Trier",
          value: _isDescending ? 'décroissant' : 'croissant',
          items: const ['décroissant', 'croissant'],
          itemLabelBuilder: (val) =>
          val == 'décroissant'
              ? "Plus récent"
              : "Plus ancien",
          onChanged: (String? newValue) {
            if (newValue != null) {
              bool newStatus = (newValue == 'décroissant');
              if (newStatus != _isDescending) {
                setState(() => _isDescending = newStatus);
                _resetAndReload();
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hasError) return const Center(child: Text("Erreur de chargement"));
    if (_allPackages.isEmpty) return const EmptyStateWidget();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _allPackages.length,
      itemBuilder: (_, i) => PackagePayedItemCard(package: _allPackages[i]),
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
            width: 100,
            child: _currentPage > 1
                ? TextButton(onPressed: () => _fetchPage(_currentPage - 1),
                child: const Text('Précédent'))
                : null,
          ),
          Expanded(
            child: Text('Page $_currentPage', textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 100,
            child: _hasMore
                ? TextButton(onPressed: () => _fetchPage(_currentPage + 1),
                child: const Text('Suivant'))
                : null,
          ),
        ],
      ),
    );
  }
}

class _CachedPage {
  final List<PackageModel> packages;
  final bool hasMore;
  final DateTime cachedAt;

  _CachedPage(
      {required this.packages, required this.hasMore, required this.cachedAt});

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > const Duration(minutes: 5);
}