import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../components/CustomCircularButton.dart';
import '../../components/CustomProject.dart';

class DisplayProfilePage extends StatefulWidget {
  final String imageUri;
  final String title;

  const DisplayProfilePage(
      {super.key, required this.imageUri, required this.title});

  @override
  State<StatefulWidget> createState() {
    return _DisplayProfilePageState();
  }
}

class _DisplayProfilePageState extends State<DisplayProfilePage> {
  bool isTitleBarVisible = true;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    setDarkUiViewOverlay();
    dismissTitleBar(isTitleBarVisible);
  }

  void performBackPressed() {
    try {
      if (KeyboardVisibilityProvider.isKeyboardVisible(context)) {
        hideKeyboard(context).then((value) {});
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  void dismissTitleBar(bool visible) {
    if (visible) {
      timer ??= Timer(const Duration(seconds: 15), () {
        setState(() {
          isTitleBarVisible = false;
        });
        timer?.cancel();
        timer = null;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
    timer == null;
  }

  Widget getTheImageViewer() {
    return switch (widget.imageUri.isNotEmpty) {
      true => Center(
          child: AspectRatio(
            aspectRatio: 1 / 1,
            child: PhotoViewGallery.builder(
              itemCount: 1,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(
                    widget.imageUri,
                  ),
                  errorBuilder: (a, b, c) {
                    return const Center(
                        child: Text(
                      "No Image to display",
                      style: TextStyle(color: Colors.white),
                    ));
                  },
                  minScale: PhotoViewComputedScale.covered,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              scrollPhysics: NeverScrollableScrollPhysics(),
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),
          ),
        ),
      false => SizedBox(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          setState(() {
            isTitleBarVisible = !isTitleBarVisible;
            dismissTitleBar(isTitleBarVisible);
          });
          // Check if the swipe direction is down and the distance is significant
          if (details.primaryVelocity! > 0 && details.primaryVelocity! >= 100) {
            Navigator.pop(context);
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView(
                  children: List.generate(1, (index) => getTheImageViewer()),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: isTitleBarVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        child: Row(
                          children: [
                            CustomCircularButton(
                              imagePath: null,
                              iconColor: Colors.white,
                              onPressed: performBackPressed,
                              icon: Icons.arrow_back,
                              width: 40,
                              height: 40,
                              iconSize: 30,
                              mainAlignment: Alignment.center,
                              defaultBackgroundColor: Colors.transparent,
                              clickedBackgroundColor: Colors.white,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                widget.title,
                                textScaler: TextScaler.noScaling,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
