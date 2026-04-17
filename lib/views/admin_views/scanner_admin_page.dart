import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/refresh_notifier.dart'; // Assure-toi que l'import est correct
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  );

  bool _isProcessing = false;
  PackageModel? _scannedPackage;
  EPackageStatus? _nextStatus;

  // Fonction pour convertir l'enum en Label lisible
  String _getStatusLabel(EPackageStatus status) {
    switch (status) {
      case EPackageStatus.waiting: return "En attente";
      case EPackageStatus.deposit: return "Au Dépôt";
      case EPackageStatus.returnFromDeposit: return "Retour Dépôt";
      case EPackageStatus.progressing: return "En Cours";
      case EPackageStatus.delivered: return "Livré";
      case EPackageStatus.payed: return "Payé";
      case EPackageStatus.permanentReturn: return "Retour Définitif";
      case EPackageStatus.returnReceived: return "Retour Reçu";
      default: return status.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double scannerSize = size.width < 600 ? size.width * 0.7 : 400;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Logistique"),
        backgroundColor: DefaultColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomDetailPanel(),
        ],
      ),
    );
  }

  Widget _buildBottomDetailPanel() {
    if (_scannedPackage == null) {
      return Container(
        padding: const EdgeInsets.all(30),
        child: const Text("En attente de scan...",
            style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
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
              style: const TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 15),

          Row(
            children: [
              _statusChip(_scannedPackage!.status, Colors.grey),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.double_arrow_rounded, size: 20, color: Colors.blue),
              ),
              _statusChip(_nextStatus!, Colors.blue),
            ],
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _isProcessing ? null : _confirmUpdate,
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text("PASSER À : ${_getStatusLabel(_nextStatus!).toUpperCase()}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _statusChip(EPackageStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        _getStatusLabel(status).toUpperCase(),
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
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
        _showSnackBar("Aucune action possible pour ce statut", isError: true);
        _controller.start();
      }
    } catch (e) {
      _showSnackBar("Erreur technique lors du scan", isError: true);
      _controller.start();
    }
  }

  Future<void> _confirmUpdate() async {
    setState(() => _isProcessing = true);
    try {
      await _db.updateStatus(_scannedPackage!.id, _nextStatus!);

      // Notification de rafraîchissement globale
      RefreshNotifier().notifyRefresh();

      _showSnackBar("Statut mis à jour avec succès");

      if (mounted) {
        // On attend un tout petit peu pour que le SnackBar soit visible avant le pop
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      _showSnackBar("Erreur lors de la mise à jour", isError: true);
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}