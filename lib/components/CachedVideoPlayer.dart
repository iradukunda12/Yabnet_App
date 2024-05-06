import 'package:appinio_video_player/appinio_video_player.dart';
import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';

class CachedVideoPlayer extends StatefulWidget {
  final Uri videoUrl;
  final Widget placeholder;
  final double aspectRatio;
  final CustomVideoPlayerController controller;

  const CachedVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.placeholder,
    required this.controller,
    this.aspectRatio = 1 / 1,
  }) : super(key: key);

  @override
  _CachedVideoPlayerState createState() => _CachedVideoPlayerState();
}

class _CachedVideoPlayerState extends State<CachedVideoPlayer> {
  WidgetStateNotifier<bool> readyController =
      WidgetStateNotifier(currentValue: false);

  @override
  void initState() {
    super.initState();

    widget.controller.videoPlayerController.initialize().then((value) {
      readyController.sendNewState(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WidgetStateConsumer(
      widgetStateNotifier: readyController,
      widgetStateBuilder: (context, data) {
        if (data == true) {
          return Center(
            child: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: CustomVideoPlayer(
                customVideoPlayerController: widget.controller,
              ),
            ),
          );
        } else {
          return widget.placeholder;
        }
      },
    );
  }
}
