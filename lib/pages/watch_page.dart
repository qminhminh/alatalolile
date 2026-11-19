import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late VideoPlayerController controller;
  late Episode currentEpisode;
  double volume = 1;
  bool showEpisodes = false;
  bool loadingEpisode = false;
  bool controlsVisible = true;
  Timer? controlsTimer;
  @override
  void initState() {
    super.initState();
    currentEpisode = widget.episode;
    controller = _createController(widget.episode);
    controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _showControls();
      }
    });
  }

  VideoPlayerController _createController(Episode episode) =>
      VideoPlayerController.networkUrl(
        Uri.parse(episode.m3u8.isNotEmpty ? episode.m3u8 : episode.embed),
      );

  Future<void> _loadEpisode(Episode episode) async {
    final next = _createController(episode);
    await controller.pause();
    await controller.dispose();
    controller = next;
    currentEpisode = episode;
    loadingEpisode = true;
    if (mounted) setState(() {});
    try {
      await controller.initialize();
      if (mounted) {
        await controller.play();
        setState(() => loadingEpisode = false);
        _showControls();
      }
    } catch (_) {
      if (mounted) setState(() => loadingEpisode = false);
    }
  }

  @override
  void dispose() {
    controlsTimer?.cancel();
    controller.pause();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${widget.movie.name} - ${currentEpisode.name}'),
    ),
    body: Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (loadingEpisode)
                  const Center(child: CupertinoActivityIndicator(radius: 16))
                else if (controller.value.isInitialized)
                  FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                if (controller.value.isInitialized)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _showControls,
                    ),
                  ),
                if (controller.value.isInitialized && controlsVisible)
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '${widget.movie.name} (${widget.movie.year}) • ${currentEpisode.name}',
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                                    icon: const Icon(
                                      CupertinoIcons.goforward_10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (showEpisodes)
                  _EpisodePanel(
                    widget: widget,
                    selectedEpisode: currentEpisode,
                    onClose: () => setState(() => showEpisodes = false),
                    onSelect: (episode) async {
                      setState(() => showEpisodes = false);
                      await _loadEpisode(episode);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void _showControls() {
    controlsTimer?.cancel();
    if (mounted) setState(() => controlsVisible = true);
    controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && controller.value.isPlaying) {
        setState(() => controlsVisible = false);
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      _togglePlayback();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _seekBy(const Duration(seconds: -10));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _seekBy(const Duration(seconds: 10));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.audioVolumeUp) {
      _setVolume((volume + .1).clamp(0.0, 1.0));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.audioVolumeDown) {
      _setVolume((volume - .1).clamp(0.0, 1.0));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _seekBy(Duration offset) async {
    if (!controller.value.isInitialized) return;
    final position = controller.value.position + offset;
    final duration = controller.value.duration;
    final target = position < Duration.zero
        ? Duration.zero
        : position > duration
        ? duration
        : position;
    await controller.seekTo(target);
  }

  Future<void> _setVolume(double value) async {
    setState(() => volume = value);
    await controller.setVolume(value);
  }

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
  const _EpisodePanel({
    required this.widget,
    required this.selectedEpisode,
    required this.onClose,
    required this.onSelect,
  });
  final WatchPage widget;
  final Episode selectedEpisode;
  final VoidCallback onClose;
  final ValueChanged<Episode> onSelect;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0,
    right: 0,
    bottom: 0,
    width: 300,
    child: Container(
      color: const Color(0xF21A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 54, 10, 12),
      child: Stack(
        children: [
          ListView(
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
                      color: episode.slug == selectedEpisode.slug
                          ? const Color(0x55FFC107)
                          : Colors.transparent,
                      onPressed: () => onSelect(episode),
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
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0x661A1A1A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.xmark,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
