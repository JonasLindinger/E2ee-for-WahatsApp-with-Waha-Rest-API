import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../screens/chat.dart';
import '../widgets/ChatWidget.dart';
import 'RSAUtils.dart';

class ChatConnection {
  static Future<void> SendKey({
    required String sessionName,
    required Chat chat,
    required Function() onSent,
  }) async {
     SharedPreferences prefs = await SharedPreferences.getInstance();

     String? keys = prefs?.getString(chatPrefPrefix + chat.id);
     bool chatIsEncrypted = keys != null;
     if (chatIsEncrypted) {
       chatIsEncrypted = keys.isNotEmpty;
     }

     // We don't need to send the key. The chat is already encrypted.
     if (chatIsEncrypted) return;

     String publicKey = await RSAUtils().GetPublicKeyAsString();
     publicKey = personalPublicKeyPrefix + publicKey;

     String messageToSent = publicKey;

     await sendMessage(
       sessionName: sessionName,
       chat: chat,
       message: messageToSent,
       dontEncrypt: false,
       onSent: onSent,
     );
  }

  static Future<void> sendMessage({
    required String sessionName,
    required Chat chat,
    required String message,
    required bool dontEncrypt,
    required Function() onSent,
  }) async {
    if (message.isEmpty) return; // Nothing to send!

    // Get preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var rawChatKeysData = prefs.getString(chatPrefPrefix + chat.id);
    bool canEncrypt = rawChatKeysData != null;

    String messageToSent = "";
    if (canEncrypt && !dontEncrypt) {
      // Encrypt message

      // Get keys
      List<String> chatKeys = decodeKeys(rawChatKeysData);
      RSAPublicKey publicKey = RSAUtils.publicKeyFromString(chatKeys[0]);

      // Encrypt message to payload
      final String encryptedPayload = RSAUtils.encryptHybridToString(message, publicKey);

      // Create messageToSent
      messageToSent = encryptedMessagePrefix + encryptedPayload;
    }

    // Send the message

    // Create Uri
    final url = serverURL + "/api/sendText";
    final uri = Uri.parse(url);

    // Try to send it
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chatId": chat.id,
          "reply_to": null, // Todo
          "text": messageToSent,
          "linkPreview": false, // Todo
          "linkPreviewHighQuality": false, // Todo
          "session": sessionName
        }),
      );

      // Sent message
      final body = response.body;
      final json = jsonDecode(body);

      onSent();
    } catch (e, st) {
      print("Something went wrong trying to get the status of a session: $e");
      print(st);
    }
  }

  
}