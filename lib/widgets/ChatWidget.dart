import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:secure_messanger_app/screens/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/chat.dart';
import '../utils/ChatConnection.dart';
import '../utils/RSAUtils.dart';

class ChatListWidget extends StatefulWidget {
  final Chat chat;
  final void Function()? OpenChat;

  const ChatListWidget({
    super.key,
    required this.OpenChat,
    required this.chat,
  });

  @override
  State<ChatListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<ChatListWidget> {
  String latestMessage = "";

  late Chat chat;
  late void Function()? OpenChat;

  @override
  void initState() {
    super.initState();

    chat = widget.chat;
    OpenChat = widget.OpenChat;

    LoadAndFormatLatestMessage();
  }

  // Dart
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, // your item height
      width: double.infinity, // fill horizontal space
      child: TextButton(
        onPressed: OpenChat,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ).copyWith(
          overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: Hero(
                  tag: '${chat.id}-image',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: chat.picture != ''
                        ? Image.network(chat.picture)
                        : Container(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.name,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        latestMessage,
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        softWrap: true,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> LoadAndFormatLatestMessage() async {
    String message = chat.lastMessage?["body"] ?? "";

    SharedPreferences prefs = await SharedPreferences.getInstance();

    var rawKeys = prefs.getString(chatPrefPrefix + chat.id);
    if (rawKeys == null) {
      setState(() {
        latestMessage = message;
      });
      return;
    }

    List<String> keys = ChatConnection.decodeKeys(rawKeys!);

    if (message.contains(encryptedMessagePrefix)) {
      // Found an encrypted message!
      message = message.replaceFirst(encryptedMessagePrefix, "");

      if (keys.isNotEmpty) {
        // decode the message
        RSAPrivateKey privateKey = RSAUtils.privateKeyFromString(keys[1]);

        message = RSAUtils.decryptHybridFromString(message, privateKey);
      }
      else {
        message = "Encrypted Message";
      }
    }
    else if (message.contains(chatKeysMessagePrefix)) {
      message = "Encryption established.";
    }
    else if (message.contains(personalPublicKeyPrefix)) {
      message = "Trying to establish encryption.";
    }

    setState(() {
      latestMessage = message;
    });
  }
}

class Chat {
  String id = "";
  String name = "";
  String picture = "";
  bool isGroupChat = false;
  Map<String, dynamic>? lastMessage;
}