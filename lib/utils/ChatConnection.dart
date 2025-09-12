import 'dart:async';
import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../screens/chat.dart';
import '../widgets/ChatWidget.dart';
import '../widgets/MessageWidget.dart';
import 'RSAUtils.dart';

class ChatConnection {
  static List<Message> messages = [];
  static int newestMessageTimeStamp = 0;
  static int oldestMessageTimeStamp = 0;
  static bool isPulling = false;
  static List<String> chatKeys = [];
  static Chat chatToUpdate = new Chat();

  static Future<void> SendKey({
    required String sessionName,
    required Chat chat,
    required Function() onSent,
  }) async {
    print("SendKey 1");
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? keys = prefs.getString(chatPrefPrefix + chat.id);
    bool chatIsEncrypted = keys != null;
    if (chatIsEncrypted) {
      chatIsEncrypted = keys.isNotEmpty;
    }

    print("SendKey 2");

    // We don't need to send the key. The chat is already encrypted.
    if (chatIsEncrypted) return;

    String publicKey = await RSAUtils().GetPublicKeyAsString();
    publicKey = personalPublicKeyPrefix + publicKey;

    String messageToSent = publicKey;

    print("SendKey 3");
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
    else {
      messageToSent = message;
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

  static Future<void> SendGetMessagesAPI(String sessionName, Chat chat, Function() onSent, Function() onUpdateUI, Uri uri) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (isPulling) {
      await waitForCondition(
            () => !isPulling,
        pollInterval: const Duration(milliseconds: 50),
        timeout: const Duration(seconds: 10),
      );
    }

    isPulling = true;
    try {
      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body);

        // Build the fetched messages list
        final List<Message> fetched = (json as List<dynamic>).map((message) {
          final m = Message();
          m.id = (message["id"] ?? "").toString();
          m.timestamp = (message["timestamp"] ?? 0) as int;
          m.from = (message["from"] ?? "").toString();
          m.fromMe = (message["fromMe"] ?? false) as bool;
          m.to = (message["to"] ?? "").toString();
          m.message = (message["body"] ?? "").toString();
          m.hasMedia = (message["hasMedia"] ?? false) as bool;
          if (m.hasMedia) {
            message["media"]["url"] = resolveMediaUrl(message["media"]["url"], serverURL);
          }
          m.media = (message["media"]);

          m.status = MessageAcknowledgementX.fromAck(message["ack"]);

          return m;
        }).toList();

        // Deduplicate by id before merging
        final Set<String> existingIds = messages.map((m) => m.id).toSet();

        // Handle fetched messages
        bool listChanged = false;
        bool gotANewMessage = false;
        for (final message in fetched) {
          if (!(message.message.isNotEmpty || message.hasMedia)) continue; // Skip the message, if it has no content (no message and no media)

          if (existingIds.contains(message.id)) continue; // If the message is already in the list, skip it.

          // Add the message to list
          if (message.timestamp > newestMessageTimeStamp) {
            newestMessageTimeStamp = message.timestamp;
            gotANewMessage = true;
          }
          if (oldestMessageTimeStamp == 0 || message.timestamp < oldestMessageTimeStamp) {
            oldestMessageTimeStamp = message.timestamp;
          }
          messages.add(message);
          listChanged = true;
        }

        messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (listChanged) {
          // Ensure the whole list is newest -> oldest
          onUpdateUI();
        }

        // Only mark new messages as read, since we can also load old messages and don't wanna send out unnecessary request to the server.
        if (gotANewMessage) {
          await MarkAllChatMessagesAsRead(sessionName, chat);
        }
      } else {
        print("getMessages failed: ${response.statusCode} ${response.body}");
      }
    } catch (e, st) {
      print("Something went wrong trying to get the chat messages$e");
      print(st);
    }

    isPulling = false;
  }

  static Future<void> MarkAllChatMessagesAsRead(String sessionName, Chat chat) async {
    final url = serverURL + "/api/" + sessionName + "/chats/" + chat.id + "/messages/read";
    final uri = Uri.parse(url);

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({

        }),
      );

      final body = response.body;
      final json = jsonDecode(body);

    } catch (e, st) {
      print("Something went wrong trying to get the status of a session: $e");
      print(st);
    }
  }

  static bool isValidHybridPayload(String s) {
    try {
      final map = Map<String, dynamic>.from(jsonDecode(s));
      return map.containsKey("key") && map.containsKey("iv") && map.containsKey("message");
    } catch (_) {
      return false;
    }
  }

  static Future<void> StartUpdate(String sessionName, Chat chat, Function() onSent, Function() onUpdateUI, bool isUpdate) async {
    if (!isUpdate) {
      // New chat opened
      chatToUpdate = chat;
    }

    // Check if we should update
    if (chatToUpdate != chat) {
      // Current chat changed
      return;
    }

    await Future.delayed(const Duration(seconds: 3));

    // Check if we should update
    if (chatToUpdate != chat) {
      // Current chat changed
      return;
    }

    CheckForNewMessages(sessionName, chat, onSent, onUpdateUI);

    // Loop
    StartUpdate(sessionName, chat, onSent, onUpdateUI, true);
  }

  static Future<void> CheckForNewMessages(String sessionName, Chat chat, Function() onSent, Function() onUpdateUI) async {
    final url = serverURL + "/api/" + sessionName + "/chats/" + chat.id + "/messages";
    final uri = Uri.parse(url).replace(
      queryParameters: {
        "downloadMedia": "true",
        "chatId": chat.id.toString(),
        "limit": "20",
        "filter.timestamp.gte": newestMessageTimeStamp.toString(),
        "session": sessionName,
      },
    );

    await SendGetMessagesAPI(sessionName, chat, onSent, onUpdateUI, uri);
  }

  static Future<void> getMessages(String sessionName, Chat chat, Function() onSent, Function() onUpdateUI) async {
    // Reset values
    messages.clear();
    newestMessageTimeStamp = 0;
    oldestMessageTimeStamp = 0;
    isPulling = false;

    // 🔥 Load saved keys instead of wiping them
    final prefs = await SharedPreferences.getInstance();
    final savedKeys = prefs.getString(chatPrefPrefix + chat.id);
    chatKeys = (savedKeys != null && savedKeys.isNotEmpty)
        ? decodeKeys(savedKeys)
        : [];

    final url = serverURL + "/api/" + sessionName + "/chats/" + chat.id + "/messages";
    final uri = Uri.parse(url).replace(
      queryParameters: {
        "downloadMedia": "true", // Todo
        "chatId": chat.id.toString(),
        "limit": "20",
        "offset": "0",
        "session": sessionName,
      },
    );

    await SendGetMessagesAPI(sessionName, chat, onSent, onUpdateUI, uri);
  }

  static Future<void> getOldMessages(String sessionName, Chat chat, Function() onSent, Function() onUpdateUI) async {
    print("Pulling old: " + oldestMessageTimeStamp.toString() + " - " + newestMessageTimeStamp.toString());
    final url = serverURL + "/api/" + sessionName + "/chats/" + chat.id + "/messages";
    final uri = Uri.parse(url).replace(
      queryParameters: {
        "downloadMedia": "true", // Todo
        "chatId": chat.id.toString(),
        "limit": "20",
        "filter.timestamp.lte": oldestMessageTimeStamp.toString(),
        "session": sessionName,
      },
    );

    await SendGetMessagesAPI(sessionName, chat, onSent, onUpdateUI, uri);
  }

  static String resolveMediaUrl(String rawUrl, String serverUrl) {
    final server = Uri.parse(serverUrl);
    Uri uri = Uri.parse(rawUrl);

    // Handle relative paths like "/files/img.jpg"
    if (!uri.hasScheme) {
      return server.resolve(rawUrl).toString();
    }

    // Rewrite localhost/loopback to your server host
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      uri = uri.replace(
        scheme: server.scheme,
        host: server.host,
        port: server.hasPort ? server.port : null,
      );
    }
    return uri.toString();
  }

  static Future<void> waitForCondition(
      FutureOr<bool> Function() condition, {
        Duration pollInterval = const Duration(milliseconds: 50),
        Duration? timeout,
      }) async {
    final sw = Stopwatch()..start();
    while (true) {
      if (await condition()) return;
      if (timeout != null && sw.elapsed >= timeout) {
        throw TimeoutException('Condition not met within $timeout');
      }
      await Future.delayed(pollInterval);
    }
  }

  static String encodeKeys(List<String> keys) {
    if (keys.length != 2) {
      throw ArgumentError('keys must contain exactly 2 items.');
    }
    return jsonEncode(keys); // e.g. ["key1","key2"]
  }

  static List<String> decodeKeys(String encoded) {
    final parsed = jsonDecode(encoded);
    if (parsed is! List || parsed.length != 2 || parsed.any((e) => e is! String)) {
      throw const FormatException('Invalid encoded keys payload (expected 2 strings).');
    }
    return List<String>.from(parsed);
  }
}