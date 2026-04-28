import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/reusable_widgets/rw_statistic_card.dart';
import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:flutter/material.dart';

class PackagesStatsPage extends StatefulWidget {
  final String userId;
  final Function(int, {String? status}) onNavigate;

  const PackagesStatsPage({
    super.key,
    required this.userId,
    required this.onNavigate,
  });

  @override
  State<PackagesStatsPage> createState() => _PackagesStatsPageState();
}

class _PackagesStatsPageState extends State<PackagesStatsPage> {
  final PackageDB _db = PackageDB();
  Map<EPackageStatus, int> _counts = {};
  int _totalCount = 0;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    RefreshNotifier().refreshCounter.addListener(_loadStats);
  }

  @override
  void dispose() {
    RefreshNotifier().refreshCounter.removeListener(_loadStats);
    super.dispose();
  }

  void initDataIfNeeded() {
    if (!_isInitialized) {
      _loadStats();
      _isInitialized = true;
    }
  }

  Future<void> _loadStats() async {
    if (_isLoading && _isInitialized) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      // Exécution parallèle des comptes par statut pour optimiser le temps
      final results = await Future.wait([
        _db.getPackageCountByStatus(userId: widget.userId),
        ...EPackageStatus.values.map(
              (s) => _db.getPackageCountByStatus(
            userId: widget.userId,
            status: s.name,
          ),
        ),
      ]);

      if (mounted) {
        setState(() {
          _totalCount = results[0];
          _counts = {
            for (int i = 0; i < EPackageStatus.values.length; i++)
              EPackageStatus.values[i]: results[i + 1],
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur Stats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      initDataIfNeeded();
    }

    if (_isLoading && _totalCount == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Statistiques Détaillées",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 15,
          runSpacing: 15,
          children: [
            ...EPackageStatus.values.map(
                  (status) => RwStatisticCard(
                title: status.label,
                value: (_counts[status] ?? 0).toString(),
                gradientColors: status.gradientColors,
                onTap: () {
                  // MAPPING : Détermine l'onglet cible et le filtre éventuel
                  int targetIndex = 1; // Par défaut : Mes Colis (PackagesListPage)
                  String? filter;

                  if (status == EPackageStatus.waiting) {
                    targetIndex = 2; // PackagesWaitingListPage
                  } else if (status == EPackageStatus.payed) {
                    targetIndex = 3; // PackagesPayedListPage
                  } else if (status == EPackageStatus.returnReceived ||
                      status == EPackageStatus.permanentReturn) {
                    targetIndex = 4; // PackagesReceivedListPage
                  } else {
                    // Pour les autres statuts, on va sur la liste globale avec filtre
                    targetIndex = 1;
                    filter = status.name;
                  }

                  widget.onNavigate(targetIndex, status: filter);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}