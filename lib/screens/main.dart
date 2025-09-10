import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:secure_messanger_app/main.dart';
import 'package:secure_messanger_app/screens/chat.dart';

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
          itemBuilder: (context, index) =>
            GestureDetector(
              onTap: OpenChat,
              child: Container(
                width: 350,
                height: 70,
                margin: EdgeInsets.only(top: 5, bottom: 5, right: 10, left: 10),
                child: Container (child: Row(
                  children: [
                    Container(
                      // Do the Image
                      width: 50,
                      height: 50,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: chats[index].picture != "" ?
                          Image.network(
                            chats[index].picture,
                          ) :
                          Container(
                            color: Colors.green,
                          )
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 30),
                        height: 50,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chats[index].name,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white
                              ),
                            ),
                            SizedBox(
                              height: 1,
                            ),
                            Text(
                              chats[index].lastMessage?["body"] ?? "",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey
                              ),
                              softWrap: true,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              ),
            )
          ),
        ),
      )
    );
  }

  void OpenChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen())
    );
  }
}

class Chat {
  String id = "";
  String name = "";
  String picture = "";
  Map<String, dynamic>? lastMessage;
}
