import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:secure_messanger_app/screens/main.dart';

class ChatWidget extends StatelessWidget {
  final Chat chat;
  final void Function()? OpenChat;

  const ChatWidget({
    super.key,
    required this.OpenChat,
    required this.chat,
  });

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
                        chat.lastMessage?['body'] ?? '',
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
}

class Chat {
  String id = "";
  String name = "";
  String picture = "";
  bool isGroupChat = false;
  Map<String, dynamic>? lastMessage;
}