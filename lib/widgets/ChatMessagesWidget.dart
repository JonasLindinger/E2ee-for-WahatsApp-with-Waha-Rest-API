import 'package:flutter/cupertino.dart';

import 'ChatListItemWidget.dart';
import 'MessageWidget.dart';

class ChatMessagesWidget extends StatelessWidget {
  final Chat chat;
  final List<Message> messages;
  final String sessionName;
  final ScrollController scrollController;

  const ChatMessagesWidget({
    super.key,
    required this.chat,
    required this.messages,
    required this.sessionName,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) =>
          MessageWidget(
            sessionName: sessionName,
            chat: chat,
            message: messages[index],
            messages: messages,
          ),
        controller: scrollController,
      ),
    );
  }
}
