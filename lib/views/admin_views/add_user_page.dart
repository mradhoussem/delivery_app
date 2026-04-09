import 'package:delivery_app/firestore/models/m_user.dart';
import 'package:delivery_app/firestore/user_db.dart';
import 'package:delivery_app/reusable_widgets/rw_textview.dart';
import 'package:delivery_app/tools/default_colors.dart';
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
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final username = _nameController.text.trim();

      // Check uniqueness
      final exists = await _userRepo.checkUsernameExists(username);
      if (exists) {
        _showSnackBar("Ce nom d'utilisateur est déjà utilisé", Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // Create Model Instance
      final newUser = UserModel(
        id: '',
        // Firestore generates this
        username: username,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone1: _phone1Controller.text.trim(),
        phone2: _phone2Controller.text.trim(),
        role: 'user',
        createdAt: DateTime.now(),
      );

      // Save to DB
      await _userRepo.addUser(newUser, _passwordController.text);

      if (mounted) {
        _showSnackBar("Utilisateur ajouté !", Colors.green);
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      _showSnackBar("Erreur: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color col) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: col));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          "Nouveau Profil",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 25),

              RwTextview(
                controller: _nameController,
                hint: "Identifiant",
                prefixIcon: Icons.login,
                iconColor: DefaultColors.primary,
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 15),
              RwTextview(
                controller: _firstNameController,
                hint: "Prénom",
                prefixIcon: Icons.person_outline,
                iconColor: DefaultColors.primary,
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 15),
              RwTextview(
                controller: _lastNameController,
                hint: "Nom",
                prefixIcon: Icons.person,
                iconColor: DefaultColors.primary,
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 15),
              RwTextview(
                controller: _phone1Controller,
                hint: "Téléphone 1",
                textNumeric: true,
                prefixIcon: Icons.phone_iphone,
                iconColor: DefaultColors.primary,
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 15),

              RwTextview(
                controller: _phone2Controller,
                hint: "Téléphone 2 (Optionnel)",
                textNumeric: true,
                prefixIcon: Icons.phone_android,
                iconColor: DefaultColors.primary,
              ),
              const SizedBox(height: 15),

              RwTextview(
                controller: _passwordController,
                hint: "Mot de passe",
                isPassword: true,
                iconColor: DefaultColors.primary,
              ),
              const SizedBox(height: 15),

              RwTextview(
                controller: _confirmPasswordController,
                hint: "Confirmer",
                isPassword: true,
                iconColor: DefaultColors.primary,
                validator: (v) =>
                    v != _passwordController.text ? "Incohérent" : null,
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
                        color: DefaultColors.primary.withValues(alpha: 0.4),
                        offset: const Offset(6, 6),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "ENREGISTRER",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
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
