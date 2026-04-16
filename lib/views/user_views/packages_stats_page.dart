import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:flutter/material.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/reusable_widgets/rw_flip_card.dart';

class PackagesStatsPage extends StatefulWidget {
  final String userId;

  const PackagesStatsPage({super.key, required this.userId});

  @override
  State<PackagesStatsPage> createState() => _PackagesStatsPageState();
}

class _PackagesStatsPageState extends State<PackagesStatsPage> {
  final PackageDB _db = PackageDB();
  Map<EPackageStatus, int> _counts = {};
  int _totalCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Listen for global refreshes
    RefreshNotifier().refreshCounter.addListener(_loadStats);
    _loadStats();
  }

  @override
  void dispose() {
    RefreshNotifier().refreshCounter.removeListener(_loadStats);
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Statistiques Détaillées",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 15,
          runSpacing: 15,
          children: [
            // Total Card with specific colors requested
            RwFlipCard(
              title: "Total Expéditions",
              value: _totalCount.toString(),
              gradientColors: [Colors.lightGreen, Colors.lightBlueAccent],
              onTap: () => (),
            ),

            // Status Cards mapped dynamically
            ...EPackageStatus.values.map(
              (status) => RwFlipCard(
                title: status.label,
                value: (_counts[status] ?? 0).toString(),
                gradientColors: status.gradientColors,
                // Now using the extension property
                onTap: () => (),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
