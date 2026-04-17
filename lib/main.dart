import 'package:delivery_app/auth_security/user_guard.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/views/admin_views/admin_home_page.dart';
import 'package:delivery_app/views/login/login_admin_page.dart';
import 'package:delivery_app/views/login/login_page.dart';
import 'package:delivery_app/views/user_views/user_home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'auth_security/admin_guard.dart';
import 'firestore/firebase_options.dart';
import 'init/init_page.dart';

// Custom Scroll Behavior to enable Mouse Dragging on Web/Desktop
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Apply the scroll behavior globally
      scrollBehavior: MyCustomScrollBehavior(),
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
        '/Home': (context) => const UserGuard(child: UserHomePage()),
        '/adminHome': (context) => const AdminGuard(child: AdminHomePage()),
        '/userHomePage': (context) => const UserGuard(child: UserHomePage()),
      },
    );
  }
}