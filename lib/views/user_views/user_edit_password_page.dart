import 'package:delivery_app/firestore/user_db.dart';
import 'package:delivery_app/reusable_widgets/rw_textview.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserEditPasswordPage extends StatefulWidget {
  const UserEditPasswordPage({super.key});

  @override
  State<UserEditPasswordPage> createState() => _UserEditPasswordPageState();
}

class _UserEditPasswordPageState extends State<UserEditPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final UserDB _userDb = UserDB();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      if (userId == null)
        throw Exception("Session expirée. Veuillez vous reconnecter.");

      // Utilisation de la méthode updatePassword de votre UserDB (hachage SHA-256 inclus)
      await _userDb.updatePassword(userId, _passwordController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mot de passe mis à jour avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
        _passwordController.clear();
        _confirmController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur : ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.pagesBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sécurité du compte",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Modifiez votre mot de passe pour sécuriser votre accès.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              RwTextview(
                controller: _passwordController,
                hint: "Nouveau mot de passe",
                prefixIcon: Icons.lock_outline,
                iconColor: DefaultColors.primary,
                isPassword: true,
                validator: (v) => v!.length < 6 ? "Minimum 6 caractères" : null,
              ),
              const SizedBox(height: 20),

              RwTextview(
                controller: _confirmController,
                hint: "Confirmer le mot de passe",
                prefixIcon: Icons.lock_reset,
                iconColor: DefaultColors.primary,
                isPassword: true,
                validator: (v) => v != _passwordController.text
                    ? "Les mots de passe ne correspondent pas"
                    : null,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpdate,
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
                          "METTRE À JOUR",
                          style: TextStyle(fontWeight: FontWeight.bold),
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
