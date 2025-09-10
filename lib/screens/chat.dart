import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:secure_messanger_app/main.dart';
import 'package:secure_messanger_app/widgets/MessageWidget.dart';

import '../widgets/ChatWidget.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  final String sessionName;

  const ChatScreen({
    super.key,
    required this.chat,
    required this.sessionName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Chat chat;
  late String sessionName;

  @override
  void initState() {
    super.initState();
    chat = widget.chat;
    sessionName = widget.sessionName;

    getMessages();
  }

  final TextEditingController messageController = TextEditingController();
  List<Message> messanges = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: chat.picture != "" ?
                  Image.network(
                    chat.picture,
                  ) :
                  Container(
                    color: Colors.green,
                  )
              ),
            ),
            SizedBox(
              width: 20,
            ),
            Text(
              chat.name,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18
              ),
            ),
          ],
        )
      ),
      body: Column(
        children: [
          // Display all messanges
          Expanded(
              child: BuildMessageList(),
          ),
          // User input
          BuildUserInput(),
        ],
      ),
    );
  }

  Widget BuildMessageList() {
    return ListView.builder(
        itemCount: messanges.length,
        itemBuilder: (context, index) =>
            MessageWidget(
                message: messanges[index]
            ),
    );
  }

  Widget BuildUserInput() {
    return Row(
      children: [
        // TextField
        Expanded(
          child: TextField(
            controller: messageController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Nachricht schreiben...",
            ),
            obscureText: false,
          )
        ),
        
        // Send button
        IconButton(
            onPressed: () => {
              sendMessage(messageController.text),
              messageController.clear(),
            }, 
            icon: Icon(Icons.arrow_upward)
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    final url = serverURL + "/api/sendText";
    final uri = Uri.parse(url);

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chatId": chat.id,
          "reply_to": null, // Todo
          "text": text, // Todo: encrypt
          "linkPreview": false, // Todo
          "linkPreviewHighQuality": false, // Todo
          "session": sessionName
        }),
      );

      final body = response.body;
      final json = jsonDecode(body);


    } catch (e, st) {
      print("Something went wrong trying to get the status of a session: $e");
      print(st);
    }
  }

  Future<void> getMessages() async {
    final url = serverURL + "/api/" + sessionName + "/chats/" + chat.id + "/messages";
    final uri = Uri.parse(url).replace(
      queryParameters: {
        "downloadMedia": "true", // Todo
        "chatId": chat.id.toString(),
        "limit": "20",
        "offset": "0", // Todo
        "session": sessionName,
      }
    );

    try {
      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body);

        for (final message in json) {
          Message newMessage = new Message();
          newMessage.id = message["id"];
          newMessage.timestamp = message["timestamp"];
          newMessage.from = message["from"];
          newMessage.fromMe = message["fromMe"];
          newMessage.to = message["to"];
          newMessage.message = message["body"];
          newMessage.hasMedia = message["hasMedia"];

          messanges.add(newMessage);
        }

        setState(() {

        });
      } else {
        debugPrint("getMessages failed: ${response.statusCode} ${response.body}");
      }

    } catch (e, st) {
      print("Something went wrong trying to get the chat messages$e");
      print(st);
    }
  }
}

