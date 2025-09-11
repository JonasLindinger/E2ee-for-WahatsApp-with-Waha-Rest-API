import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:secure_messanger_app/main.dart';
import 'package:secure_messanger_app/screens/chat.dart';
import 'package:secure_messanger_app/widgets/ChatWidget.dart';

import '../widgets/center_circle.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Chat> chats = [];

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    HandleIncomingMessages(defaultSessionName);

    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        if (!mounted) return; // State was disposed; abort.

        // Load new messages
        getChats(defaultSessionName, false);
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void HandleIncomingMessages(String sessionName) async {
    Update(true, sessionName);
  }

  bool _isFetchingChats = false;

  Future<void> getChats(String sessionName, bool isUpdate) async {
    if (_isFetchingChats) return;
    _isFetchingChats = true;

    final url = '$serverURL/api/$sessionName/chats/overview';
    final uri = Uri.parse(url).replace(
      queryParameters: {
        "offset": (isUpdate ? 0 : chats.length).toString(),
      }
    );

    try {
      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      );

      if (!mounted) return; // State was disposed; abort.

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Create Chat objects
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

        final List<Chat> fetched = data.map<Chat>((chat) {
          final c = Chat();
          c.id = chat["id"];
          c.name = chat["name"];
          if (chat["picture"] != null) c.picture = chat["picture"]; // url
          if (chat["lastMessage"] != null) c.lastMessage = chat["lastMessage"];
          return c;
        }).toList();

        // Merge into existing list by id
        final Map<String, int> indexById = {
          for (int i = 0; i < chats.length; i++)
            ((chats[i].id ?? '').toString()): i
        };

        bool changed = false;

        for (final c in fetched) {
          final id = (c.id ?? '').toString();
          if (id.isEmpty) continue;

          final existingIndex = indexById[id];
          if (existingIndex != null) {
            // Update the existing chat
            final existing = chats[existingIndex];
            existing.name = c.name;
            existing.picture = c.picture;
            existing.lastMessage = c.lastMessage;
            changed = true;
          } else {
            chats.add(c);
            changed = true;
          }
        }

        // Get Groups
        var groups = await GetGroups(sessionName, chats.length);
        if (groups != null) {
          List<String> groupIds = [];

          for (var group in groups) {
            groupIds.add(group["groupMetadata"]["id"]["_serialized"]);
          }

          for (final chat in chats) {
            if (groupIds.contains(chat.id)) {
              chat.isGroupChat = true;
            }
          }
        }

        if (changed) {
          // Keep global list newest -> oldest
          setState(() {});
        }
      } else {
        debugPrint("getChats failed: ${response.statusCode} ${response.body}");
      }
    } catch (e, st) {
      print("Something went wrong trying to get the chats overview: $e");
      print(st);
    } finally {
      _isFetchingChats = false;
    }
  }

  Future<void> Update(bool loop, String sessionName) async {
    if (!mounted) return; // State was disposed; abort.
    if (loop && chats.length != 0) await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return; // State was disposed; abort.

    await getChats(sessionName, true);

    if (loop) Update(loop, sessionName);
  }

  Future<dynamic> GetGroups(String sessionName, int limit) async {
    final url = '$serverURL/api/$sessionName/groups';
    final uri = Uri.parse(url).replace(
      queryParameters: {
        "limit": limit.toString(),
      }
    );

    try {
      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      );

      if (!mounted) return; // State was disposed; abort.

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body;
        final json = jsonDecode(body);

        return json;
      } else {
        debugPrint("getChats failed: ${response.statusCode} ${response.body}");
      }
    } catch (e, st) {
      print("Something went wrong trying to get the chats overview: $e");
      print(st);
    } finally {
      _isFetchingChats = false;
    }
    return null;
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
            fontSize: 28,
          ),
        ),
      ),
      body: Stack( // Das Stack-Widget ist der Schlüssel zur Überlagerung von Widgets
        children: [
          // Dein ListView.builder, der den Hauptinhalt darstellt
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: ListView.builder(
              controller: scrollController,
              itemCount: chats.length,
              itemBuilder: (context, index) => ChatWidget(
                chat: chats[index],
                OpenChat: () => OpenChat(chats[index]),
              ),
            ),
          ),
        // Dein CenterCircle-Widget, das oben drauf positioniert wird
          CenterCircle(
            color: Colors.green,
            icon: Icons.add,
            height: 60,
            width: 60,
          ),
        ],
      ),
    );
  }



  void OpenChat(Chat chat) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
            chat: chat,
            sessionName: defaultSessionName,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0); // start from bottom
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeInOutQuint);

          return SlideTransition(
            position: tween.animate(curvedAnimation),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 600),
      ),
    );
  }
}
