import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:secure_messanger_app/main.dart';
import 'package:http/http.dart' as http;

import 'ChatListScreen.dart';

class WahaConnectionScreen extends StatefulWidget {
  const WahaConnectionScreen({super.key});

  @override
  State<WahaConnectionScreen> createState() => _WahaConnectionScreenState();
}

class _WahaConnectionScreenState extends State<WahaConnectionScreen> {
  Uint8List? qrCodeBytes; // store the PNG bytes

  @override
  void initState() {
    super.initState();
    HandleSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
          child:
          qrCodeBytes == null ?
          const Text(
            "Loading...",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ) :
          Image.memory(qrCodeBytes!)
      ),
    );
  }

  void HandleSession() async {
    String sessionName = defaultSessionName;

    print("TryCreateSession");
    await TryCreateSession(sessionName);

    String status = await SessionStarted(sessionName);

    if (status == "SCAN_QR_CODE") {
      // Get QR-Code and display
      print("GetQRCode");
      await GetQRCode(sessionName);
    }

    // Load the messanger!
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChatListScreen())
    );
  }

  Future<void> TryCreateSession(String sessionName) async {
    final url = serverURL + "/api/sessions/";
    final uri = Uri.parse(url);

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": sessionName,
          "start": true,
        }),
      );

      await StartSession(sessionName);

      return;
    } catch (e, st) {
      print("Something went wrong trying to create a session: $e");
      print(st);
    }
  }

  Future<void> StartSession(String sessionName) async {
    final url = serverURL + "/api/sessions/" + sessionName + "/start";
    final uri = Uri.parse(url);

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({

        }),
      );

      final body = response.body;
      final json = jsonDecode(body);

      return;
    } catch (e, st) {
      print("Something went wrong trying to start a session: $e");
      print(st);
    }
  }

  Future<void> GetQRCode(String sessionName) async {
    final url = "$serverURL/api/$sessionName/auth/qr";
    final uri = Uri.parse(url);

    try {
      print("Requesting QR code!");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // If server sends base64 JSON, decode first

        // If server sends raw PNG bytes
        final bytes = response.bodyBytes;
        if (bytes == null) {
          // Error
          print("QR Code is not valid!");
        }
        else {
          setState(() {
            qrCodeBytes = bytes as Uint8List?;
          });

          await WaitForStatus(sessionName, "WORKING");
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching QR code: $e");
    }
  }

  Future<void> WaitForStatus(String sessionName, String status) async {
    await Future.delayed(const Duration(seconds: 3));

    final url = serverURL + "/api/sessions/" + sessionName;
    final uri = Uri.parse(url);

    try {
      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      );

      final body = response.body;
      final json = jsonDecode(body);

      if (json["status"] == status) {
        // We logged in!
        return;
      }
    } catch (e, st) {
      print("Something went wrong trying to get the status of a session: $e");
      print(st);
    }

    await WaitForStatus(sessionName, status);
  }

  Future<String> SessionStarted(String sessionName) async {
    final url = serverURL + "/api/sessions/" + sessionName;
    final uri = Uri.parse(url);

    try {
      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      );

      final body = response.body;
      final json = jsonDecode(body);

      String status = json["status"];
      switch (status) {
        case "WORKING":
          return status;
        case "SCAN_QR_CODE":
          return status;
      }
    } catch (e, st) {
      print("Something went wrong trying to get the status of a session: $e");
      print(st);
    }

    return SessionStarted(sessionName);
  }
}
