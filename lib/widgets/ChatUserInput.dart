import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:secure_messanger_app/screens/chat.dart';
import 'package:secure_messanger_app/utils/ChatConnection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ChatWidget.dart';

class ChatUserInput extends StatefulWidget {
  final FocusNode myFocusNode;
  final Chat chat;
  final String sessionName;
  final Function() onSent;

  const ChatUserInput({
    super.key,
    required this.myFocusNode,
    required this.chat,
    required this.sessionName,
    required this.onSent,
  });

  @override
  State<ChatUserInput> createState() => _ChatUserInputState();
}

class _ChatUserInputState extends State<ChatUserInput> {
  late FocusNode myFocusNode;
  late Chat chat;
  late String sessionName;
  late Function() onSent;

  final double sendPublicKeyGestureLength = 80;

  final TextEditingController messageController = TextEditingController();

  Offset startingDragPosition = Offset(0, 0);
  bool encryptionButtonState = false;
  String oldText = "";

  @override
  void initState() {
    super.initState();

    myFocusNode = widget.myFocusNode;
    chat = widget.chat;
    onSent = widget.onSent;
    sessionName = widget.sessionName;

    messageController.addListener(() {
      if (messageController.text != oldText) {
        // Update happened

        // Update ui
        setState(() {

        });

        // set values
        oldText = messageController.text;
      }
    });
  }

  @override
  void dispose() {
    messageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Row(
        children: [
          if (!chat.isGroupChat) // Only allow encryption for private chats. Group chats aren't supported (yet).
            GestureDetector(
              onVerticalDragEnd: (details) => {
                if (DraggedLongEnoughToSendKey(details)) {
                  ChatConnection.SendKey(
                    sessionName: sessionName,
                    chat: chat,
                    onSent: onSent,
                  ),
                },
              },
              onVerticalDragStart: (details) => {
                startingDragPosition = details.localPosition,
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: encryptionButtonState ? Colors.blue : Colors.grey,
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.only(left: 10),
                child: IconButton(
                    onPressed: ToggleEncryptionButton,
                    icon: Icon(Icons.account_circle_rounded, color: Colors.white)
                ),
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 150, // Max height before scrolling
                ),
                child: Scrollbar(
                  child: TextField(
                    controller: messageController,
                    focusNode: myFocusNode,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
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
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: null, // Allow growing lines
                  ),
                ),
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
                onPressed: () async {
                  bool shouldSendMessage = messageController.text.isNotEmpty;

                  if (shouldSendMessage) {
                    await ChatConnection.sendMessage(
                      sessionName: sessionName,
                      chat: chat,
                      message: messageController.text,
                      dontEncrypt: false,
                      onSent: onSent,
                    );
                    messageController.clear();
                  }
                  else {
                    // Do voice message
                  }
                },
                icon: Icon(
                    messageController.text == "" ? Icons.mic : Icons.send_rounded,
                    color: Colors.white
                )
            ),
          ),
        ],
      ),
    );
  }

  Future<void> ToggleEncryptionButton() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? keys = prefs.getString(chatPrefPrefix + chat.id);
    if (keys == null || keys.isEmpty) return; //  Chat has no keys

    setState(() {
      encryptionButtonState = !encryptionButtonState;
    });
  }

  double distanceBetween(Offset a, Offset b) => (a - b).distance;
  bool DraggedLongEnoughToSendKey(DragEndDetails details) {
    Offset endDragPosition = details.localPosition;
    var distance = distanceBetween(startingDragPosition, endDragPosition);

    return distance >= sendPublicKeyGestureLength;
  }
}
