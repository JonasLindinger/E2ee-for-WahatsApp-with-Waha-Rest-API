import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class MessageWidget extends StatefulWidget {
  final Message message;

  const MessageWidget({
    super.key,
    required this.message,
  });

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  final audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  late final StreamSubscription<PlayerState> _stateSub;
  late final StreamSubscription<Duration> _durationSub;
  late final StreamSubscription<Duration> _positionSub;

  @override
  void initState() {
    super.initState();

    _stateSub = audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    _durationSub = audioPlayer.onDurationChanged.listen((newDuration) {
      if (!mounted) return;
      setState(() {
        duration = newDuration;
      });
    });

    _positionSub = audioPlayer.onPositionChanged.listen((newPosition) {
      if (!mounted) return;
      setState(() {
        position = newPosition;
      });
    });
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _durationSub.cancel();
    _positionSub.cancel();
    audioPlayer.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;

    final bool isCurrentUser = message.fromMe;
    final alignment =
    isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment, // position the bubble left/right
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // limit width so long texts wrap; short texts keep minimal size
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.green : Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isCurrentUser ? 12 : 0),
              bottomRight: Radius.circular(isCurrentUser ? 0 : 12),
            ),
          ),
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
          // Remove alignment here so the container sizes to its child
          child: Column(
            children: [
              if (message.hasMedia && (message.media['mimetype'] as String?)?.toLowerCase().startsWith('image/') == true)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    // make it reasonably wide in the bubble
                    width: 130,
                    // optionally cap height so tall images don't take over
                    // height: 220,
                    child: blurredImage(message.media['url'].toString()),
                  ),
                ),
              if (message.hasMedia && (message.media['mimetype'] as String?)?.toLowerCase().startsWith('audio/') == true)
                Container(
                  padding: const EdgeInsets.all(0),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: (isPlaying ? Colors.green : Colors.blueGrey.shade700),
                        child: IconButton(
                          color: Colors.white,
                          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                          iconSize: 22,
                          onPressed: () async {
                            if (isPlaying) {
                              await audioPlayer.pause();
                            } else {
                              await audioPlayer.play(message.media["url"]);
                            }
                          },
                          tooltip: isPlaying ? 'Pause' : 'Play',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Progress + time
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Use milliseconds for smoother scrubbing
                            Builder(
                              builder: (context) {
                                final totalMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
                                final posMs = position.inMilliseconds.clamp(0, totalMs);
                                return SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                    inactiveTrackColor: Colors.white24,
                                    activeTrackColor: Colors.white70,
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: totalMs.toDouble(),
                                    value: posMs.toDouble(),
                                    onChanged: duration > Duration.zero
                                        ? (value) {
                                      // Immediate visual feedback while dragging
                                      setState(() {
                                        position = Duration(milliseconds: value.round());
                                      });
                                    }
                                        : null,
                                    onChangeEnd: duration > Duration.zero
                                        ? (value) async {
                                      await audioPlayer.seek(Duration(milliseconds: value.round()));
                                    }
                                        : null,
                                  ),
                                );
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatTime(position),
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  formatTime(
                                    Duration(
                                      milliseconds: (duration - position).inMilliseconds.clamp(0, duration.inMilliseconds),
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (message.message.isNotEmpty)
                Text(
                  message.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
            ]
          ),
        ),
      ),
    );
  }

  Widget blurredImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          // fit: BoxFit.cover, // or BoxFit.contain if you don't want cropping
          errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white70),
        ),
      ),
    );
  }


  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return [
      if (duration.inHours > 0) hours,
      minutes,
      seconds,
    ].join(":");
  }
}

class Message {
  String id = "";
  int timestamp = 0;
  String from = "";
  bool fromMe = false;
  String to = "";
  String message = "";
  bool hasMedia = false;
  dynamic media;
  // Todo: Add Media
}