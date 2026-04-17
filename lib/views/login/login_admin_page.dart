import 'package:delivery_app/firestore/admin_db.dart';
import 'package:delivery_app/reusable_widgets/rw_textview.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/images_files.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginAdminPage extends StatefulWidget {
  const LoginAdminPage({super.key});

  @override
  State<LoginAdminPage> createState() => _LoginAdminPageState();
}

class _LoginAdminPageState extends State<LoginAdminPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({
    required String email,
    required String password,
  }) async {
    try {
      final isValid = await AdminDB().loginAdmin(
        email: email,
        password: password,
      );

      if (isValid) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_admin_logged_in', true);
        await prefs.setString('admin_email', email);

        if (mounted) {
          final snackBarController = ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Connexion réussie !"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
          await snackBarController.closed;
        }

        if (mounted) {
          if (mounted) {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/adminHome');
          }
        }
      } else {
        _showError("Email ou mot de passe incorrect");
      }
    } catch (e) {
      _showError("Erreur de connexion: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _validateAndSubmit() {
    if (_formKey.currentState!.validate()) {
      _handleLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.background,
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          alignment: Alignment.center,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Card(
                        color: DefaultColors.background,
                        elevation: 5,
                        shadowColor: DefaultColors.secondary.withValues(
                          alpha: 0.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          width: isMobile ? double.infinity : 450,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Accès Administrateur',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                    color: DefaultColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                RwTextview(
                                  controller: _emailController,
                                  hint: 'Email',
                                  isEmail: true,
                                  prefixIcon: Icons.email_rounded,
                                ),
                                const SizedBox(height: 15),
                                RwTextview(
                                  controller: _passwordController,
                                  hint: "Mot de passe",
                                  isPassword: true,
                                  onSubmitted: (_) =>
                                      _validateAndSubmit(), // Trigger on Enter
                                ),
                                const SizedBox(height: 30),
                                GestureDetector(
                                  onTap: _validateAndSubmit,
                                  child: Container(
                                    width: double.infinity,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: [
                                          DefaultColors.secondary.withValues(
                                            alpha: 0.7,
                                          ),
                                          DefaultColors.secondary,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: DefaultColors.secondary
                                              .withValues(alpha: 0.4),
                                          offset: const Offset(6, 6),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "SE CONNECTER",
                                        style: TextStyle(
                                          color: DefaultColors.pagesBackground,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/login'),
                                  child: const Text(
                                    "Continuer en tant qu'expéditeur",
                                    style: TextStyle(
                                      color: DefaultColors.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(30),
                      child: Image.asset(
                        ImagesFiles.logo2,
                        width: isMobile ? 200 : 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
