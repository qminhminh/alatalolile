import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';
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
  late Episode currentEpisode;
  WebViewController? controller;
  VideoPlayerController? player;
  String? directUrl;
  bool showEpisodes = false;
  bool fullscreen = false;

  Future<void> _toggleFullscreen() async {
    final next = !fullscreen;
    setState(() => fullscreen = next);
    if (next) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void initState() {
    super.initState();
    currentEpisode = widget.episode;
    _loadEpisode(widget.episode);
  }

  void _loadEpisode(Episode episode) {
    currentEpisode = episode;
    player?.dispose();
    player = null;
    directUrl = _directMediaUrl(episode.m3u8);
    if (directUrl != null) {
      controller = null;
      final video = VideoPlayerController.networkUrl(Uri.parse(directUrl!));
      player = video;
      video.initialize().then((_) {
        if (mounted && player == video) {
          video.play();
          setState(() {});
        }
      });
    } else {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(episode.embed));
    }
    if (mounted) setState(() {});
  }

  String? _directMediaUrl(String value) {
    if (value.isEmpty) return null;
    final path = Uri.tryParse(value)?.path.toLowerCase() ?? '';
    return path.endsWith('.m3u8') ||
            path.endsWith('.mp4') ||
            path.endsWith('.mpd')
        ? value
        : null;
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: fullscreen
        ? null
        : AppBar(
            title: Text('${widget.movie.name} - ${currentEpisode.name}'),
            actions: [
              IconButton(
                onPressed: () => setState(() => showEpisodes = !showEpisodes),
                icon: Icon(
                  showEpisodes
                      ? CupertinoIcons.xmark
                      : CupertinoIcons.list_bullet,
                ),
              ),
            ],
          ),
    body: Stack(
      children: [
        Positioned.fill(
          child: directUrl != null
              ? player!.value.isInitialized
                    ? _VideoSurface(
                        controller: player!,
                        onFullscreen: _toggleFullscreen,
                      )
                    : const Center(child: CupertinoActivityIndicator())
              : controller == null
              ? const Center(child: CupertinoActivityIndicator())
              : WebViewWidget(controller: controller!),
        ),
        if (showEpisodes)
          _EpisodePanel(
            servers: widget.servers,
            selected: currentEpisode,
            onClose: () => setState(() => showEpisodes = false),
            onSelect: (episode) {
              _loadEpisode(episode);
              setState(() => showEpisodes = false);
            },
          ),
      ],
    ),
  );
}

class _VideoSurface extends StatefulWidget {
  const _VideoSurface({required this.controller, required this.onFullscreen});
  final VideoPlayerController controller;
  final Future<void> Function() onFullscreen;
  @override
  State<_VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends State<_VideoSurface> {
  bool visible = true;
  Timer? hideTimer;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  void _scheduleHide() {
    hideTimer?.cancel();
    hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => visible = false);
    });
  }

  @override
  void dispose() {
    hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      final next = !visible;
      setState(() => visible = next);
      if (next) _scheduleHide();
    },
    child: Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: widget.controller.value.size.width,
                height: widget.controller.value.size.height,
                child: VideoPlayer(widget.controller),
              ),
            ),
          ),
        ),
        if (visible)
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) => DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xCCFFFFFF),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => value.isPlaying
                    ? widget.controller.pause()
                    : widget.controller.play(),
                iconSize: 34,
                color: Colors.black,
                icon: Icon(
                  value.isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                ),
              ),
            ),
          ),
        if (visible)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: _VideoControls(
                  controller: widget.controller,
                  onFullscreen: widget.onFullscreen,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _VideoControls extends StatelessWidget {
  const _VideoControls({required this.controller, required this.onFullscreen});
  final VideoPlayerController controller;
  final Future<void> Function() onFullscreen;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: controller,
    builder: (context, value, _) {
      final total = value.duration.inMilliseconds.toDouble();
      final position = value.position.inMilliseconds
          .clamp(0, total.toInt())
          .toDouble();
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC111111),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () =>
                  value.isPlaying ? controller.pause() : controller.play(),
              icon: Icon(
                value.isPlaying
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: total > 0 ? position : 0,
                  max: total > 0 ? total : 1,
                  onChanged: total > 0
                      ? (v) =>
                            controller.seekTo(Duration(milliseconds: v.round()))
                      : null,
                ),
              ),
            ),
            Text(
              '${_formatTime(value.position)} / ${_formatTime(value.duration)}',
              style: const TextStyle(fontSize: 12),
            ),
            IconButton(
              onPressed: () async {
                await onFullscreen();
              },
              icon: const Icon(CupertinoIcons.fullscreen),
            ),
          ],
        ),
      );
    },
  );

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _EpisodePanel extends StatelessWidget {
  const _EpisodePanel({
    required this.servers,
    required this.selected,
    required this.onClose,
    required this.onSelect,
  });
  final List<EpisodeServer> servers;
  final Episode selected;
  final VoidCallback onClose;
  final ValueChanged<Episode> onSelect;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0,
    right: 0,
    bottom: 0,
    width: 320,
    child: Material(
      color: const Color(0xF21A1A1A),
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 58, 12, 16),
            children: [
              const Text(
                'Danh sách tập',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ...servers.expand(
                (server) => [
                  Text(
                    server.name,
                    style: const TextStyle(color: Color(0xFFFFC107)),
                  ),
                  ...server.episodes.map(
                    (episode) => CupertinoButton(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: episode.slug == selected.slug
                          ? const Color(0xAA806316)
                          : Colors.transparent,
                      onPressed: () => onSelect(episode),
                      child: Text(
                        'Tập ${episode.name}',
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
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(CupertinoIcons.xmark),
            ),
          ),
        ],
      ),
    ),
  );
}
