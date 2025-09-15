import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:secure_messanger_app/widgets/MessageWidget.dart';

class VoiceMessageWidget extends StatefulWidget {
  final Message message;

  const VoiceMessageWidget({
    super.key,
    required this.message,
  });

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  final AudioPlayer audioPlayer = AudioPlayer();

  bool isPlaying = false;
  bool loadedSource = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  late final StreamSubscription<PlayerState> _stateSub;
  late final StreamSubscription<Duration> _durationSub;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<void> _completeSub;

  @override
  void initState() {
    super.initState();

    // Make sure we stop at the end (no looping)
    audioPlayer.setReleaseMode(ReleaseMode.stop);

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

    // Snap UI to the end when playback completes
    _completeSub = audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        isPlaying = false;
        position = duration;
      });
    });
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _durationSub.cancel();
    _positionSub.cancel();
    _completeSub.cancel();
    audioPlayer.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VoiceMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If a different message gets rendered into the same State, reset visuals
    if (oldWidget.message.id != widget.message.id) {
      audioPlayer.stop();
      loadedSource = false;
      setState(() {
        isPlaying = false;
        duration = Duration.zero;
        position = Duration.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Message message = widget.message;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: (isPlaying ? Colors.green : Colors.blueGrey.shade700),
          child: IconButton(
            color: Colors.white,
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            iconSize: 18,
            onPressed: () async {
              if (isPlaying) {
                await audioPlayer.pause();
              } else {
                // Only prepare the source once; afterwards just resume
                if (!loadedSource) {
                  await PlayAudio(message); // keep your existing logic that sets the source and starts playing
                  loadedSource = true;
                } else {
                  await audioPlayer.resume();
                }
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              // ... your time labels (formatTime(position) etc.)
            ],
          ),
        ),
      ],
    );
  }


  Future<void> PlayAudio(Message message) async {
    String url = message.media["url"];

    final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
    final bytes = resp.bodyBytes; // Uint8List
    await audioPlayer.play(BytesSource(bytes));
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
