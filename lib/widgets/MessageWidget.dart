import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MessageWidget extends StatelessWidget {
  final Message message;

  const MessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = message.fromMe;
    final alignment =
    isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment, // position the bubble left/right
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // limit width so long texts wrap; short texts keep minimal size
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.green : Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isCurrentUser ? 12 : 0),
              bottomRight: Radius.circular(isCurrentUser ? 0 : 12),
            ),
          ),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
          // Remove alignment here so the container sizes to its child
          child: Text(
            message.message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class Message {
  String id = "";
  int timestamp = 0;
  String from = "";
  bool fromMe = false;
  String to = "";
  String message = "";
  bool hasMedia = false;
  // Todo: Add Media
}