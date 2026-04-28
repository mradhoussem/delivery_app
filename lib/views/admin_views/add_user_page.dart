import 'package:delivery_app/firestore/models/m_user.dart';
import 'package:delivery_app/firestore/user_db.dart';
import 'package:delivery_app/reusable_widgets/rw_textview.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:flutter/material.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final UserDB _userRepo = UserDB();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // New
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _deliveryCostsController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose(); // New
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _deliveryCostsController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final username = _nameController.text.trim();

      final exists = await _userRepo.checkUsernameExists(username);
      if (exists) {
        _showSnackBar("Ce nom d'utilisateur est déjà utilisé", Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final newUser = UserModel(
        id: '',
        username: username,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text
            .trim()
            .isEmpty ? null : _emailController.text.trim(),
        phone1: _phone1Controller.text.trim(),
        phone2: _phone2Controller.text.trim(),
        role: 'user',
        deliveryCosts: double.tryParse(_deliveryCostsController.text.replaceAll(',', '.')) ?? 0.0,
        createdAt: DateTime.now(),
      );

      await _userRepo.addUser(newUser, _passwordController.text);

      if (mounted) {
        _showSnackBar("Utilisateur ajouté !", DefaultColors.success);
        RefreshNotifier().refreshCounter.value++;
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar("Erreur: $e", DefaultColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color col) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: col),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.pagesBackground,
      appBar: AppBar(
        title: const Text("Nouveau Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Informations de Connexion",
                style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              RwTextview(
                controller: _nameController,
                hint: "Identifiant",
                prefixIcon: Icons.login,
                iconColor: DefaultColors.primary,
                validator: (v) => v!.isEmpty ? "Requis" : null,
                maxLength: 256,
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: RwTextview(
                      controller: _firstNameController,
                      hint: "Prénom",
                      prefixIcon: Icons.person_outline,
                      iconColor: DefaultColors.primary,
                      validator: (v) => v!.isEmpty ? "Requis" : null,
                      maxLength: 256,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RwTextview(
                      controller: _lastNameController,
                      hint: "Nom",
                      prefixIcon: Icons.person,
                      iconColor: DefaultColors.primary,
                      validator: (v) => v!.isEmpty ? "Requis" : null,
                      maxLength: 256,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // --- EMAIL FIELD (OPTIONAL) ---
              RwTextview(
                controller: _emailController,
                hint: "Email (Optionnel)",
                isEmail: true,
                prefixIcon: Icons.email_outlined,
                iconColor: DefaultColors.primary,
                maxLength: 500,
              ),
              const SizedBox(height: 15),

              RwTextview(
                controller: _phone1Controller,
                hint: "Téléphone 1",
                textNumeric: true,
                prefixIcon: Icons.phone_iphone,
                iconColor: DefaultColors.primary,
                validator: (v) => v!.isEmpty ? "Requis" : null,
                maxLength: 8,
              ),
              const SizedBox(height: 15),

              RwTextview(
                controller: _phone2Controller,
                hint: "Téléphone 2 (Optionnel)",
                textNumeric: true,
                prefixIcon: Icons.phone_android,
                iconColor: DefaultColors.primary,
                maxLength: 8,
              ),
              const SizedBox(height: 15),

              RwTextview(
                controller: _deliveryCostsController,
                hint: "Frais de livraison par colis (TND)",
                textDouble: true,
                prefixIcon: Icons.local_shipping_outlined,
                iconColor: DefaultColors.primary,
                validator: (v) => v!.isEmpty ? "Requis" : null,
                maxLength: 20,
              ),
              const SizedBox(height: 15),

              RwTextview(
                controller: _passwordController,
                hint: "Mot de passe",
                isPassword: true,
                iconColor: DefaultColors.primary,
                validator: (v) => v!.length < 8 ? "Minimum 8 caractères" : null,
                minLength: 8,
                maxLength: 256,
              ),
              const SizedBox(height: 15),

              RwTextview(
                controller: _confirmPasswordController,
                hint: "Confirmer le mot de passe",
                isPassword: true,
                iconColor: DefaultColors.primary,
                validator: (v) => v != _passwordController.text ? "Incohérent" : null,
                minLength: 8,
                maxLength: 256,
              ),

              const SizedBox(height: 40),

              GestureDetector(
                onTap: _isLoading ? null : _saveUser,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        DefaultColors.primary.withValues(alpha: 0.7),
                        DefaultColors.primary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DefaultColors.primary.withValues(alpha: 0.3),
                        offset: const Offset(0, 8),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "ENREGISTRER LE PROFIL",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}