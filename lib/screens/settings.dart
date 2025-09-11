import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background color of the whole screen
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)), // Text color for the title
        backgroundColor: Colors.black, // Background color of the header/AppBar
        foregroundColor: Colors.white, // Color for the back button and other icons
      ),
      body: const Center(
        child: Text(
          'Einstellungen',
          style: TextStyle(color: Colors.white), // Text color to be visible on black background
        ),
      ),
    );
  }
}