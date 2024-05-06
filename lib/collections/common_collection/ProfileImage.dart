import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/operations/ProfileOperation.dart';

import '../../components/CustomProject.dart';
import '../../db_references/Profile.dart';
import '../../main.dart';
import '../../pages/common_pages/DisplayProfilePage.dart';

class DefaultProfile {
  static Widget getImageText(String textImage, double iconSize,
      {Color? color, double? textSize}) {
    return Container(
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? const Color(getDarkGreyColor).withOpacity(0.4)),
      height: iconSize,
      width: iconSize,
      child: Center(
          child: Text(textImage,
              textScaleFactor: 1,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: textSize ?? (iconSize > 50 ? 50 : 20),
              ))),
    );
  }
}

class ProfileImage extends StatefulWidget {
  final double iconSize;
  final double? textSize;
  final String fullName;
  final String imageUri;
  final ValueChanged<String>? imageUrl;
  final bool canDisplayImage;
  final bool fromHome;
  final bool fromComment;

  const ProfileImage({
    super.key,
    required this.iconSize,
    this.imageUrl,
    this.canDisplayImage = false,
    required this.fullName,
    required this.imageUri,
    this.textSize,
    this.fromHome = false,
    this.fromComment = false,
  });

  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  String? imageAddress;
  WidgetStateNotifier<String?> widgetStateNotifier = WidgetStateNotifier();
  BoxFit fit = BoxFit.cover;

  ValueListenable<Box<dynamic>>? listenable;

  @override
  void didUpdateWidget(covariant ProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    loadTheImage();
  }

  @override
  void initState() {
    super.initState();
    loadTheImage();
  }

  @override
  void dispose() {
    super.dispose();
    listenable?.removeListener(loadTheImage);
  }

  void loadTheImage() async {
    if (!mounted) return;

    String text = widget.imageUri.toString();
    int length = text.length;

    if (text.isNotEmpty &&
        text[length - 1] == '_' &&
        text.contains(dbReference(dbReference(Profile.bucket)))) {
      imageAddress = null;
    } else {
      imageAddress = widget.imageUri;
    }

    widgetStateNotifier.sendNewState(imageAddress);
  }

  Widget onLoading() {
    return Center(
      child: progressBarWidget(),
    );
  }

  Widget onError() {
    return Icon(
      Icons.person,
      size: widget.iconSize,
    );
  }

  Widget useTextImage() {
    String imageText = ProfileOperation.getFullNameTextImage(widget.fullName);
    return DefaultProfile.getImageText(imageText, widget.iconSize,
        color: Colors.transparent, textSize: widget.textSize);
  }

  @override
  Widget build(BuildContext context) {
    if (imageAddress != null) {
      if (widget.imageUrl != null) {
        widget.imageUrl!(imageAddress!);
      }
      return WidgetStateConsumer(
          widgetStateNotifier: widgetStateNotifier,
          widgetStateBuilder: (context, data) {
            if (imageAddress?.isEmpty == true) return useTextImage();
            return imageAddress!.contains("https") ||
                    imageAddress!.contains("http")
                ? GestureDetector(
                    onTap: widget.canDisplayImage
                        ? () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => DisplayProfilePage(
                                        imageUri: imageAddress ?? "",
                                        title: widget.fullName))).then((value) {
                              if (widget.fromHome) {
                                setNormalUiViewOverlay();
                              } else if (widget.fromComment) {
                                setDarkGreyUiViewOverlay();
                              } else {
                                setLightUiViewOverlay();
                              }
                            });
                          }
                        : null,
                    child: CachedNetworkImage(
                      imageUrl: imageAddress!,
                      filterQuality: FilterQuality.medium,
                      fadeInCurve: Curves.linear,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      useOldImageOnUrlChange: true,
                      progressIndicatorBuilder: (a, b, c) {
                        return useTextImage();
                      },
                      fit: fit,
                      errorWidget: (a, b, c) {
                        return useTextImage();
                      },
                    ),
                  )
                : Image.asset(
                    imageAddress!,
                    fit: BoxFit.cover,
                    errorBuilder: (a, b, c) {
                      return useTextImage();
                    },
                  );
          });
    } else {
      if (widget.imageUrl != null && imageAddress != null) {
        widget.imageUrl!(imageAddress!);
      }
      return useTextImage();
    }
  }
}
