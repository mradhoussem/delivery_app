import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/auth_security/user_guard.dart';
import 'package:delivery_app/login/login_admin_page.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/views/admin_views/add_user_page.dart';
import 'package:delivery_app/views/admin_views/admin_home_page.dart';
import 'package:delivery_app/views/user_views/user_home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'auth_security/admin_guard.dart';
import 'firestore/firebase_options.dart';

// Import your pages here
import 'init/init_page.dart';
import 'login/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Quick connectivity check
  FirebaseFirestore.instance
      .collection('users')
      .limit(1)
      .get()
      .then((value) => debugPrint("Firestore connected!"))
      .catchError((e) => debugPrint("Firestore error: $e"));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: DefaultColors.background),
        useMaterial3: true,
      ),

      // 1. Define the initial route (where the app starts)
      initialRoute: '/',

      // 2. Define the route map
      routes: {
        '/': (context) => const InitPage(),
        '/login': (context) => const LoginPage(),
        '/loginAdmin': (context) => const LoginAdminPage(),
        '/Home': (context) => const AdminGuard(child: UserHomePage()),
        '/adminHome': (context) => const AdminGuard(child: AdminHomePage()),
        '/addUser': (context) => const AdminGuard(child: AddUserPage()),
        '/userHomePage': (context) => const UserGuard(child: UserHomePage()),

      },
    );
  }
}
