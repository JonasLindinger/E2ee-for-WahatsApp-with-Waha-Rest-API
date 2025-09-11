import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../main.dart';

class AppLifecycleHandler with WidgetsBindingObserver {
  static final AppLifecycleHandler _instance = AppLifecycleHandler._internal();

  factory AppLifecycleHandler() {
    return _instance;
  }

  AppLifecycleHandler._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _onAppClose();
    } else if (state == AppLifecycleState.paused) {
      _onAppBackground();
    }
  }

  void _onAppClose() {
    print("App is closing! (Global Handler)");
    // Do cleanup / save data here
  }

  void _onAppBackground() {
    print("App went to background! (Global Handler)");
    StopSession(defaultSessionName);
    SystemNavigator.pop(); // Close the app, because we shut down on the server!
    // Save state here
  }

  void StopSession(String sessionName) {
    final url = "$serverURL/api/sessions/$sessionName/stop";
    final uri = Uri.parse(url);

    print("StopSession: firing request to $url");

    // Fire & forget: we don't wait for it to finish
    http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({}),
    ).catchError((e) {
      print("StopSession failed: $e");
    });
  }
}