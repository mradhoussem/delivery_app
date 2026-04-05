import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'init/init_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance
      .collection('users')
      .get()
      .then((value) => print("Firestore connected!"))
      .catchError((e) => print("Firestore error: $e"));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: DefaultColors.primary),
      ),
      home: const InitPage(),
    );
  }
}



