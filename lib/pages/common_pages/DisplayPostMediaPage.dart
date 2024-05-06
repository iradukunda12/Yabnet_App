import 'dart:async';

import 'package:appinio_video_player/appinio_video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/CachedVideoPlayer.dart';
import 'package:yabnet/data_notifiers/CommentsNotifier.dart';
import 'package:yabnet/data_notifiers/LikesNotifier.dart';
import 'package:yabnet/data_notifiers/PostProfileNotifier.dart';
import 'package:yabnet/data_notifiers/RepostsNotifier.dart';

import '../../components/CustomCircularButton.dart';
import '../../components/CustomOnClickContainer.dart';
import '../../components/CustomProject.dart';
import '../../components/EllipsisText.dart';
import '../../data/HomePagePostData.dart';
import '../../supabase/SupabaseConfig.dart';

class DisplayPostMediaPage extends StatefulWidget {
  final bool fromHome;
  final int? startAt;
  final HomePagePostData homePagePostData;
  final CommentsNotifier commentsNotifier;
  final LikesNotifier likesNotifier;
  final RepostsNotifier repostsNotifier;
  final PostProfileNotifier postProfileNotifier;
  final Function(String operation) onClickedQuick;

  const DisplayPostMediaPage({
    super.key,
    this.startAt,
    required this.onClickedQuick,
    required this.commentsNotifier,
    required this.likesNotifier,
    required this.homePagePostData,
    required this.repostsNotifier,
    required this.postProfileNotifier,
    this.fromHome = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _DisplayPostMediaPageState();
  }
}

class _DisplayPostMediaPageState extends State<DisplayPostMediaPage> {
  bool isAnyBarVisible = true;
  WidgetStateNotifier<bool> anyBarVisibleNotifier =
      WidgetStateNotifier(currentValue: true);
  Timer? timer;
  PageController? pageController;
  Map<int, CustomVideoPlayerController> videoController = {};
  int currentView = 0;
  bool notVideo = false;

  @override
  void initState() {
    super.initState();
    setDarkUiViewOverlay();
    currentView = widget.startAt ?? currentView;
    pageController = PageController(initialPage: widget.startAt ?? 0);
    dismissTitleBar(anyBarVisibleNotifier.currentValue ?? isAnyBarVisible);
  }

  void performBackPressed() {
    if (widget.fromHome) {
      setNormalUiViewOverlay();
    } else {
      setLightUiViewOverlay();
    }
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
        isAnyBarVisible = false;
        anyBarVisibleNotifier.sendNewState(isAnyBarVisible);
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

    videoController.values.forEach((element) {
      element.areControlsVisible.removeListener(controlIsBarVisible);
      element.dispose();
    });
  }

  void handleMediaChanged(index) {
    currentView = index;
    List<CustomVideoPlayerController> videoControllers =
        videoController.values.toList();

    videoControllers.forEach((element) {
      if (element.hashCode !=
          videoController.values.elementAtOrNull(index).hashCode) {
        element.videoPlayerController.seekTo(Duration());
        element.videoPlayerController.pause();
      }
    });
  }

  void controlIsBarVisible() {
    CustomVideoPlayerController? customVideoPlayerController =
        videoController.values.elementAtOrNull(currentView);

    if (customVideoPlayerController != null && !notVideo) {
      isAnyBarVisible = customVideoPlayerController.areControlsVisible.value;
      anyBarVisibleNotifier.sendNewState(isAnyBarVisible);
      dismissTitleBar(anyBarVisibleNotifier.currentValue ?? isAnyBarVisible);
    } else {
      isAnyBarVisible = !isAnyBarVisible;
      anyBarVisibleNotifier.sendNewState(isAnyBarVisible);
      dismissTitleBar(anyBarVisibleNotifier.currentValue ?? isAnyBarVisible);
    }
    notVideo = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          notVideo = true;
          controlIsBarVisible();
        },
        onVerticalDragEnd: (details) {
          notVideo = true;
          controlIsBarVisible();
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
                  controller: pageController,
                  onPageChanged: handleMediaChanged,
                  children: widget.homePagePostData.postMedia
                      .asMap()
                      .map((key, mediaType) => MapEntry(
                          key,
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: getScreenHeight(context) * 0.25),
                            child: getMediaViewer(key, mediaType),
                          )))
                      .values
                      .toList(),
                ),
              ),

              // Profile Header

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: StreamBuilder(
                    initialData: anyBarVisibleNotifier.currentValue,
                    stream: anyBarVisibleNotifier.stream,
                    builder: (context, snapshot) {
                      return AnimatedOpacity(
                        opacity: (snapshot.data ?? isAnyBarVisible) ? 1.0 : 0.0,
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
                                    child: WidgetStateConsumer(
                                        widgetStateNotifier:
                                            widget.postProfileNotifier.state,
                                        widgetStateBuilder: (context, data) {
                                          return Text(
                                            data?.fullName ?? "Error",
                                            textScaler: TextScaler.noScaling,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          );
                                        }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: WidgetStateConsumer(
                    widgetStateNotifier: anyBarVisibleNotifier,
                    widgetStateBuilder: (context, snapshot) {
                      return AnimatedOpacity(
                          opacity: (snapshot ?? isAnyBarVisible) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: EllipsisText(
                                  text: widget.homePagePostData.postText,
                                  maxLength: 150,
                                  onMorePressed: () {},
                                  textStyle: TextStyle(
                                      color: Colors.white, fontSize: 14),
                                  moreText: 'more',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16, right: 16, top: 16, bottom: 32),
                                child: WidgetStateConsumer(
                                    widgetStateNotifier:
                                        widget.likesNotifier.state,
                                    widgetStateBuilder: (context, likesData) {
                                      String thisUser = SupabaseConfig
                                              .client.auth.currentUser?.id ??
                                          '';
                                      bool isLiked = likesData
                                              ?.where((element) =>
                                                  element.membersId == thisUser)
                                              .isNotEmpty ??
                                          false;

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          getQuickButton(
                                              Icons.thumb_up,
                                              "Like",
                                              isLiked,
                                              (likesData?.length ?? 0)),
                                          WidgetStateConsumer(
                                              widgetStateNotifier:
                                                  widget.commentsNotifier.state,
                                              widgetStateBuilder:
                                                  (context, commentsData) {
                                                String thisUser = SupabaseConfig
                                                        .client
                                                        .auth
                                                        .currentUser
                                                        ?.id ??
                                                    '';
                                                int comments = (commentsData
                                                            ?.length ??
                                                        0) +
                                                    (commentsData?.fold(
                                                            0,
                                                            (previousValue,
                                                                    element) =>
                                                                (previousValue ??
                                                                    0) +
                                                                element
                                                                    .commentsPost
                                                                    .length) ??
                                                        0);
                                                bool commented = false;
                                                bool stop = false;
                                                commentsData?.forEach((main) {
                                                  if (!stop) {
                                                    commented =
                                                        main.commentBy ==
                                                            thisUser;
                                                    stop = commented;
                                                  }
                                                  main.commentsPost
                                                      .forEach((sub) {
                                                    if (!stop) {
                                                      commented =
                                                          sub.commentBy ==
                                                              thisUser;
                                                      stop = commented;
                                                    }
                                                  });
                                                });
                                                return getQuickButton(
                                                    Icons.message_outlined,
                                                    "Comment",
                                                    commented,
                                                    comments);
                                              }),
                                          WidgetStateConsumer(
                                              widgetStateNotifier:
                                                  widget.repostsNotifier.state,
                                              widgetStateBuilder:
                                                  (context, repostData) {
                                                int reposts =
                                                    repostData?.length ?? 0;
                                                String thisUser = SupabaseConfig
                                                        .client
                                                        .auth
                                                        .currentUser
                                                        ?.id ??
                                                    '';

                                                bool reposted = repostData
                                                        ?.where((element) =>
                                                            element.postBy ==
                                                            thisUser)
                                                        .isNotEmpty ??
                                                    false;

                                                return getQuickButton(
                                                    Icons.repeat,
                                                    "Repost",
                                                    reposted,
                                                    reposts);
                                              }),
                                        ],
                                      );
                                    }),
                              ),
                            ],
                          ));
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget imageViewer(String imageUri) {
    return Center(
      child: PhotoViewGallery.builder(
        itemCount: 1,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(
              imageUri,
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
    );
  }

  Widget getQuickButton(
      IconData iconData, String text, bool state, int counts) {
    return CustomOnClickContainer(
      onTap: () {
        widget.onClickedQuick(text);
      },
      defaultColor: Colors.transparent,
      clickedColor: Colors.grey.shade400,
      shape: BoxShape.circle,
      child: Row(
        children: [
          Icon(
            iconData,
            color: state ? Colors.white : Colors.white.withOpacity(0.5),
            size: 24,
          ),
          SizedBox(
            width: 4,
          ),
          Builder(builder: (context) {
            return Text(counts.toString(),
                style: TextStyle(
                    color: state ? Colors.white : Colors.white.withOpacity(0.5),
                    fontSize: 14));
          })
        ],
      ),
    );
  }

  Widget getMediaViewer(int index, HomePageMediaData mediaType) {
    return switch (mediaType.mediaType) {
      HomePageMediaType.image => imageViewer(mediaType.mediaData),
      HomePageMediaType.video => getVideoPlayerWidget(index, mediaType),
      HomePageMediaType.document => SizedBox(),
    };
  }

  Widget getVideoPlayerWidget(int index, HomePageMediaData mediaType) {
    VideoPlayerController controller =
        VideoPlayerController.networkUrl(Uri.parse(mediaType.mediaData));

    CustomVideoPlayerSettings customVideoPlayerSettings =
        CustomVideoPlayerSettings(
            playOnlyOnce: false,
            showDurationPlayed: false,
            showFullscreenButton: false,
            alwaysShowThumbnailOnVideoPaused: true,
            durationAfterControlsFadeOut: Duration(seconds: 2));

    CustomVideoPlayerController customVideoPlayerController =
        CustomVideoPlayerController(
            customVideoPlayerSettings: customVideoPlayerSettings,
            context: context,
            videoPlayerController: controller);

    videoController[index] = customVideoPlayerController;

    videoController[index]?.areControlsVisible.addListener(controlIsBarVisible);
    videoController[index]?.videoPlayerController.setLooping(true);

    return CachedVideoPlayer(
      aspectRatio: 1 / 1,
      videoUrl: Uri.parse(mediaType.mediaData),
      placeholder: progressBarWidget(),
      controller: customVideoPlayerController,
    );
  }
}
