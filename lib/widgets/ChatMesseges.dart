import 'package:flutter/cupertino.dart';

import 'MessageWidget.dart';

class ChatMessages extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;

  const ChatMessages({
    super.key,
    required this.messages,
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
                message: messages[index]
            ),
        controller: scrollController,
      ),
    );
  }
}
