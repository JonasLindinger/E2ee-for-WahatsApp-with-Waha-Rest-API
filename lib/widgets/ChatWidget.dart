import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:secure_messanger_app/screens/main.dart';

class ChatWidget extends StatelessWidget {
  final Chat chat;
  final void Function()? OpenChat;

  const ChatWidget({
    super.key,
    required this.OpenChat,
    required this.chat,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: OpenChat,
      child: Container(
        width: 350,
        height: 70,
        margin: EdgeInsets.only(top: 5, bottom: 5, right: 10, left: 10),
        child: Container (
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: chat.picture != "" ?
                    Image.network(
                      chat.picture,
                    ) :
                    Container(
                      color: Colors.green,
                    )
                  ),
                ),
              SizedBox(
                width: 20,
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(right: 30),
                  height: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.name,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white
                        ),
                      ),
                      SizedBox(
                        height: 1,
                      ),
                      Text(
                        chat.lastMessage?["body"] ?? "",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey
                        ),
                        softWrap: true,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    ],
                  ),
                ),
              ),
            ],
          )
        ),
      )
    );
  }
}

class Chat {
  String id = "";
  String name = "";
  String picture = "";
  Map<String, dynamic>? lastMessage;
}