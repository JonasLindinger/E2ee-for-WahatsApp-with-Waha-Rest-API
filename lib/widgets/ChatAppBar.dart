import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/Colors.dart';
import 'ChatWidget.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Chat chat;
  final bool whatsAppLikeAppBar;

  const ChatAppBar({
    super.key,
    required this.whatsAppLikeAppBar,
    required this.chat,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppbarBackground,
      foregroundColor: Colors.white,
      title: whatsAppLikeAppBar ? WhatsAppLikeAppBar() : NotWhatsAppLikeAppBar(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
}
