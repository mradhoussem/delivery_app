import 'package:delivery_app/dialogs/rd_print_save_package.dart';
import 'package:delivery_app/firestore/enums/e_governorate.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/reusable_widgets/rw_dropdown.dart';
import 'package:delivery_app/reusable_widgets/rw_textview.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddPackagePage extends StatefulWidget {
  const AddPackagePage({super.key});

  @override
  State<AddPackagePage> createState() => _AddPackagePageState();
}

class _AddPackagePageState extends State<AddPackagePage> {
  final _formKey = GlobalKey<FormState>();
  final PackageDB _db = PackageDB();

  final TextEditingController _fNameController = TextEditingController();
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _productDesignationController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  String? _selectedGov = EGovernorate.tunis.name;
  bool _isExchange = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _productDesignationController.dispose();
    _designationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');
      final String? username = prefs.getString('username');
      final String? taxId = prefs.getString('tax_id'); // <--- RETRIEVE TAX ID

      if (userId == null || username == null) {
        throw Exception('Session expirée.');
      }

      final newPackage = PackageModel(
        id: '',
        firstName: _fNameController.text.trim(),
        lastName: _lNameController.text.trim(),
        phone1: _phone1Controller.text.trim(),
        phone2: _phone2Controller.text.trim().isEmpty ? null : _phone2Controller.text.trim(),
        governorate: EGovernorateExtension.fromName(_selectedGov!),
        address: _addressController.text.trim(),
        amount: double.parse(_amountController.text.trim().replaceAll(',', '.')),
        deliveryCost: 0.0,
        isExchange: _isExchange,
        productDesignation: _productDesignationController.text.trim().isEmpty
            ? null
            : _productDesignationController.text.trim(),
        packageDesignation: _isExchange ? _designationController.text.trim() : null,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        status: EPackageStatus.waiting,
        createdAt: DateTime.now(),
        creatorUserId: userId,
        creatorUsername: username,
        creatorTaxId: taxId ?? '', // <--- PASS TAX ID TO MODEL
      );

      final docRef = await _db.addPackage(package: newPackage, userId: userId);
      final savedPackage = newPackage.copyWith(id: docRef.id);

      if (mounted) {
        RefreshNotifier().notifyRefresh();
        setState(() => _isLoading = false);
        RdPrintSavePackage.show(
          context,
          savedPackage,
          doublePopNavigation: true,
          isAddingPackage: true,
          isDismissible: false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.pagesBackground,
      appBar: AppBar(
        title: const Text(
          'Nouvelle Expédition',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('DESTINATAIRE'),
              Row(
                children: [
                  Expanded(
                    child: RwTextview(
                      controller: _fNameController,
                      hint: 'Prénom',
                      prefixIcon: Icons.person_outline,
                      iconColor: DefaultColors.primary,
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RwTextview(
                      controller: _lNameController,
                      hint: 'Nom',
                      prefixIcon: Icons.person,
                      iconColor: DefaultColors.primary,
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              RwTextview(
                controller: _phone1Controller,
                hint: 'Téléphone 1',
                textNumeric: true,
                prefixIcon: Icons.phone_iphone,
                iconColor: DefaultColors.primary,
                maxLength: 8,
                minLength: 8,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 15),
              RwTextview(
                controller: _phone2Controller,
                hint: 'Téléphone 2 (Optionnel)',
                textNumeric: true,
                prefixIcon: Icons.phone_android,
                iconColor: DefaultColors.primary,
                maxLength: 8,
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('LIVRAISON'),
              RwDropdown(
                value: _selectedGov,
                items: EGovernorate.values.map((e) => e.name).toList(),
                itemLabelBuilder: (name) => EGovernorateExtension.fromName(name).label,
                onChanged: (val) => setState(() => _selectedGov = val),
              ),
              const SizedBox(height: 15),
              RwTextview(
                controller: _addressController,
                hint: 'Adresse exacte',
                prefixIcon: Icons.location_on_outlined,
                iconColor: DefaultColors.primary,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 15),
              RwTextview(
                controller: _productDesignationController,
                hint: 'Désignation du produit (Ex: Chaussures)',
                prefixIcon: Icons.shopping_bag_outlined,
                iconColor: DefaultColors.primary,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 15),
              RwTextview(
                controller: _amountController,
                hint: 'Montant à collecter (TND)',
                textDouble: true,
                prefixIcon: Icons.payments_outlined,
                iconColor: DefaultColors.primary,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 25),
              _buildExchangeSection(),
              const SizedBox(height: 15),
              RwTextview(
                controller: _commentController,
                hint: 'Remarque',
                prefixIcon: Icons.textsms_outlined,
                iconColor: DefaultColors.primary,
              ),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _buildExchangeSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Échange de colis',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            value: _isExchange,
            activeThumbColor: DefaultColors.primary,
            onChanged: (val) => setState(() {
              _isExchange = val;
              if (!val) _designationController.clear();
            }),
          ),
          if (_isExchange)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: RwTextview(
                controller: _designationController,
                hint: 'Que doit-on récupérer ?',
                prefixIcon: Icons.inventory_2_outlined,
                iconColor: DefaultColors.primary,
                validator: (v) => (_isExchange && v!.isEmpty) ? 'Requis' : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: DefaultColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          "CONFIRMER L'EXPÉDITION",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}