import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/MessageWidget.dart';

class ImageInspectionScreen extends StatefulWidget {
  final Message message;

  const ImageInspectionScreen({
    super.key,
    required this.message,
  });

  @override
  State<ImageInspectionScreen> createState() => _ImageInspectionScreenState();
}

class _ImageInspectionScreenState extends State<ImageInspectionScreen> {
  @override
  Widget build(BuildContext context) {
    final message = widget.message;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ColoredBox(
        color: Colors.black,
        child: SizedBox.expand(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 5.0,
            child: Image.network(
              message.media["url"] as String,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}