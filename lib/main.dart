import 'package:flutter/material.dart';
import 'package:secure_messanger_app/screens/connection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

late String serverURL;
const String defaultSessionName = "default";

void main() async {
  // Load .env
  await dotenv.load(fileName: ".env");

  // set variables from .env
  serverURL = dotenv.get("SERVER_IP_ADDRESS");

  // Run app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super (key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Secure Messanger App",
      home: const ConnectionScreen(),
    );
  }
}