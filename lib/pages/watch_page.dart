import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/movie.dart';

class WatchPage extends StatefulWidget {
  const WatchPage({required this.movie, required this.episode, super.key});
  final Movie movie;
  final Episode episode;
  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  late final VideoPlayerController controller;
  double volume = 1;
  @override
  void initState() {
    super.initState();
    controller =
        VideoPlayerController.networkUrl(
            Uri.parse(
              widget.episode.m3u8.isNotEmpty
                  ? widget.episode.m3u8
                  : widget.episode.embed,
            ),
          )
          ..initialize().then((_) {
            if (mounted) setState(() {});
          });
  }

  @override
  void dispose() {
    controller.pause();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${widget.movie.name} - ${widget.episode.name}'),
    ),
    body: Column(
      children: [
        AspectRatio(
          aspectRatio: controller.value.isInitialized
              ? controller.value.aspectRatio
              : 16 / 9,
          child: controller.value.isInitialized
              ? VideoPlayer(controller)
              : const Center(child: CircularProgressIndicator()),
        ),
        VideoProgressIndicator(
          controller,
          allowScrubbing: true,
          padding: const EdgeInsets.all(12),
          colors: const VideoProgressColors(playedColor: Color(0xFFFFC107)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => controller.seekTo(
                controller.value.position - const Duration(seconds: 10),
              ),
              icon: const Icon(CupertinoIcons.gobackward_10),
            ),
            IconButton(
              onPressed: () async {
                volume = volume > 0 ? 0 : 1;
                await controller.setVolume(volume);
                if (mounted) setState(() {});
              },
              icon: Icon(
                volume == 0
                    ? CupertinoIcons.volume_off
                    : CupertinoIcons.volume_up,
              ),
            ),
            SizedBox(
              width: 120,
              child: Slider(
                value: volume,
                onChanged: (value) async {
                  setState(() => volume = value);
                  await controller.setVolume(value);
                },
                activeColor: const Color(0xFFFFC107),
              ),
            ),
            IconButton(
              onPressed: _togglePlayback,
              icon: Icon(
                controller.value.isPlaying
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
              ),
            ),
            IconButton(
              onPressed: () => controller.seekTo(
                controller.value.position + const Duration(seconds: 10),
              ),
              icon: const Icon(CupertinoIcons.goforward_10),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> _togglePlayback() async {
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }
}
