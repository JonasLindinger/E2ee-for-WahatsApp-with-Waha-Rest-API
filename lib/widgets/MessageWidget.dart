import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:secure_messanger_app/utils/ChatConnection.dart';
import 'package:secure_messanger_app/utils/Colors.dart';
import 'package:secure_messanger_app/utils/RSAUtils.dart';
import 'package:secure_messanger_app/utils/TimeConverter.dart';
import 'package:secure_messanger_app/widgets/ChatImageWidget.dart';
import 'package:secure_messanger_app/widgets/VideoMessageWidget.dart';
import 'package:secure_messanger_app/widgets/VoiceMessageWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/chat.dart';
import 'ChatWidget.dart';


class MessageWidget extends StatefulWidget {
  final List<Message> messages;
  final Message message;
  final Chat chat;
  final String sessionName;

  const MessageWidget({
    super.key,
    required this.messages,
    required this.message,
    required this.chat,
    required this.sessionName,
  });

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final chat = widget.chat;
    final String sessionName = widget.sessionName;
    final bool isCurrentUser = message.fromMe;

    String messageToDisplay = GetMessageToDisplay(message);
    messageToDisplay = normalizeLinks(messageToDisplay);

    HandleMessage(sessionName, chat, message, isCurrentUser, widget.messages);

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isCurrentUser ? OwnMessage : OtherMessage,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isCurrentUser ? 12 : 0),
              bottomRight: Radius.circular(isCurrentUser ? 0 : 12),
            ),
          ),
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Image centered if exists
              if (message.hasMedia &&
                  (message.media['mimetype'] as String?)
                      ?.toLowerCase()
                      .startsWith('image/') ==
                      true)
                Center(child: ChatImageWidget(message: message)),
              // Video centered if exists
              if (message.hasMedia &&
                  (message.media['mimetype'] as String?)
                      ?.toLowerCase()
                      .startsWith('video/') ==
                      true)
                Center(child: VideoMessageWidget(message: message)),
              // Audio message
              if (message.hasMedia &&
                  (message.media['mimetype'] as String?)
                      ?.toLowerCase()
                      .startsWith('audio/') ==
                      true)
                VoiceMessageWidget(message: message),
              // Text message
              if (messageToDisplay.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SelectableLinkify(
                    text: messageToDisplay,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                    linkStyle: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      decorationThickness: 1.5,
                    ),
                    onOpen: (link) async {
                      Uri uri = Uri.parse(link.url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        debugPrint("Could not open " + link.url);
                      }
                    },
                  )
                ),
              // Time + checkmarks row at bottom right
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      formatMessageTime(
                        message.timestamp * 1000,
                        timestampIsUtc: true,
                        use24HourFormat: true,
                        timeZoneOffset: Duration(hours: 2), // adjust if needed
                      ),
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (isCurrentUser) ...[
                      SizedBox(width: 2),
                      Icon(
                        Icons.check,
                        size: 16,
                        color: message.status == MessageAcknowledgement.read
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      if (message.status != MessageAcknowledgement.sent)
                        Icon(
                          Icons.check,
                          size: 16,
                          color: message.status == MessageAcknowledgement.read
                              ? Colors.blue
                              : Colors.grey,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String GetMessageToDisplay(Message message) {
    if (message.message.contains(encryptedMessagePrefix) || message.message.contains(personalPublicKeyPrefix) || message.message.contains(chatKeysMessagePrefix))
      return "Loading message...";


    return message.message;
  }

  Future<void> HandleMessage(String sessionName, Chat chat, Message message, bool isFromUs, List<Message> messages) async {
    // Get Shared Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if we have keys
    bool hasKeys = await HasChatKeys(prefs, chat);

    String startingMessage = message.message;

    // If the newest message is this message, process it.
    bool isNewestMessage = messages[0].id == message.id;

    if (message.message.contains(encryptedMessagePrefix)) {
      // A encrypted message has to be decrypted!
      try {
        message.message = await GetDecryptedMessage(prefs, chat, message);
      }
      catch (e, st) {
        print("No key found for chat to decrypt message.");
      }
    }
    else if (!message.fromMe && hasKeys && message.message.contains(personalPublicKeyPrefix) && isNewestMessage) {
      // We got a chat key request and have to answer!

      print("PPK found: FM: " + message.fromMe.toString() + ", HK: " + hasKeys.toString() + ", IN: " + isNewestMessage.toString() + ", M: " + message.message);

      // Send chat keys
      await SendChatKeys(
        sessionName,
        prefs,
        chat,
        message,
        hasKeys
      );
    }
    else if (!message.fromMe && !hasKeys && message.message.contains(chatKeysMessagePrefix) /*&& isNewestMessage*/) { // We should be able to ignore the isTrue part
      // We got chat keys and should save them.
      await SaveChatKeys(prefs, chat, message);
    }

    if (message.message.contains(personalPublicKeyPrefix)) {
      message.message = "Chat key request.";
    }
    else if (message.message.contains(chatKeysMessagePrefix)) {
      message.message = "Chat keys.";
    }

    // Check if the message go changed.
    if (startingMessage != message.message) {
      // Update UI
      setState(() {

      });
    }
  }

  Future<String> GetDecryptedMessage(SharedPreferences prefs, Chat chat, Message message) async {
    String payload = message.message.replaceFirst(encryptedMessagePrefix, "");

    RSAPrivateKey privateKey = await GetPrivateChatKey(prefs, chat);

    String decryptedMessage = "";
    try {
      decryptedMessage = RSAUtils.decryptHybridFromString(payload, privateKey);
    }
    catch (e, st) {
      print("Couldn't found a chat key for this message.");
      decryptedMessage = "[No chat keys available]";
    }

    return decryptedMessage;
  }

  Future<bool> HasChatKeys(SharedPreferences prefs, Chat chat) async {
    var keys = await GetRawChatKeys(prefs, chat);

    bool hasKeys = keys != null;
    if (hasKeys)
      hasKeys = keys.isNotEmpty;

    return hasKeys;
  }

  Future<String?> GetRawChatKeys(SharedPreferences prefs, Chat chat) async {
    final String? storedKeys = prefs.getString(chatPrefPrefix + chat.id);
    return storedKeys;
  }

  Future<RSAPrivateKey> GetPrivateChatKey(SharedPreferences prefs, Chat chat) async {
    String? rawPemKeys = await GetRawChatKeys(prefs, chat);
    List<String> pemKeys = ChatConnection.decodeKeys(rawPemKeys!);

    RSAPrivateKey privateKey = RSAUtils.privateKeyFromString(pemKeys[1]); // 0 -> Public Key, 1 -> Private Key
    return privateKey;
  }

  Future<void> SendChatKeys(String sessionName, SharedPreferences prefs, Chat chat, Message message, bool hasKeys) async {
    String pemPublicKey = message.message.replaceFirst(personalPublicKeyPrefix, "");

    RSAPublicKey otherPersonsPublicKey = RSAUtils.publicKeyFromString(pemPublicKey);

    // Get or Create Chat Keys
    String chatKeys = "";
    if (hasKeys) {
      // Get Chat Keys
      String? rawChatKeys = await GetRawChatKeys(prefs, chat);
      chatKeys = rawChatKeys!;
    }
    else {
      // Create Chat Keys
      final keyPair = RSAUtils.generateRSAKeyPair();
      final publicKey = keyPair.publicKey;
      final privateKey = keyPair.privateKey;

      final publicPem = CryptoUtils.encodeRSAPublicKeyToPemPkcs1(publicKey);
      final privatePem = CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(privateKey);

      List<String> newChatKeys = [publicPem, privatePem];
      chatKeys = ChatConnection.encodeKeys(newChatKeys);
    }

    try {
      // Encode the chat keys with the public key of the other person and add the prefix
      chatKeys = RSAUtils.encryptHybridToString(chatKeys, otherPersonsPublicKey);
      chatKeys = chatKeysMessagePrefix + chatKeys;

      // Send the Chat Key
      ChatConnection.sendMessage(
        sessionName: sessionName,
        chat: chat,
        message: chatKeys,
        dontEncrypt: true,
        onSent: () {

        }
      );
    }
    catch (e, st) {
      print("Something went wrong trying to send the chat keys encrypted with the other persons public key");
    }
  }

  Future<void> SaveChatKeys(SharedPreferences prefs, Chat chat, Message message) async {
    String rawChatKeys = message.message.replaceFirst(chatKeysMessagePrefix, "");

    RSAPrivateKey myPrivateKey = await RSAUtils().GetPrivateKey();

    // Decrypt the rawChatKeys
    try {
      rawChatKeys = RSAUtils.decryptHybridFromString(rawChatKeys, myPrivateKey);
    }
    catch (e, st) {
      print("Failed decrypt chat keys. probably not for me...");
      return;
    }

    // We don't need to decode them to the List of Strings, since they are already in the format we want.
    // We want it to be a encoded(List<String>), which it should be from the other person by default.

    // Save keys
    prefs.setString(chatPrefPrefix + chat.id, rawChatKeys);
  }

  /// Normalizes text by adding "https://" in front of links that don't have a scheme.
  String normalizeLinks(String text) {
    return text.replaceAllMapped(
      // Match anything that looks like a link but does not already start with http:// or https://
      RegExp(r'(?<!https?:\/\/)(www\.[^\s]+)', caseSensitive: false),
          (match) => "https://${match.group(1)}",
    );
  }
}

class Message {
  String id = "";
  int timestamp = 0;
  String from = "";
  bool fromMe = false;
  MessageAcknowledgement status = MessageAcknowledgement.delivered;
  int ackId = -2;
  String ackName = "";
  String to = "";
  String message = "";
  bool hasMedia = false;
  dynamic media;
}

enum MessageAcknowledgement {
  sent,
  delivered,
  read,
}

extension MessageAcknowledgementX on MessageAcknowledgement {
  static MessageAcknowledgement fromAck(dynamic rawAck) {
    final ack = (rawAck ?? 1) as int;

    // WhatsApp ack: 0 = pending/unknown, 1 = sent, 2 = delivered, 3 = read
    final index = ack - 1;

    if (index < 0 || index >= MessageAcknowledgement.values.length) {
      // Fallback to "sent" (or maybe create a separate "pending" state)
      return MessageAcknowledgement.sent;
    }

    return MessageAcknowledgement.values[index];
  }
}