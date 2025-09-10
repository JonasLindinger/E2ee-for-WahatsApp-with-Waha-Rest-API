import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:secure_messanger_app/main.dart';
import 'package:secure_messanger_app/screens/chat.dart';
import 'package:secure_messanger_app/widgets/ChatWidget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Chat> chats = [];

  @override
  void initState() {
    super.initState();
    HandleIncomingMessages();


  }

  void HandleIncomingMessages() {
    GetChats(defaultSessionName);
  }

  Future<void> GetChats(String sessionName) async {
    final url = serverURL + "/api/" + sessionName + "/chats/overview";
    final uri = Uri.parse(url);

    try {
      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      );

      final body = response.body;
      final json = jsonDecode(body);

      List<Chat> newChats = [];
      bool isFirst = true; // For testing
      for (final chat in json) {
        Chat newChat = new Chat();
        newChat.id = chat["id"];
        newChat.name = chat["name"];
        if (chat["picture"] != null)
          newChat.picture = chat["picture"]; // picture is a url
        if (chat["lastMessage"] != null)
          newChat.lastMessage = chat["lastMessage"];

        if (isFirst)
          print(chat["lastMessage"]);

        newChats.add(newChat);
        isFirst = false;
      }

      setState(() {
        chats = newChats;
      });
    } catch (e, st) {
      print("Something went wrong trying to get the status of a session: $e");
      print(st);
    }

    await Future.delayed(const Duration(seconds: 3));
    GetChats(sessionName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        title: const Text(
            "Chats",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28
          ),
        ),
      ),
      body: Container(
        margin: EdgeInsets.only(top: 20),
        child: ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) => ChatWidget(
            chat: chats[index],
            OpenChat: () => {
              OpenChat(chats[index])
            }
          )
        ),
      )
    );
  }

  void OpenChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(
        chat: chat,
        sessionName: defaultSessionName,
      ))
    );
  }
}
