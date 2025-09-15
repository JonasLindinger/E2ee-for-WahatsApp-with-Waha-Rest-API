import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:secure_messanger_app/screens/VideoInspectionScreen';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../screens/ImageInspectionScreen.dart';
import 'MessageWidget.dart';

class VideoMessageWidget extends StatefulWidget {
  final Message message;

  const VideoMessageWidget({
    super.key,
    required this.message,
  });

  @override
  State<VideoMessageWidget> createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends State<VideoMessageWidget> {
  Uint8List? thumbnail;
  String? videoPath;
  late Message message;

  @override
  void initState() {
    super.initState();
    message = widget.message;
    print("Video: " + message.media.toString());

    // run async code in a separate method without making initState async
    _initVideo();
  }

  Future<void> _initVideo() async {
    final path = await generateThumbnail();
    if (mounted) {
      setState(() {
        videoPath = path;
      });
    }
  }

  Future<String?> generateThumbnail() async {
    final path = message.media['url'].toString();

    if (path.isEmpty) {
      debugPrint("No video path found for message ${message.id}");
      return null;
    }

    String localPath = path;
    try {
      // Download if remote URL
      if (localPath.startsWith("http")) {
        debugPrint("Downloading video for thumbnail...");
        final response = await http.get(Uri.parse(localPath));
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/video_${message.id}.mp4');
          await file.writeAsBytes(response.bodyBytes);
          localPath = file.path;
          debugPrint("Video saved to: $localPath");
        } else {
          debugPrint("Failed to download video. Status: ${response.statusCode}");
          return null;
        }
      }

      final uint8list = await VideoThumbnail.thumbnailData(
        video: localPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );

      if (mounted) {
        setState(() {
          thumbnail = uint8list;
        });
      }
    } catch (e) {
      debugPrint("Failed to generate thumbnail: $e");
    }

    return localPath;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: videoPath == null
          ? null
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoInspectionScreen(
              message: message,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 130,
          child: Column(
            children: [
              ClipRRect(
                child: Stack(
                  alignment: Alignment.center, // centers the overlay
                  children: [
                    ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Image.memory(
                        thumbnail!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white70),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black38, // semi-transparent background
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}