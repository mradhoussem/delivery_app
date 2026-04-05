import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/tools/images_files.dart';
import 'package:flutter/material.dart';

import '../tools/default_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> addUserToFirestore({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    try {
      CollectionReference users = FirebaseFirestore.instance.collection(
        'users',
      );

      await users.add({
        'email': email,
        'password': password,
        // For testing only! Use Firebase Auth in real apps
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User added to Firestore!")));
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.background,

      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 700;
            return  Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        ImagesFiles.backgroundCar,
                        height: isMobile ? 200 : 450,
                      ),
                    ),
                  ),

                  // Card
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Card(
                        color: DefaultColors.background,
                        elevation: 5,
                        shadowColor: DefaultColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(30),
                          width: isMobile ? double.infinity : 500,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Votre colis, notre mission',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  color: DefaultColors.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 20),

                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  hintText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),

                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  hintText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              SizedBox(height: 30),

                              ElevatedButton(
                                onPressed: () {
                                  String email = _emailController.text.trim();
                                  String password = _passwordController.text;

                                  addUserToFirestore(
                                    email: email,
                                    password: password,
                                    context: context,
                                  );

                                  _emailController.clear();
                                  _passwordController.clear();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DefaultColors.primary,
                                  foregroundColor: DefaultColors.background,
                                  padding: EdgeInsets.all(25),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: 15,
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
                ],
              );
          },
        ),
      ),
    );
  }
}
