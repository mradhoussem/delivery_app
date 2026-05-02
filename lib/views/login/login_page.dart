import 'package:delivery_app/firestore/user_db.dart';
import 'package:delivery_app/reusable_widgets/rw_textview.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/images_files.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingAdminSession().then((isAdmin) {
      if (!isAdmin) {
        _checkExistingSession();
      }
    });
  }

  Future<bool> _checkExistingAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    bool isAdminLoggedIn = prefs.getBool('is_admin_logged_in') ?? false;

    if (isAdminLoggedIn && mounted) {
      Navigator.pushReplacementNamed(context, '/adminHome');
      return true;
    }
    return false;
  }

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    bool isUserLoggedIn = prefs.getBool('is_user_logged_in') ?? false;

    if (isUserLoggedIn && mounted) {
      Navigator.pushReplacementNamed(context, '/userHomePage');
    }
  }

  Future<void> _handleUserLogin({
    required String username,
    required String password,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final UserDB userRepo = UserDB();

      final user = await userRepo.loginUser(
        username: username,
        password: password,
      );

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_user_logged_in', true);
        await prefs.setString('user_id', user.id);
        await prefs.setString('username', user.username);
        await prefs.setString('tax_id', user.taxId);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/userHomePage');
        }
      } else {
        _showError("Identifiant ou mot de passe incorrect");
      }
    } catch (e) {
      _showError("Erreur de connexion : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _validateAndSubmit() {
    if (_formKey.currentState!.validate()) {
      _handleUserLogin(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                      child: Image.asset(
                        ImagesFiles.logo,
                        width: isMobile ? 250 : 500,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Card(
                        color: DefaultColors.background,
                        elevation: 5,
                        shadowColor: DefaultColors.primary.withValues(alpha: 0.3),
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
                                  'Espace Expéditeur',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                    color: DefaultColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                RwTextview(
                                  controller: _usernameController,
                                  hint: 'Identifiant',
                                  prefixIcon: Icons.person_outline,
                                  validator: (v) => v!.isEmpty ? "Identifiant requis" : null,
                                ),
                                const SizedBox(height: 15),
                                RwTextview(
                                  controller: _passwordController,
                                  hint: "Mot de passe",
                                  isPassword: true,
                                  validator: (v) => v!.isEmpty ? "Mot de passe requis" : null,
                                  onSubmitted: (_) => _validateAndSubmit(),
                                ),
                                const SizedBox(height: 30),
                                GestureDetector(
                                  onTap: _isLoading
                                      ? null
                                      : () => _handleUserLogin(
                                    username: _usernameController.text.trim(),
                                    password: _passwordController.text,
                                  ),
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
                                          ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : const Text(
                                        "SE CONNECTER",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Accès réservé ? "),
                                    Flexible(
                                      child: TextButton(
                                        onPressed: () => Navigator.pushNamed(context, '/loginAdmin'),
                                        child: const Text(
                                          "Session administrateur",
                                          style: TextStyle(
                                            color: DefaultColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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