import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:visibility_detector/visibility_detector.dart'; // Import requis

class AdminScannerPage extends StatefulWidget {
  const AdminScannerPage({super.key});

  @override
  State<AdminScannerPage> createState() => _AdminScannerPageState();
}

class _AdminScannerPageState extends State<AdminScannerPage> {
  final PackageDB _db = PackageDB();
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    autoStart: false, // On gère le démarrage manuellement via VisibilityDetector
  );

  bool _isProcessing = false;
  PackageModel? _scannedPackage;
  EPackageStatus? _nextStatus;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String packageId) async {
    _controller.stop();
    try {
      final package = await _db.getPackageById(packageId);
      if (package == null) {
        _showSnackBar("Colis introuvable", isError: true);
        _controller.start();
        return;
      }

      EPackageStatus? next;
      if (package.status == EPackageStatus.waiting) {
        next = EPackageStatus.deposit;
      } else if (package.status == EPackageStatus.deposit) {
        next = EPackageStatus.progressing;
      } else if (package.status == EPackageStatus.progressing) {
        next = EPackageStatus.returnFromDeposit;
      } else if (package.status == EPackageStatus.returnFromDeposit) {
        next = EPackageStatus.progressing;
      }

      if (next != null) {
        setState(() {
          _scannedPackage = package;
          _nextStatus = next;
        });
      } else {
        _showSnackBar("Aucune action requise pour ce statut", isError: true);
        _controller.start();
      }
    } catch (e) {
      _showSnackBar("Erreur technique lors du scan", isError: true);
      _controller.start();
    }
  }

  Future<void> _confirmUpdate() async {
    if (_scannedPackage == null || _nextStatus == null) return;

    setState(() => _isProcessing = true);
    try {
      await _db.updateStatus(_scannedPackage!.id, _nextStatus!);
      RefreshNotifier().notifyRefresh();

      if (mounted) {
        _showSnackBar("Statut mis à jour : ${_nextStatus!.label}");
        // On réinitialise pour le prochain scan au lieu de faire un Navigator.pop
        // car cette page fait maintenant partie des onglets principaux
        setState(() {
          _scannedPackage = null;
          _nextStatus = null;
          _isProcessing = false;
        });
        _controller.start();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Erreur lors de la mise à jour", isError: true);
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double scannerSize = size.width < 600 ? size.width * 0.7 : 400;

    return VisibilityDetector(
      key: const Key('admin-scanner-key'),
      onVisibilityChanged: (visibilityInfo) {
        // Si l'onglet est visible à plus de 50%, on allume la caméra
        if (visibilityInfo.visibleFraction > 0.5) {
          _controller.start();
        } else {
          // Sinon (changement d'onglet ou app en background), on coupe
          _controller.stop();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            // Section Scanner
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && !_isProcessing) {
                        final String? code = barcodes.first.rawValue;
                        if (code != null) _handleScan(code);
                      }
                    },
                  ),
                  Container(
                    width: scannerSize,
                    height: scannerSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomDetailPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomDetailPanel() {
    if (_scannedPackage == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        color: Colors.white,
        child: const Text(
          "Scannez un QR code pour modifier le statut",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_scannedPackage!.firstName} ${_scannedPackage!.lastName}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  onPressed: () {
                    setState(() => _scannedPackage = null);
                    _controller.start();
                  },
                )
              ],
            ),
            Text("📍 ${_scannedPackage!.governorate.name}",
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            Row(
              children: [
                _statusChip(_scannedPackage!.status, Colors.grey),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.trending_flat, color: Colors.blue),
                ),
                _statusChip(_nextStatus!, DefaultColors.primary),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DefaultColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isProcessing ? null : _confirmUpdate,
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "CONFIRMER LA MISE À JOUR",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(EPackageStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.label.toUpperCase(),
        style:
        TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? DefaultColors.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}