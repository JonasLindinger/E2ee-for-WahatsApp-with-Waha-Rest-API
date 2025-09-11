import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:crypto/crypto.dart';
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

  int newestMessageTimeStamp = 0;
  int oldestMessageTimeStamp = 0;
  bool isPulling = false;

  @override
  void initState() {
    super.initState();
    chat = widget.chat;
    sessionName = widget.sessionName;

    getMessages(); // Get's the current messages
    StartUpdate(); // Checks for new messages

    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        // cause a delay so that the keyboard has time to show up
        Future.delayed(const Duration(milliseconds: 500), () => {
        if (mounted)
          ScrollDown(),
        });
      }
    });

    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        // Load new messages
        if (!mounted) return; // State was disposed; abort.
        getOldMessages(); // gets the next old messages
      }
    });

    Future.delayed(
      const Duration(milliseconds: 500),
        () => ScrollDown(),
    );
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    messageController.dispose();
    super.dispose();
  }

  final TextEditingController messageController = TextEditingController();
  FocusNode myFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  List<Message> messanges = [];

  void ScrollDown() {
    scrollController.animateTo(
      scrollController.position.minScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

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
      reverse: true,
      itemCount: messanges.length,
      itemBuilder: (context, index) =>
        MessageWidget(
          message: messanges[index]
        ),
      controller: scrollController,
    );
  }

  Widget BuildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(left: 10),
            child: IconButton(
                onPressed: () => {
                  sendMessage(messageController.text),
                  messageController.clear(),
                },
                icon: Icon(Icons.account_circle_rounded, color: Colors.white)
            ),
          ),
          // TextField
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.black,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                style: TextStyle(
                  color: Colors.white,
                  decorationColor: Colors.white,
                ),
                controller: messageController,
                focusNode: myFocusNode,
                decoration: InputDecoration(
                  hintText: "Nachricht schreiben...",
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                obscureText: false,
              ),
            ),
          ),

          // Send button
          Container(
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 10, left: 10),
            child: IconButton(
              onPressed: () => {
                sendMessage(messageController.text),
                messageController.clear(),
              },
              icon: Icon(Icons.send_rounded, color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text == null) return;
    if (text.isEmpty) return;

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

      CheckForNewMessanges();

      ScrollDown();
    } catch (e, st) {
      print("Something went wrong trying to get the status of a session: $e");
      print(st);
    }
  }

  Future<void> SendGetMessagesAPI(Uri uri) async {
    if (isPulling) {
      await waitForCondition(
        () => !isPulling,
        pollInterval: const Duration(milliseconds: 50),
        timeout: const Duration(seconds: 10),
      );
    }

    isPulling = true;
    try {
      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      );

      if (!mounted) return; // State was disposed; abort.

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body);

        // Build the fetched messages list
        final List<Message> fetched = (json as List<dynamic>).map((message) {
          final m = Message();
          m.id = (message["id"] ?? "").toString();
          m.timestamp = (message["timestamp"] ?? 0) as int;
          m.from = (message["from"] ?? "").toString();
          m.fromMe = (message["fromMe"] ?? false) as bool;
          m.to = (message["to"] ?? "").toString();
          m.message = (message["body"] ?? "").toString();
          m.hasMedia = (message["hasMedia"] ?? false) as bool;
          if (m.hasMedia) {
            message["media"]["url"] = resolveMediaUrl(message["media"]["url"], serverURL);
          }
          m.media = (message["media"]);
          return m;
        }).toList();

        // Sort fetched batch by timestamp (newest -> oldest)
        fetched.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Deduplicate by id before merging
        final Set<String> existingIds = messanges.map((m) => m.id).toSet();
        bool updated = false;

        for (final m in fetched) {
          if (m.id.isEmpty) continue;

          // Check if the message has content to display or is just useless
          bool hasContent = false;
          if (m.hasMedia) hasContent = true;
          if (m.message.isNotEmpty) hasContent = true;

          // If the message has no content, it's useless and we don't display it.
          if (!hasContent) continue;

          if (m.timestamp > newestMessageTimeStamp) {
            newestMessageTimeStamp = m.timestamp;
          }
          if (oldestMessageTimeStamp == 0) {
            oldestMessageTimeStamp = m.timestamp;
          }
          if (m.timestamp < oldestMessageTimeStamp) {
            oldestMessageTimeStamp = m.timestamp;
          }

          if (!existingIds.contains(m.id)) {
            messanges.add(m);
            existingIds.add(m.id);
            updated = true;
          }
        }

        if (updated) {
          // Ensure the whole list is newest -> oldest
          messanges.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          setState(() {});
        }
      } else {
        debugPrint("getMessages failed: ${response.statusCode} ${response.body}");
      }
    } catch (e, st) {
      print("Something went wrong trying to get the chat messages$e");
      print(st);
    }

    isPulling = false;
  }

  Future<void> StartUpdate() async {
    if (!mounted) return; // State was disposed; abort.
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return; // State was disposed; abort.

    CheckForNewMessanges();

    StartUpdate();
  }

  Future<void> CheckForNewMessanges() async {
    final url = serverURL + "/api/" + sessionName + "/chats/" + chat.id + "/messages";
    final uri = Uri.parse(url).replace(
      queryParameters: {
        "downloadMedia": "true", // Todo
        "chatId": chat.id.toString(),
        "limit": "20",
        "filter.timestamp.gte": newestMessageTimeStamp.toString(),
        "session": sessionName,
      },
    );

    await SendGetMessagesAPI(uri);
  }

  Future<void> getMessages() async {
    final url = serverURL + "/api/" + sessionName + "/chats/" + chat.id + "/messages";
    final uri = Uri.parse(url).replace(
      queryParameters: {
        "downloadMedia": "true", // Todo
        "chatId": chat.id.toString(),
        "limit": "20",
        "offset": "0",
        "session": sessionName,
      },
    );

    await SendGetMessagesAPI(uri);
  }

  Future<void> getOldMessages() async {
    print("Pulling old: " + oldestMessageTimeStamp.toString() + " - " + newestMessageTimeStamp.toString());
    final url = serverURL + "/api/" + sessionName + "/chats/" + chat.id + "/messages";
    final uri = Uri.parse(url).replace(
      queryParameters: {
        "downloadMedia": "true", // Todo
        "chatId": chat.id.toString(),
        "limit": "20",
        "filter.timestamp.lte": oldestMessageTimeStamp.toString(),
        "session": sessionName,
      },
    );

    await SendGetMessagesAPI(uri);
  }

  String resolveMediaUrl(String rawUrl, String serverUrl) {
    final server = Uri.parse(serverUrl);
    Uri uri = Uri.parse(rawUrl);

    // Handle relative paths like "/files/img.jpg"
    if (!uri.hasScheme) {
      return server.resolve(rawUrl).toString();
    }

    // Rewrite localhost/loopback to your server host
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      uri = uri.replace(
        scheme: server.scheme,
        host: server.host,
        port: server.hasPort ? server.port : null,
      );
    }
    return uri.toString();
  }

  Future<void> waitForCondition(
      FutureOr<bool> Function() condition, {
        Duration pollInterval = const Duration(milliseconds: 50),
        Duration? timeout,
      }) async {
    final sw = Stopwatch()..start();
    while (true) {
      if (await condition()) return;
      if (timeout != null && sw.elapsed >= timeout) {
        throw TimeoutException('Condition not met within $timeout');
      }
      await Future.delayed(pollInterval);
    }
  }
}

