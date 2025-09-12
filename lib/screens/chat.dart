import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:secure_messanger_app/main.dart';
import 'package:secure_messanger_app/utils/ChatConnection.dart';
import 'package:secure_messanger_app/utils/Colors.dart';
import 'package:secure_messanger_app/utils/RSAUtils.dart';
import 'package:secure_messanger_app/widgets/ChatAppBar.dart';
import 'package:secure_messanger_app/widgets/ChatMesseges.dart';
import 'package:secure_messanger_app/widgets/ChatUserInput.dart';
import 'package:secure_messanger_app/widgets/MessageWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

const String chatPrefPrefix = "~Chat-";

const String personalPublicKeyPrefix = "~PPK: ";  // PPK -> Personal Public Key
const String encryptedMessagePrefix = "~EM: ";  // EM -> Encrypted Message
const String chatKeysMessagePrefix = "~CK: ";  // CK -> Chat Keys
const String encryptionEstablishedTextReplacement = "Encryption established.";
const String tryToEstablishEncryptionTextReplacement = "Trying to establish encryption.";

class _ChatScreenState extends State<ChatScreen> {
  late Chat chat;
  late String sessionName;

  // Obtain shared preferences.
  SharedPreferences? prefs;

  FocusNode myFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    chat = widget.chat;
    sessionName = widget.sessionName;

    ChatConnection.getMessages(sessionName, chat, OnSentMessage, UpdateUI); // Get's the current messages
    ChatConnection.StartUpdate(sessionName, chat, OnSentMessage, UpdateUI, false); // Checks for new messages
    HandleScrollingUp(); // Subscribes to scroll up event
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppBackground,
      appBar: ChatAppBar(
          whatsAppLikeAppBar: false,
          chat: chat
      ),
      body: Column(
        children: [
          // Display all messages
          ChatMessages(
              messages: ChatConnection.messages,
              scrollController: scrollController
          ),

          // Display user input
          ChatUserInput(
            myFocusNode: myFocusNode,
            chat: chat,
            sessionName: sessionName,
            onSent: OnSentMessage,
          ),
        ],
      ),
    );
  }

  void HandleScrollingUp() {
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        // Load new messages
        if (!mounted) return; // State was disposed; abort.
        ChatConnection.getOldMessages(sessionName, chat, OnSentMessage, UpdateUI); // gets the next old messages
      }
    });
  }

  void OnSentMessage() {
    ChatConnection.CheckForNewMessages(sessionName, chat, OnSentMessage, UpdateUI);

    // Scroll down to the beginning of the chat.
    scrollController.animateTo(
      scrollController.position.minScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  void UpdateUI() {
    setState(() {

    });
  }
}