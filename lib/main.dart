import 'package:flutter/material.dart';
import 'package:secure_messanger_app/screens/connection.dart';

const serverURL = "http://10.0.2.2:3000"; // localhost (for testing)

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super (key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Secure Messanger App",
      home: const ConnectionScreen(),
    );
  }
}