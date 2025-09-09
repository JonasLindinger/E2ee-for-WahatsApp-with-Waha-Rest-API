import 'dart:convert';

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final serverURL = "http://10.0.2.2:3000"; // localhost (for testing)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? qrCodeBytes; // store the PNG bytes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Messanger App"),
      ),
      body: Center(
        child: qrCodeBytes != null
            ? Image.memory(qrCodeBytes!)
            : const Text("No QR code yet"),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => {
            print("1"),
            StartConnection(),
          },
      ),
    );
  }

  void StartConnection() async {
    print("2");
    final defaultSessionName = "default"; // Todo: replace if needed...?
    await StartSession(defaultSessionName);
    await GetQRCode(defaultSessionName);
  }

  Future<void> StartSession(final sessionName) async {
    final url = serverURL + "/api/sessions/" + sessionName + "/start";
    final uri = Uri.parse(url);
    print("Starting session...");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      final body = response.body;
      final json = jsonDecode(body);

      if (json["status"] == "STARTING") {
        print("Session: " + sessionName + " started!");
      }
      else
        print("Something went wrong trying to start a session: " + response.statusCode.toString() + " -> " + response.body);
    } catch (e, st) {
      print("Something went wrong trying to start a session: " + e.toString());
      print(st);
    }
  }

  Future<void> GetQRCode(final session) async {
    final url = serverURL + "/api/" + session + "/auth/qr";
    final uri = Uri.parse(url);

    try {
      print("Requesting QR code!");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // If server sends base64 JSON, decode first
        // final json = jsonDecode(response.body);
        // final base64String = json['image']; // adjust key if needed
        // qrCodeBytes = base64Decode(base64String);

        // If server sends raw PNG bytes
        qrCodeBytes = response.bodyBytes;

        setState(() {});
        print("Got QR code!");
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching QR code: $e");
    }
  }
}