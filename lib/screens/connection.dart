import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:secure_messanger_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'main.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
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
          const Text( // Todo: Make animation instead of Loading text
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
    if (await IsValidSession(sessionName)) {
      // Everything is fine, we join the session
    }
    else {
      await CheckSessionAndCreateASessionIfNecessary(sessionName);
    }

    if (!await IsValidSession(sessionName)) {
      // Reactivate the session (we should still be logged in!)
      await StartSession(sessionName);

      if (await CheckSessionAndIfThereIsANeedToLogin(sessionName)) {
        // We need to login!
        await GetQRCode(sessionName);
      }
    }

    if (await IsValidSession(sessionName)) {
      // Everything is working!
    }
    else {
      // Session isn't working...
      print("Error while logging in");
    }

    // Load the messanger!
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen())
    );
  }

  Future<void> CheckSessionAndCreateASessionIfNecessary(String sessionName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    const SessionNamePreference = "SESSIONNAME";
    final session = prefs.getString(SessionNamePreference);

    if (session == null) {
      // Create Session
      await CreateSession(sessionName);
      await GetQRCode(sessionName);

      // Save the session name
      prefs.setString(SessionNamePreference, sessionName);
    }
    else {
      // Join Session
      print("Session should still be working!");
    }
  }

  Future<void> CreateSession(String sessionName) async {
    final url = serverURL + "/api/sessions/";
    final uri = Uri.parse(url);
    print("Creating session...");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": sessionName,
          "start": true,
        }),
      );

      final body = response.body;
      final json = jsonDecode(body);

      await waitForStatus(sessionName, "SCAN_QR_CODE");

      print("Created Session!");
    } catch (e, st) {
      print("Something went wrong trying to create a session: $e");
      print(st);
    }
  }

  Future<void> StartSession(String sessionName) async {
    final url = serverURL + "/api/sessions/" + sessionName + "/start";
    final uri = Uri.parse(url);
    print("Starting session...");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({

        }),
      );

      final body = response.body;
      final json = jsonDecode(body);

      print("Created Session!");
    } catch (e, st) {
      print("Something went wrong trying to create a session: $e");
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
        // final json = jsonDecode(response.body);
        // final base64String = json['image']; // adjust key if needed
        // final bytes = base64Decode(base64String);

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

          await waitForStatus(sessionName, "WORKING");
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching QR code: $e");
    }
  }

  Future<void> waitForStatus(String sessionName, String status) async {
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

    await waitForStatus(sessionName, status);
  }

  Future<bool> CheckSessionAndIfThereIsANeedToLogin(String sessionName) async {
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

      if (json["status"] == "WORKING") {
        // We logged in!
        return false;
      }
      else if (json["status"] == "SCAN_QR_CODE"){
        // We have to login!
        return true;
      }
    } catch (e, st) {
      print("Something went wrong trying to get the status of a session: $e");
      print(st);
    }

    return await CheckSessionAndIfThereIsANeedToLogin(sessionName);
  }

  Future<bool> IsValidSession(String sessionName) async {
    final url = serverURL + "/api/sessions/" + sessionName;
    final uri = Uri.parse(url);

    try {
      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      );

      final body = response.body;
      final json = jsonDecode(body);

      if (json["status"] == "WORKING") {
        // We logged in!
        return true;
      }
    } catch (e, st) {
      print("Something went wrong trying to get the status of a session: $e");
      print(st);
    }
    return false;
  }
}
