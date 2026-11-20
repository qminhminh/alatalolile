import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:better_player/better_player.dart';
import 'package:path_provider/path_provider.dart';

import '../pages/home_page.dart';

class StartupVideoGate extends StatefulWidget {
  const StartupVideoGate({super.key});
  @override
  State<StartupVideoGate> createState() => _StartupVideoGateState();
}

class _StartupVideoGateState extends State<StartupVideoGate> {
  BetterPlayerController? _controller;
  bool _closed = false;
  int _plays = 0;

  bool get _desktop => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    if (_desktop) _startVideo();
  }

  Future<void> _startVideo() async {
    final bytes = (await rootBundle.load('assets/videos/he_he_he.mp4')).buffer
        .asUint8List();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/alatalolile_intro.mp4');
    await file.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    final controller = BetterPlayerController(
      const PlayerConfiguration(autoPlay: true, looping: false),
      betterPlayerDataSource: PlayerDataSource.file(file.path),
    );
    _controller = controller;
    controller.addVideoListener(_onVideoChanged);
    if (mounted) setState(() {});
  }

  void _onVideoChanged() {
    final controller = _controller;
    if (controller == null || controller.duration == null) return;
    controller.position.then((position) {
      if (!mounted || _controller != controller || position == null) return;
      if (position < controller.duration!) return;
      _plays++;
      if (_plays >= 2) {
        _close();
      } else {
        controller.seekTo(Duration.zero);
        controller.play();
      }
    });
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    _controller?.removeVideoListener(_onVideoChanged);
    _controller?.dispose();
    if (mounted) setState(() {});
  }

  void _replay() {
    if (!_desktop) return;
    setState(() {
      _closed = false;
      _plays = 0;
    });
    _startVideo();
  }

  @override
  void dispose() {
    _controller?.removeVideoListener(_onVideoChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_desktop || _closed || controller == null) {
      return HomePage(onReplayIntro: _replay);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: const Color(0xFF000000),
          child: Center(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: BetterPlayer(controller: controller),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: CupertinoButton(
            padding: const EdgeInsets.all(10),
            color: const Color(0xAA222222),
            onPressed: _close,
            child: const Icon(CupertinoIcons.xmark),
          ),
        ),
      ],
    );
  }
}
