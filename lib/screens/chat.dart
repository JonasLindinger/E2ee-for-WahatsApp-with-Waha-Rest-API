import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:secure_messanger_app/main.dart';
import 'package:secure_messanger_app/utils/Colors.dart';
import 'package:secure_messanger_app/utils/RSAUtils.dart';
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

class _ChatScreenState extends State<ChatScreen> {
  late Chat chat;
  late String sessionName;

  int newestMessageTimeStamp = 0;
  int oldestMessageTimeStamp = 0;
  bool isPulling = false;

  // Encryption Button
  bool buttonState = false; // true -> encrypt. false -> normal messaging

  double sendPublicKeyGestureLength = 80;
  bool whatsAppLikeAppBar = false;

  // Obtain shared preferences.
  SharedPreferences? prefs;
  static const String chatPrefPrefix = "Chat-";

  static const String personalPublicKeyPrefix = "2PPK: ";  // PPK -> Personal Public Key
  static const String encryptedMessagePrefix = "2EM: ";  // EM -> Encrypted Message
  static const String chatKeysPrefix = "2CK: ";  // CK -> Chat Keys

  List<String> chatKeys = [];

  @override
  void initState() {
    super.initState();
    chat = widget.chat;
    sessionName = widget.sessionName;

    getMessages(); // Get's the current messages
    StartUpdate(); // Checks for new messages

    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        // cause a delay so that the keyboard has time to show up
        Future.delayed(const Duration(milliseconds: 500), () => {
        if (mounted)
          ScrollDown(),
        });
      }
    });

    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        // Load new messages
        if (!mounted) return; // State was disposed; abort.
        getOldMessages(); // gets the next old messages
      }
    });

    Future.delayed(
      const Duration(milliseconds: 500),
        () => ScrollDown(),
    );
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    messageController.dispose();
    super.dispose();
  }

  final TextEditingController messageController = TextEditingController();
  FocusNode myFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  List<Message> messanges = [];

  void ScrollDown() {
    scrollController.animateTo(
      scrollController.position.minScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppBackground,
      appBar: AppBar(
        backgroundColor: AppbarBackground,
        foregroundColor: Colors.white,
        title: whatsAppLikeAppBar ? WhatsAppLikeAppBar() : NotWhatsAppLikeAppBar(),
      ),
      body: Column(
        children: [
          // Display all messanges
          Expanded(
              child: BuildMessageList(),
          ),
          // User input
          BuildUserInput(),
        ],
      ),
    );
  }

  Widget WhatsAppLikeAppBar() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          child: Hero(
            tag: chat.id+"-image",
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: chat.picture != "" ?
              Image.network(
                chat.picture,
              ) :
              Container(
                color: Colors.green,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 20,
        ),
        Text(
          chat.name,
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18
          ),
        ),
      ],
    );
  }

  Widget NotWhatsAppLikeAppBar() {
    return Row(
      children: [
        // 1. Ein Expanded-Widget, das den Platz links vom Namen füllt
        const Expanded(
          child: SizedBox(),
        ),

        // 2. Der Name, der nun durch die Expanded-Widgets zentriert wird
        Text(
          chat.name,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24
          ),
        ),

        // 3. Ein Expanded-Widget, das den gesamten verbleibenden Platz füllt
        //    und das Profilbild nach ganz rechts schiebt.
        const Expanded(
          child: SizedBox(),
        ),

        // 4. Das Profilbild, das nun ganz rechts steht
        Container(
          width: 40,
          height: 40,
          child: Hero(
            tag: chat.id + "-image",
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: chat.picture != ""
                  ? Image.network(
                chat.picture,
              )
                  : Container(
                color: Colors.green,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void ToggleEncryptionButton() async {
    if (prefs == null) {
      prefs = await SharedPreferences.getInstance();
    }
    else {
      await prefs?.reload();
    }

    var list = prefs?.getString(chatPrefPrefix + chat.id);
    if (list == null || list.isEmpty) return; //  Chat has no keys

    setState(() {
      buttonState = !buttonState;
    });
  }

  void SendKey() async {
    if (prefs == null) {
      prefs = await SharedPreferences.getInstance();
    }
    else {
      await prefs?.reload();
    }

    var list = prefs?.getString(chatPrefPrefix + chat.id);
    bool chatIsEncrypted = list != null;
    if (chatIsEncrypted) {
      chatIsEncrypted = list.isNotEmpty;
    }

    // We don't need to send the key. The chat is already encrypted.
    if (chatIsEncrypted) return;

    String publicKey = await RSAUtils().GetPublicKeyAsString();
    publicKey = personalPublicKeyPrefix + publicKey;

    sendMessage(publicKey, true);
  }

  double distanceBetween(Offset a, Offset b) => (a - b).distance;
  bool DragedLongEnoughToSendKey(DragEndDetails details) {
    Offset endDragPosition = details.localPosition;
    var distance = distanceBetween(startingDragPosition, endDragPosition);

    return distance >= sendPublicKeyGestureLength;
  }

  Widget BuildMessageList() {
    return ListView.builder(
      reverse: true,
      itemCount: messanges.length,
      itemBuilder: (context, index) =>
        MessageWidget(
          message: messanges[index]
        ),
      controller: scrollController,
    );
  }

  Offset startingDragPosition = Offset(0, 0);

  Widget BuildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Row(
        children: [
          if (!chat.isGroupChat) // Only allow encryption for private chats. Group chats aren't supported (yet).
            GestureDetector(
              onVerticalDragEnd: (details) => {
                if (DragedLongEnoughToSendKey(details)) {
                  SendKey(),
                },
              },
              onVerticalDragStart: (details) => {
                startingDragPosition = details.localPosition,
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: buttonState ? Colors.blue : Colors.grey,
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
              child: TextField(
                style: TextStyle(
                  color: Colors.white,
                  decorationColor: Colors.white,
                ),
                controller: messageController,
                focusNode: myFocusNode,
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
                obscureText: false,
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
              onPressed: () => {
                sendMessage(messageController.text, false),
                messageController.clear(),
              },
              icon: Icon(Icons.send_rounded, color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sendMessage(String text, bool dontEncrypt) async {
    if (text == null) return;
    if (text.isEmpty) return;

    if (!dontEncrypt) {
      prefs = await SharedPreferences.getInstance();

      bool canEncrypt = prefs?.getString(chatPrefPrefix + chat.id) != null;

      if (canEncrypt && buttonState) {
        if (chatKeys.isEmpty) {
          var savedKeys = prefs?.getString(chatPrefPrefix + chat.id);
          if (savedKeys != null) {
            chatKeys = decodeKeys(savedKeys);
          }
        }
        
        // Get pom public key
        if (chatKeys.length == 2) {
          // Encrypt message
          RSAPublicKey publicKey = RSAUtils.publicKeyFromString(chatKeys[0]);

          // Encrypt text with public key
          text = encryptedMessagePrefix + RSAUtils.encrypt(text, publicKey); // EM -> Encrypted Message
        }
        else {
          print("Something went wrong. We should encrypt, but have no keys.");
        }
      }
    }

    final url = serverURL + "/api/sendText";
    final uri = Uri.parse(url);

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chatId": chat.id,
          "reply_to": null, // Todo
          "text": text, // Todo: encrypt
          "linkPreview": false, // Todo
          "linkPreviewHighQuality": false, // Todo
          "session": sessionName
        }),
      );

      final body = response.body;
      final json = jsonDecode(body);

      CheckForNewMessanges();

      ScrollDown();
    } catch (e, st) {
      print("Something went wrong trying to get the status of a session: $e");
      print(st);
    }
  }

  Future<void> SendGetMessagesAPI(Uri uri) async {
    prefs ??= await SharedPreferences.getInstance();

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

      if (!mounted) return; // State was disposed; abort.

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
          return m;
        }).toList();

        // Sort fetched batch by timestamp (newest -> oldest)
        fetched.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Deduplicate by id before merging
        final Set<String> existingIds = messanges.map((m) => m.id).toSet();
        bool updated = false;

        final String prefKey = chatPrefPrefix + chat.id;
        final List<String>? storedKeys = prefs?.getStringList(prefKey);
        bool hasKeys = storedKeys == null;

        for (final m in fetched) {
          if (m.id.isEmpty) continue;

          // Check if the message has content to display or is just useless
          bool hasContent = false;
          if (m.hasMedia) hasContent = true;
          if (m.message.isNotEmpty) hasContent = true;

          // If the message has no content, it's useless and we don't display it.
          if (!hasContent) continue;

          if (!chat.isGroupChat) { // Only do encryption stuff on private chats. not group chats
            // Do Encryption stuff
            if (m.message.contains(encryptedMessagePrefix)) {
              // Found an encrypted message!
              String message = m.message.replaceFirst(encryptedMessagePrefix, "");

              // Check for keys
              if (chatKeys.isEmpty) {
                var savedKeys = prefs?.getString(chatPrefPrefix + chat.id);
                if (savedKeys != null) {
                  chatKeys = decodeKeys(savedKeys);
                }
              }

              // Check if we can decrypt
              if (chatKeys == 2) {
                // Get Private key
                RSAPrivateKey privateKey = RSAUtils.privateKeyFromString(chatKeys[1]);

                // Decrypt Message
                m.message = RSAUtils.decrypt(message, privateKey);
              }
            }

            // Check if we have an encrypted chat. If we don't search messages for events
            if (!hasKeys) {
              // Search for public key
              if (m.fromMe) continue; // Don't search for the own RSA Key!

              if (m.message.contains(chatKeysPrefix)) {
                // The other person sent us Chat Keys.
                String message = m.message.replaceFirst(chatKeysPrefix, "");
                message = RSAUtils.decrypt(message, await RSAUtils().GetPrivateKey());

                // Extract keys
                List<String> keys = decodeKeys(message);

                // Save keys
                prefs?.setStringList(chatPrefPrefix + chat.id, keys);
              }
              else if (m.message.contains(personalPublicKeyPrefix)) {
                // The other person wants to encrypt the chat
                String otherPersonsPemPublicKey = m.message.replaceFirst(personalPublicKeyPrefix, "");
                RSAPublicKey otherPersonsPublicKey = RSAUtils.publicKeyFromString(otherPersonsPemPublicKey);

                // Generate public keys for the chat
                final keyPair = RSAUtils.generateRSAKeyPair();
                final publicKey = keyPair.publicKey as RSAPublicKey;
                final privateKey = keyPair.privateKey as RSAPrivateKey;

                // convert to string
                final publicPem = CryptoUtils.encodeRSAPublicKeyToPemPkcs1(publicKey);
                final privatePem = CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(privateKey);

                List<String> keys = [
                  publicPem,
                  privatePem
                ];

                // Save the keys locally
                prefs?.setStringList(chatPrefPrefix + chat.id, keys);

                // Send the keys encrypted with the other persons public key.
                String message = encodeKeys(keys);
                message = RSAUtils.encrypt(message, otherPersonsPublicKey);
                message = chatKeysPrefix + message; // CK -> Chat Keys

                // Actually send it.
                sendMessage(message, true);
              }
            }
          }

          // Add to Message list
          if (m.timestamp > newestMessageTimeStamp) {
            newestMessageTimeStamp = m.timestamp;
          }
          if (oldestMessageTimeStamp == 0) {
            oldestMessageTimeStamp = m.timestamp;
          }
          if (m.timestamp < oldestMessageTimeStamp) {
            oldestMessageTimeStamp = m.timestamp;
          }

          if (!existingIds.contains(m.id)) {
            messanges.add(m);
            existingIds.add(m.id);
            updated = true;
          }
        }

        if (updated) {
          // Ensure the whole list is newest -> oldest
          messanges.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          setState(() {});
        }
      } else {
        debugPrint("getMessages failed: ${response.statusCode} ${response.body}");
      }
    } catch (e, st) {
      print("Something went wrong trying to get the chat messages$e");
      print(st);
    }

    isPulling = false;
  }

  Future<void> StartUpdate() async {
    if (!mounted) return; // State was disposed; abort.
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return; // State was disposed; abort.

    CheckForNewMessanges();

    StartUpdate();
  }

  Future<void> CheckForNewMessanges() async {
    final url = serverURL + "/api/" + sessionName + "/chats/" + chat.id + "/messages";
    final uri = Uri.parse(url).replace(
      queryParameters: {
        "downloadMedia": "true", // Todo
        "chatId": chat.id.toString(),
        "limit": "20",
        "filter.timestamp.gte": newestMessageTimeStamp.toString(),
        "session": sessionName,
      },
    );

    await SendGetMessagesAPI(uri);
  }

  Future<void> getMessages() async {
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

    await SendGetMessagesAPI(uri);
  }

  Future<void> getOldMessages() async {
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

    await SendGetMessagesAPI(uri);
  }

  String resolveMediaUrl(String rawUrl, String serverUrl) {
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

  Future<void> waitForCondition(
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

  String encodeKeys(List<String> keys) {
    if (keys.length != 2) {
      throw ArgumentError('keys must contain exactly 2 items.');
    }
    return jsonEncode(keys); // e.g. ["key1","key2"]
  }

  List<String> decodeKeys(String encoded) {
    final parsed = jsonDecode(encoded);
    if (parsed is! List || parsed.length != 2 || parsed.any((e) => e is! String)) {
      throw const FormatException('Invalid encoded keys payload (expected 2 strings).');
    }
    return List<String>.from(parsed);
  }

}

