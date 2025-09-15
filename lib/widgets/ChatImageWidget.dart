import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:secure_messanger_app/widgets/MessageWidget.dart';

import '../screens/ImageInspectionScreen.dart';

class ChatImageWidget extends StatelessWidget {
  final Message message;

  const ChatImageWidget({
    super.key,
    required this.message,
  });


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ImageInspectionScreen(
              message: message,
            ))
        ),
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          // make it reasonably wide in the bubble
          width: 130,
          // optionally cap height so tall images don't take over
          // height: 220,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Image.network(
                    message.media['url'].toString(),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) => Icon(Icons.broken_image, color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
