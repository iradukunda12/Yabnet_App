import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:yabnet/components/CustomProject.dart';

import '../data/HomePagePostData.dart';

class HomePageMediaTypeData {
  final Uint8List data;
  final String type;

  HomePageMediaTypeData(this.data, this.type);
}

class HomePageMediaHandler extends StatefulWidget {
  final double height;
  final double width;
  final bool device;
  final List<HomePageMediaData> media;
  final ValueChanged<int>? clicked;
  final Widget? action;

  const HomePageMediaHandler(
      {super.key,
      required this.media,
      required this.height,
      required this.width,
      this.device = false,
      this.clicked,
      this.action});

  @override
  State<HomePageMediaHandler> createState() => _HomePageMediaHandlerState();
}

class _HomePageMediaHandlerState extends State<HomePageMediaHandler> {
  @override
  Widget build(BuildContext context) {
    int length = widget.media.length;

    if (length == 1) {
      HomePageMediaData homePageMediaData = widget.media.single;
      return getTheMediaTypeView(
          0, homePageMediaData, widget.height, widget.width);
    } else if (length > 1) {
      List<Size> mediaWidth = [];
      double screenWidth = widget.width;

      int index = 0;
      // Catch four items

      while (index < length && index < 4) {
        if (widget.media.elementAtOrNull(index) != null) {
          if (length == 2) {
            mediaWidth.add(Size(screenWidth / 2, widget.height));
          }
          if (length == 3) {
            if (index == 0) {
              mediaWidth.add(
                  Size(screenWidth / 2, addPercentage(widget.height, 0.1)));
            } else {
              mediaWidth.add(
                  Size(screenWidth / 2, addPercentage(widget.height / 2, 0.1)));
            }
          }
          if (length >= 4) {
            mediaWidth.add(
                Size(screenWidth / 2, addPercentage(widget.height / 2, 0.1)));
          }
        }
        index++;
      }

      int mediaSize = mediaWidth.length;
      if (mediaSize == 2) {
        return twoTemplateView(mediaWidth);
      } else if (mediaSize == 3) {
        return threeLeftTemplateView(mediaWidth);
      } else {
        return fourTemplateView(mediaWidth);
      }
    }

    return SizedBox();
  }

  double addPercentage(double value, double percentage) {
    return value + (value * percentage);
  }

  Widget getTheMediaTypeView(int index, HomePageMediaData homePageMediaData,
      double height, double width,
      {bool moreMedia = false}) {
    return GestureDetector(
      onTap: () {
        if (widget.clicked != null) {
          widget.clicked!(index);
        }
      },
      child: Stack(
        children: [
          switch (homePageMediaData.mediaType) {
            HomePageMediaType.image =>
              imageMedia(homePageMediaData.mediaData, height, width),
            HomePageMediaType.video =>
              getVideoMedia(homePageMediaData.mediaData, height, width),
            HomePageMediaType.document =>
              imageMedia(homePageMediaData.mediaData, height, width),
          },
          moreMedia
              ? Positioned.fill(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration:
                        BoxDecoration(color: Colors.black.withOpacity(0.7)),
                    child: Center(
                      child: Text(
                        "+${widget.media.length - 4}",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ))
              : SizedBox(),
          widget.action != null
              ? Positioned.fill(
                  bottom: 0, left: 0, right: 0, child: widget.action!)
              : SizedBox(),
        ],
      ),
    );
  }

  Widget threeLeftTemplateView(List<Size> sizes) {
    return Row(
      children: [
        getTheMediaTypeView(
            0, widget.media[0], sizes[0].height, sizes[0].width),
        Expanded(
          child: Column(
            children: [
              getTheMediaTypeView(
                  1, widget.media[1], sizes[1].height, sizes[1].width),
              getTheMediaTypeView(
                  2, widget.media[2], sizes[2].height, sizes[2].width),
            ],
          ),
        )
      ],
    );
  }

  Widget fourTemplateView(List<Size> sizes) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              getTheMediaTypeView(
                  0, widget.media[0], sizes[0].height, sizes[0].width),
              getTheMediaTypeView(
                  1, widget.media[1], sizes[1].height, sizes[1].width),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              getTheMediaTypeView(
                  2, widget.media[2], sizes[2].height, sizes[2].width),
              getTheMediaTypeView(
                  3, widget.media[3], sizes[3].height, sizes[3].width,
                  moreMedia: widget.media.length > 4),
            ],
          ),
        )
      ],
    );
  }

  Widget twoTemplateView(List<Size> sizes) {
    return Row(
      children: [
        Expanded(
            child: getTheMediaTypeView(
                0, widget.media[0], sizes[0].height, sizes[0].width)),
        Expanded(
            child: getTheMediaTypeView(
                1, widget.media[1], sizes[1].height, sizes[1].width)),
      ],
    );
  }

  Future<Uint8List?> getLocalVideoThumbnail(String video) async {
    return await VideoThumbnail.thumbnailData(
      video: video,
      imageFormat: ImageFormat.JPEG,
      quality: 100,
    );
  }

  Future<Uint8List?> getOnlineVideoThumbnail(String video, String path) async {
    final filePath = await VideoThumbnail.thumbnailFile(
      video: video,
      thumbnailPath: path,
      imageFormat: ImageFormat.WEBP,
    );
    if (filePath == null) {
      return null;
    }
    return await File(filePath).readAsBytes();
    ;
  }

  Widget imageMedia(String image, double height, double width) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: height,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(0)),
              child: widget.device
                  ? Image.file(
                      File(image),
                      fit: BoxFit.cover,
                      errorBuilder: (a, b, c) {
                        return widgetProvider(Icons.not_interested);
                      },
                    )
                  : CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      progressIndicatorBuilder: (a, b, c) {
                        return widgetProvider(Icons.circle_outlined,
                            other: progressBarWidget());
                      },
                      errorWidget: (a, b, c) {
                        return widgetProvider(Icons.not_interested);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> getVideoThumbnail(String video) async {
    final videoPath = widget.device
        ? (await getLocalVideoThumbnail(video))
        : (await getOnlineVideoThumbnail(
            video, (await getTemporaryDirectory()).path));
    if (videoPath != null) {
      return videoPath;
    }
    return null;
  }

  Widget widgetProvider(IconData iconData, {Widget? other}) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
        ),
        child: Center(
          child: other ??
              Icon(
                iconData,
                color: Colors.white,
                size: 24,
              ),
        ));
  }

  Widget getVideoMedia(String video, double height, double width) {
    return FutureBuilder(
        future: getVideoThumbnail(video),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            // Error occurred
            return widgetProvider(Icons.circle_outlined,
                other: Container(
                  height: height,
                  child: Center(
                    child: progressBarWidget(),
                  ),
                ));
          }
          return SizedBox(
            width: width,
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                          height: height,
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(0)),
                          child: Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            errorBuilder: (a, b, c) {
                              return widgetProvider(Icons.not_interested);
                            },
                          )),
                    ),
                  ],
                ),
                Positioned.fill(
                    child: Center(
                  child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      )),
                ))
              ],
            ),
          );
        });
  }
}
