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
    return Text(
      message.message,
      style: TextStyle(
        color: Colors.black,
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