import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:dear_livery_app/screens/login_page.dart'; // Verifique se o caminho está correto

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dear-Livery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(), // Tela inicial de login
    );
  }
}
