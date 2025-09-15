import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../widgets/MessageWidget.dart';

class VideoInspectionScreen extends StatefulWidget {
  final Message message;

  const VideoInspectionScreen({
    super.key,
    required this.message
  });

  @override
  State<VideoInspectionScreen> createState() => _VideoInspectionScreenState();
}

class _VideoInspectionScreenState extends State<VideoInspectionScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _showControls = true;
  bool _isMuted = false;
  late Message message;

  @override
  void initState() {
    super.initState();

    message = widget.message;

    final url = message.media["url"].toString();
    final uri = Uri.parse(url);

    _controller = VideoPlayerController.networkUrl(uri)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _controller!.setVolume(1.0); // Enable audio
          _controller!.play();          // Optional autoplay
        }
      });
    }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isLoading || _controller == null
            ? const CircularProgressIndicator()
            : GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
              if (_showControls) _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        VideoProgressIndicator(
          _controller!,
          allowScrubbing: true,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          colors: const VideoProgressColors(
            playedColor: Colors.red,
            bufferedColor: Colors.grey,
            backgroundColor: Colors.white30,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                final pos = _controller!.value.position;
                _controller!.seekTo(pos - const Duration(seconds: 10));
              },
              icon: const Icon(Icons.replay_10, color: Colors.white),
            ),
            IconButton(
              onPressed: _togglePlayPause,
              icon: Icon(
                _controller!.value.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
                color: Colors.white,
                size: 50,
              ),
            ),
            IconButton(
              onPressed: () {
                final pos = _controller!.value.position;
                _controller!.seekTo(pos + const Duration(seconds: 10));
              },
              icon: const Icon(Icons.forward_10, color: Colors.white),
            ),
            IconButton(
              onPressed: _toggleMute,
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}