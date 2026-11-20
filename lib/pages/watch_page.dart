import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_all/webview_all.dart';

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
  bool hasPlayableSource = false;
  bool showEpisodes = false;

  @override
  void initState() {
    super.initState();
    currentEpisode = widget.episode;
    _loadEpisode(widget.episode);
  }

  void _loadEpisode(Episode episode) {
    currentEpisode = episode;
    final url = episode.embed.isNotEmpty ? episode.embed : episode.m3u8;
    hasPlayableSource = url.isNotEmpty;
    controller = hasPlayableSource
        ? (WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(url)))
        : null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${widget.movie.name} - ${currentEpisode.name}'),
      actions: [
        IconButton(
          onPressed: () => setState(() => showEpisodes = !showEpisodes),
          icon: Icon(
            showEpisodes ? CupertinoIcons.xmark : CupertinoIcons.list_bullet,
          ),
        ),
      ],
    ),
    body: Stack(
      children: [
        Positioned.fill(
          child: !hasPlayableSource
              ? const _PlaybackUnavailable()
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

class _PlaybackUnavailable extends StatelessWidget {
  const _PlaybackUnavailable();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(CupertinoIcons.exclamationmark_circle, size: 44),
        const SizedBox(height: 12),
        const Text('Tập phim này chưa có nguồn phát.'),
        const SizedBox(height: 16),
        CupertinoButton.filled(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Quay lại'),
        ),
      ],
    ),
  );
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
