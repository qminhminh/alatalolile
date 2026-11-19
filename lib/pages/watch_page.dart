import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/movie.dart';

class WatchPage extends StatefulWidget {
  const WatchPage({
    required this.movie,
    required this.episode,
    this.servers = const [],
    super.key,
  });
  final Movie movie;
  final Episode episode;
  final List<EpisodeServer> servers;
  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  late final VideoPlayerController controller;
  double volume = 1;
  bool showEpisodes = false;
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              controller.value.isInitialized
                  ? VideoPlayer(controller)
                  : const Center(child: CircularProgressIndicator()),
              if (controller.value.isInitialized)
                Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '${widget.movie.name} (${widget.movie.year}) • ${widget.episode.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                      ),
                    ),
                  ),
                ),
              if (controller.value.isInitialized)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(10),
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(22),
                    onPressed: () =>
                        setState(() => showEpisodes = !showEpisodes),
                    child: Icon(
                      showEpisodes
                          ? CupertinoIcons.xmark
                          : CupertinoIcons.list_bullet,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              if (controller.value.isInitialized)
                Center(
                  child: GestureDetector(
                    onTap: _togglePlayback,
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white.withValues(alpha: .9),
                      child: Icon(
                        controller.value.isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              if (controller.value.isInitialized)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    height: 68,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xDD000000)],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            controller,
                            allowScrubbing: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 1,
                            ),
                            colors: const VideoProgressColors(
                              playedColor: Color(0xFFFFC107),
                              bufferedColor: Colors.white38,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -52),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () => controller.seekTo(
                                    controller.value.position -
                                        const Duration(seconds: 10),
                                  ),
                                  icon: const Icon(
                                    CupertinoIcons.gobackward_10,
                                  ),
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
                                    controller.value.position +
                                        const Duration(seconds: 10),
                                  ),
                                  icon: const Icon(CupertinoIcons.goforward_10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (showEpisodes) _EpisodePanel(widget: widget),
            ],
          ),
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

class _EpisodePanel extends StatelessWidget {
  const _EpisodePanel({required this.widget});
  final WatchPage widget;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0,
    right: 0,
    bottom: 0,
    width: 300,
    child: Container(
      color: const Color(0xF21A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 54, 10, 12),
      child: ListView(
        children: [
          const Text(
            'Danh sách tập',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...widget.servers.expand(
            (server) => <Widget>[
              Text(
                server.name,
                style: const TextStyle(color: Color(0xFFFFC107)),
              ),
              const SizedBox(height: 6),
              ...server.episodes.map(
                (episode) => CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  alignment: Alignment.centerLeft,
                  color: episode.slug == widget.episode.slug
                      ? const Color(0x55FFC107)
                      : Colors.transparent,
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => WatchPage(
                        movie: widget.movie,
                        episode: episode,
                        servers: widget.servers,
                      ),
                    ),
                  ),
                  child: Text(
                    episode.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    ),
  );
}
