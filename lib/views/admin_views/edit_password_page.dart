import 'package:delivery_app/firestore/user_db.dart';
import 'package:delivery_app/reusable_widgets/rw_textview.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:flutter/material.dart';

class EditPasswordPage extends StatefulWidget {
  final String userId;
  final String userName;
  const EditPasswordPage({super.key, required this.userId, required this.userName});
  @override
  State<EditPasswordPage> createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _userRepo = UserDB();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController(); // Nouveau
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // On envoie le texte brut, UserDB s'occupera du hachage
      await _userRepo.updatePassword(
          widget.userId, _passController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Mot de passe mis à jour !")));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.pagesBackground,
      appBar: AppBar(title: Text("Modifier : ${widget.userName}"), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              RwTextview(
                controller: _passController,
                hint: "Nouveau mot de passe",
                isPassword: true,
                iconColor: DefaultColors.primary,
                validator: (v) => v!.length < 6 ? "Minimum 6 caractères" : null,
              ),
              const SizedBox(height: 15),
              RwTextview(
                controller: _confirmPassController,
                hint: "Confirmer le mot de passe",
                isPassword: true,
                iconColor: DefaultColors.primary,
                validator: (v) {
                  if (v != _passController.text)
                    return "Les mots de passe ne correspondent pas";
                  return null;
                },
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _isLoading ? null : _updatePassword,
                child: Container(
                  width: double.infinity, height: 55,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: DefaultColors.primary,
                      boxShadow: [
                        BoxShadow(
                            color: DefaultColors.primary.withValues(alpha: 0.3),
                            offset: const Offset(0, 5),
                            blurRadius: 10)
                      ]
                  ),
                  child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("METTRE À JOUR", style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))
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