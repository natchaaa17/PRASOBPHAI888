import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/dashboard_page.dart'; // เพิ่มบรรทัดนี้

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBp9_gwNtpoiIPoJJJSt1hSYQ1i1fqerTg",
      appId: "1:632567920434:web:f374b346e9d69c3d7d892b",
      messagingSenderId: "632567920434",
      projectId: "heart-link-3a50e",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const DashboardPage(), // แก้ตรงนี้
    );
  }
}