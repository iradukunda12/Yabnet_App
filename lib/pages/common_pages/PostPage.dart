import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/builders/CustomWrapListBuilder.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';
import 'package:yabnet/components/CustomPrimaryButton.dart';
import 'package:yabnet/data/ConnectInfo.dart';
import 'package:yabnet/drawer/ProfileDrawer.dart';
import 'package:yabnet/main.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/operations/PostOperation.dart';
import 'package:yabnet/pages/common_pages/CheckUploadPostMediaPage.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../../collections/common_collection/ProfileImage.dart';
import '../../components/CustomButtonRefreshCard.dart';
import '../../components/CustomCircularButton.dart';
import '../../components/CustomProject.dart';
import '../../components/CustomWrappingLayout.dart';
import '../../components/FeatureComingSoonWidget.dart';
import '../../components/IconListView.dart';
import '../../components/WrappingSilverAppBar.dart';
import '../../data/HomePagePostData.dart';
import '../../data/UserData.dart';
import '../../data_notifiers/ProfileNotifier.dart';
import '../../data_notifiers/UserConnectsNotifier.dart';
import '../../db_references/Post.dart';
import '../../handler/HomePageMediaHandler.dart';
import 'ProfilePage.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> implements UserConnectsImplement {
  TextEditingController postTextController = TextEditingController();
  WidgetStateNotifier<IconListDisplay> iconViewNotifier =
      WidgetStateNotifier(currentValue: IconListDisplay.normal);
  WidgetStateNotifier<bool> postButtonNotifier = WidgetStateNotifier();
  WidgetStateNotifier<List<HomePageMediaData>> mediaSelectionNotifier =
      WidgetStateNotifier();
  TextEditingController mentionSearchController = TextEditingController();

  RetryStreamListener connectionRetryStreamListener = RetryStreamListener();

  UserConnectsStack userConnectsStack = UserConnectsStack();

  WidgetStateNotifier<List<ConnectInfo>> mentionsNotifier =
      WidgetStateNotifier(currentValue: []);

  @override
  BuildContext? getLatestContext() {
    return context;
  }

  @override
  RetryStreamListener? getRetryStreamListener() {
    return connectionRetryStreamListener;
  }

  @override
  void initState() {
    super.initState();
    hideKeyboard(context);
    postButtonNotifier.addController(postTextController, (notifier) {
      notifier.sendNewState(postTextController.text.isNotEmpty ||
          (mediaSelectionNotifier.currentValue?.isNotEmpty ?? false));
    });
  }

  @override
  void dispose() {
    super.dispose();
    postTextController.dispose();
    mentionSearchController.dispose();
    hideKeyboard(context);
  }

  void onTapImage(int index) async {
    Future<List<String?>?> picker = Platform.isIOS
        ? FilePicker.platform
            .pickFiles(type: FileType.image, allowMultiple: true)
            .then<List<String?>?>((value) => value?.paths)
        : ImagePicker()
            .pickMultiImage()
            .then<List<String?>?>((value) => value.map((e) => e.path).toList());

    picker.then((value) {
      List<HomePageMediaData> media = [];
      final images = value
          ?.map((e) => HomePageMediaData(HomePageMediaType.image, e ?? ""))
          .toList();
      media.addAll(mediaSelectionNotifier.currentValue ?? []);
      media.addAll(images ?? []);
      if (images?.isNotEmpty == true) {
        startProgressPeriodForMedia();
      }
      mediaSelectionNotifier.sendNewState(media);
    });
  }

  void startProgressPeriodForMedia() {
    showCustomProgressBar(context);
    Timer(Duration(milliseconds: 1300), () {
      closeCustomProgressBar(context);
    });
  }

  void onTapVideo(int index) {
    Future<List<String?>?> picker = FilePicker.platform
        .pickFiles(type: FileType.video, allowMultiple: true)
        .then<List<String?>?>((value) => value?.paths);

    picker.then((value) {
      List<HomePageMediaData> media = [];

      final videos = value
          ?.map((e) => HomePageMediaData(HomePageMediaType.video, e ?? ""))
          .toList();
      media.addAll(mediaSelectionNotifier.currentValue ?? []);
      media.addAll(videos ?? []);
      if (videos?.isNotEmpty == true) {
        startProgressPeriodForMedia();
      }
      mediaSelectionNotifier.sendNewState(media);
    });
  }

  Future<void> onTapMention(int index) async {
    final mentions = await onGetMention();
    mentionSearchController.clear();
    if (mentions.isNotEmpty) {
      mentionsNotifier.sendNewState(mentions);
    }
  }

  Future<List<ConnectInfo>> onGetMention() async {
    List<ConnectInfo> selectedUsers = mentionsNotifier.currentValue ?? [];
    WidgetStateNotifier<String> searchNotifier = WidgetStateNotifier();
    WidgetStateNotifier<bool> loading = WidgetStateNotifier();
    Timer? timer;
    String text = '';
    mentionSearchController.addListener(() {
      String newText = mentionSearchController.text.trim();

      if (text != newText) {
        searchNotifier.sendNewState(newText.trim());
      }
      text = newText;
    });

    await openBottomSheet(
        context,
        SizedBox(
          height: getScreenHeight(context) * 0.75,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 4,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Icon(Icons.cancel),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),

                  WidgetStateConsumer(
                      widgetStateNotifier: loading,
                      widgetStateBuilder: (context, data) {
                        return Row(
                          children: [
                            CustomOnClickContainer(
                                defaultColor: Colors.transparent,
                                clickedColor: Colors.grey.shade200,
                                padding: EdgeInsets.all(6),
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  UserConnectsNotifier().restart(true, true);
                                  loading.sendNewState(true);
                                  timer?.cancel();
                                  timer = Timer(Duration(seconds: 5), () {
                                    loading.sendNewState(false);
                                  });
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      "Refresh",
                                      style: TextStyle(
                                          color: Colors.black.withOpacity(0.8),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    (data ?? false)
                                        ? SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: progressBarWidget(
                                                size: 10, pad: 4))
                                        : Icon(
                                            Icons.sync,
                                            size: 14,
                                          )
                                  ],
                                )),
                          ],
                        );
                      }),

                  TextField(
                    controller: mentionSearchController,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none),
                        hintText: "eg: John",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black,
                        )),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Expanded(
                    child: MultiWidgetStateConsumer(
                        widgetStateListNotifiers: [
                          UserConnectsNotifier().state,
                          searchNotifier
                        ],
                        widgetStateListBuilder: (
                          context,
                        ) {
                          final connections = UserConnectsNotifier()
                              .state
                              .currentValue
                              ?.connection;
                          final filterText = searchNotifier.currentValue;
                          if (connections == null ||
                              connections.isEmpty == true) {
                            return Center(
                                child: CustomButtonRefreshCard(
                                    topIcon: const Icon(
                                      Icons.not_interested,
                                      size: 50,
                                    ),
                                    retryStreamListener:
                                        connectionRetryStreamListener,
                                    displayText:
                                        "There are no user connections yet."));
                          }

                          final displayConnection = connections
                              .where((element) =>
                                  element.membersFullname
                                      .toLowerCase()
                                      .contains(
                                          filterText?.toLowerCase() ?? '') ||
                                  (filterText?.isEmpty ?? true))
                              .toList();

                          return CustomWrapListBuilder(
                              retryStreamListener:
                                  connectionRetryStreamListener,
                              itemCount: displayConnection.length,
                              wrapListBuilder: (context, index) {
                                ConnectInfo connectInfo =
                                    displayConnection[index];

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child:
                                      StatefulBuilder(builder: (context, set) {
                                    List<String> selectionIds = selectedUsers
                                        .map((e) => e.membersId)
                                        .toList();

                                    return CustomOnClickContainer(
                                      onTap: () {
                                        set(() {
                                          if (selectionIds.contains(
                                              connectInfo.membersId)) {
                                            selectedUsers.removeWhere(
                                                (element) =>
                                                    element.membersId ==
                                                    connectInfo.membersId);
                                          } else if (!selectionIds.contains(
                                              connectInfo.membersId)) {
                                            selectedUsers.add(connectInfo);
                                          }
                                        });
                                      },
                                      defaultColor: Colors.transparent,
                                      clickedColor: Colors.grey.shade100,
                                      child: Row(children: [
                                        Checkbox(
                                            value: selectionIds.contains(
                                                connectInfo.membersId),
                                            onChanged: (check) {
                                              set(() {
                                                if (check == true) {
                                                  selectedUsers
                                                      .add(connectInfo);
                                                } else if (check == false) {
                                                  selectedUsers.removeWhere(
                                                      (element) =>
                                                          element.membersId ==
                                                          connectInfo
                                                              .membersId);
                                                }
                                              });
                                            }),
                                        Container(
                                            height: 40,
                                            width: 40,
                                            clipBehavior: Clip.hardEdge,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey.shade300,
                                            ),
                                            child: ProfileImage(
                                              iconSize: 40,
                                              textSize: 16,
                                              canDisplayImage: true,
                                              imageUri: MembersOperation()
                                                  .getMemberProfileBucketPath(
                                                      connectInfo.membersId,
                                                      connectInfo
                                                          .membersProfileIndex),
                                              fullName:
                                                  connectInfo.membersFullname,
                                            )),
                                        const SizedBox(
                                          width: 8,
                                        ),
                                        Expanded(
                                            child: Text(
                                          connectInfo.membersFullname,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ))
                                      ]),
                                    );
                                  }),
                                );
                              });
                        }),
                  ),
                  //   Continue
                  const SizedBox(
                    height: 8,
                  ),
                ]),
          ),
        ),
        color: Colors.grey.shade200);
    return selectedUsers;
  }

  void onTapTemplate(int index) {
    showDialog(
        context: context,
        builder: (context) {
          return FeatureComingSoon(
            icon: Icons.ten_mp,
            featureName: 'Template Post',
            description:
                "Template Post is the ultimate solution to simplify your content creation process. Say goodbye to writer's block and hello to beautifully crafted posts in seconds",
          );
        });
  }

  void onTapEvent(int index) {
    showDialog(
        context: context,
        builder: (context) {
          return FeatureComingSoon(
            icon: Icons.event_note_outlined,
            featureName: 'Event Post',
            description:
                "Soon, you'll be able to easily create and share events right from our platform! Whether it's a conference, webinar, workshop, or social gathering, Event Posting will make it simple to spread the word and gather attendees.",
          );
        });
  }

  void onTapPoll(int index) {
    showDialog(
        context: context,
        builder: (context) {
          return FeatureComingSoon(
            icon: Icons.poll,
            featureName: 'Poll Post',
            description:
                "Cast your vote now and be a part of the decision-making process",
          );
        });
  }

  void onTapDocument(int index) {
    showDialog(
        context: context,
        builder: (context) {
          return FeatureComingSoon(
            icon: Icons.file_present_sharp,
            featureName: 'Document',
            description:
                "Document Posting makes it simple to upload and share your valuable content with your audience.",
          );
        });
  }

  void onTapServices(int index) {
    showDialog(
        context: context,
        builder: (context) {
          return FeatureComingSoon(
            icon: Icons.person_search_outlined,
            featureName: 'Services',
            description:
                "Cast your vote now and be a part of the decision-making process.",
          );
        });
  }

  void onTapSchedule() {
    showDialog(
        context: context,
        builder: (context) {
          return FeatureComingSoon(
            icon: Icons.schedule,
            featureName: 'Schedule Post',
            description:
                "Get ready to take control of your content schedule! Soon, you'll be able to schedule your posts to go live at a later time.",
          );
        });
  }

  List<IconView> get iconView => [
        IconView(
            canDisable: false,
            Icon(Icons.person_pin_outlined,
                color: Color(getDarkGreyColor), size: 28),
            Text(
              "Mentions",
              style: TextStyle(fontSize: 14, color: Color(getDarkGreyColor)),
            ),
            onTapMention),
        IconView(
            canDisable: false,
            Icon(Icons.image_outlined,
                color: Color(getDarkGreyColor), size: 28),
            Text(
              "Image",
              style: TextStyle(fontSize: 14, color: Color(getDarkGreyColor)),
            ),
            onTapImage),
        IconView(
            canDisable: false,
            Icon(Icons.videocam, color: Color(getDarkGreyColor), size: 28),
            Text(
              "Video",
              style: TextStyle(fontSize: 14, color: Color(getDarkGreyColor)),
            ),
            onTapVideo),
        IconView(
            Icon(Icons.ten_mp, color: Color(getDarkGreyColor), size: 28),
            Text(
              "Template",
              style: TextStyle(fontSize: 14, color: Color(getDarkGreyColor)),
            ),
            onTapTemplate),
        IconView(
            Icon(Icons.event_note_outlined,
                color: Color(getDarkGreyColor), size: 28),
            Text(
              "Event",
              style: TextStyle(fontSize: 14, color: Color(getDarkGreyColor)),
            ),
            onTapEvent),
        IconView(
            Icon(Icons.poll, color: Color(getDarkGreyColor), size: 28),
            Text(
              "Poll",
              style: TextStyle(fontSize: 14, color: Color(getDarkGreyColor)),
            ),
            onTapPoll),
        IconView(
            Icon(Icons.file_present_sharp,
                color: Color(getDarkGreyColor), size: 28),
            Text(
              "Document",
              style: TextStyle(fontSize: 14, color: Color(getDarkGreyColor)),
            ),
            onTapDocument),
        IconView(
            Icon(Icons.person_search_outlined,
                color: Color(getDarkGreyColor), size: 28),
            Text(
              "Services",
              style: TextStyle(fontSize: 14, color: Color(getDarkGreyColor)),
            ),
            onTapServices),
      ];

  void openNavigationBar(BuildContext scaffoldContext) {
    Scaffold.of(scaffoldContext).openDrawer();
  }

  void getExtendedIconView(BuildContext thisContext) async {
    await openBottomSheet(
            thisContext,
            Container(
              height: getScreenHeight(context) * 0.4,
              child: Builder(builder: (context) {
                iconViewNotifier.sendNewState(IconListDisplay.extended);
                return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 24),
                    child: Column(
                      children: createSubgroups(iconView, 3)
                          .asMap()
                          .map((key, eachGroup) {
                            return MapEntry(
                                key,
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: CustomWrappingLayout(
                                    wlChildren: eachGroup
                                        .asMap()
                                        .map((key, iconView) {
                                          return MapEntry(
                                              key,
                                              WLView(
                                                  expandMain: true,
                                                  child: CustomOnClickContainer(
                                                    defaultColor:
                                                        Colors.transparent,
                                                    clickedColor:
                                                        Colors.grey.shade200,
                                                    onTap: () {
                                                      iconView.onTap(key);
                                                    },
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          iconView.icon,
                                                          SizedBox(
                                                            height: 5,
                                                          ),
                                                          iconView.text
                                                        ]),
                                                  )));
                                        })
                                        .values
                                        .toList(),
                                  ),
                                ));
                          })
                          .values
                          .toList(),
                    ));
              }),
            ),
            color: Colors.grey.shade200)
        .whenComplete(() {
      iconViewNotifier.sendNewState(IconListDisplay.normal);
    });
  }

  void onTapMore() {
    getExtendedIconView(context);
  }

  void viewPostOperation(Map postData) async {
    hideKeyboard(context);
    FocusScopeNode focusScopeNode = FocusScope.of(context);
    focusScopeNode.requestFocus(FocusNode());

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProfilePage(
                  homePagePostMapData: postData,
                )));
  }

  void clickedOnPost() async {
    showCustomProgressBar(context);
    try {
      void clearOperation() {
        postTextController.clear();
        mediaSelectionNotifier.sendNewState(null);
        mentionsNotifier.sendNewState(null);
        showToastMobile(msg: "You have added a new post!");
      }

      void afterAllPostHasBeenAdded(
          Map postData, String postId, bool postVerification) async {
        if (!postVerification) {
          // Update post verified
          final verified = await PostOperation()
              .updatePostVerification(postId, !postVerification);
          if (verified != null) {
            // Delete Temp folder
            PostOperation().deleteFolder(postId).then((value) {
              clearOperation();
              closeCustomProgressBar(context);
              viewPostOperation(postData);
            }).onError((error, stackTrace) {
              // Failed to remove folder
              PostOperation().scheduleFolderDeletion(postId);
              clearOperation();
              showToastMobile(msg: "An error has occurred");
              showDebug(msg: "$error $stackTrace");
              closeCustomProgressBar(context);
            });
          }
        } else {
          clearOperation();
          closeCustomProgressBar(context);
          viewPostOperation(postData);
        }
      }

      // Get post text
      String postText = postTextController.text.toString().trim();
      // Get members id
      String? membersId = SupabaseConfig.client.auth.currentUser?.id;

      // Check for existence
      if (membersId == null) {
        showToastMobile(msg: "An unexpected error has occurred");
        closeCustomProgressBar(context);
        return;
      }
      // Start posting
      List<HomePageMediaData> media = mediaSelectionNotifier.currentValue ?? [];

      // Map out media files
      final imageMedia = await media
          .where((element) => element.mediaType == HomePageMediaType.image)
          .map((image) => FlutterNativeImage.compressImage(image.mediaData,
                  quality: 100, percentage: 100)
              .then((compressedImage) async => HomePageMediaTypeData(
                  await compressedImage.readAsBytes(),
                  PostOperation().getExtension(compressedImage.path, "image"))))
          .toList();

      final videoMedia = media
          .where((element) => element.mediaType == HomePageMediaType.video)
          .map((video) => VideoCompress.compressVideo(video.mediaData,
                      quality: VideoQuality.LowQuality)
                  .then((compressedVideo) async {
                File? file = compressedVideo?.file;

                if (file == null) {
                  return null;
                }
                return HomePageMediaTypeData(await file.readAsBytes(),
                    PostOperation().getExtension(file.path, "video"));
              }));

      // Get the file future for image
      Future<List<HomePageMediaTypeData?>> mediaByteFuture =
          Future.wait([...imageMedia]);

      // Return the file data
      List<HomePageMediaTypeData?> getMediaFutureResult = await mediaByteFuture;

      // Get file future for video
      if (videoMedia.isNotEmpty) {
        await Future.forEach(videoMedia, (element) async {
          final data = await element;
          getMediaFutureResult.add(data);
        });
      }

      // Remove null data and handle them
      getMediaFutureResult.removeWhere((element) => element == null);

      // Cast the remaining media
      List<HomePageMediaTypeData> getMediaBytes = getMediaFutureResult.cast();

      // Post has media
      int hasMedia = getMediaBytes.length;

      // Get any mentions

      List<String> postMentions =
          (mentionsNotifier.currentValue?.map((e) => e.membersId))?.toList() ??
              [];

      int hasMentions = postMentions.length;
      bool postVerified =
          getMediaBytes.isNotEmpty || postMentions.isNotEmpty ? false : true;

      // Send a new post
      final post = await PostOperation().sendANewPost(
          postText, membersId, hasMedia, hasMentions, postVerified);

      //     Post is sent already but verified if media is attached
      if (post != null) {
        // Post identity
        String postId = post[dbReference(Post.id)];

        if (getMediaBytes.isNotEmpty) {
          // Start media attachment
          // Create a temp directory
          final mediaBytes = await PostOperation().createTempFolder(
              getMediaBytes.map((e) => e.data).toList(), postId);

          if (mediaBytes.isNotEmpty) {
            //     Start uploading media
            final uploads = mediaBytes
                .asMap()
                .map((index, mediaByte) => MapEntry(
                    index,
                    PostOperation().uploadPostMedia(
                        postId, index, mediaByte, getMediaBytes[index].type)))
                .values
                .toList();

            final uploadOperation = await Future.wait(uploads);

            if (uploadOperation.isNotEmpty && postMentions.isNotEmpty) {
              final mentions = postMentions
                  .asMap()
                  .map((index, membersId) => MapEntry(index,
                      PostOperation().uploadPostMentions(postId, membersId)))
                  .values
                  .toList();

              final mentionOperation = await Future.wait(mentions);

              if (mentionOperation.isNotEmpty) {
                afterAllPostHasBeenAdded(post, postId, postVerified);
              }
            } else if (uploadOperation.isNotEmpty) {
              afterAllPostHasBeenAdded(post, postId, postVerified);
            } else {
              showToastMobile(msg: "An error has occurred");
              closeCustomProgressBar(context);
            }
          } else {
            //   Upload failed
            showToastMobile(msg: "An error has occurred");
            closeCustomProgressBar(context);
          }
        } else {
          if (postMentions.isNotEmpty) {
            final mentions = postMentions
                .asMap()
                .map((index, membersId) => MapEntry(index,
                    PostOperation().uploadPostMentions(postId, membersId)))
                .values
                .toList();

            final mentionOperation = await Future.wait(mentions);

            if (mentionOperation.isNotEmpty) {
              afterAllPostHasBeenAdded(post, postId, postVerified);
            }
          } else {
            afterAllPostHasBeenAdded(post, postId, postVerified);
          }
        }
      } else {
        // Post was not added
        showToastMobile(msg: "An error with post addition");
        closeCustomProgressBar(context);
      }
    } catch (error, stackTrace) {
      // Catch uncaught error here
      closeCustomProgressBar(context);
      showToastMobile(msg: "An error has occurred");
      showDebug(msg: "$error $stackTrace");
    }
  }

  void handleMediaClicked(int? at) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CheckUploadPostMediaPage(
                mediaSelectionNotifier: mediaSelectionNotifier,
                startAt: at ?? 0))).then((value) {
      setNormalUiViewOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: ProfileDrawer(),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              WrappingSliverAppBar(
                  titleSpacing: 0,
                  elevation: 0,
                  pinned: true,
                  forceMaterialTransparency: true,
                  title: Container(
                    color: Colors.white,
                    child: Column(children: [
                      // Top buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        child: Row(
                          children: [
                            CustomOnClickContainer(
                              onTap: () {
                                openNavigationBar(context);
                              },
                              defaultColor: Colors.grey.shade200,
                              clickedColor: Colors.grey.shade300,
                              height: 45,
                              width: 45,
                              clipBehavior: Clip.hardEdge,
                              shape: BoxShape.circle,
                              child: WidgetStateConsumer(
                                  widgetStateNotifier: ProfileNotifier().state,
                                  widgetStateBuilder: (context, snapshot) {
                                    UserData? userData = snapshot;
                                    return ProfileImage(
                                      fullName: snapshot?.fullName ?? 'Error',
                                      iconSize: 45,
                                      imageUri: MembersOperation()
                                          .getMemberProfileBucketPath(
                                              snapshot?.userId ?? '',
                                              snapshot?.profileIndex),
                                      imageUrl: (imageAddress) {},
                                    );
                                  }),
                            ),

                            SizedBox(
                              width: 8,
                            ),

                            Expanded(
                                child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                StreamBuilder(
                                    initialData:
                                        ProfileNotifier().state.currentValue,
                                    stream: ProfileNotifier().state.stream,
                                    builder: (context, snapshot) {
                                      String location =
                                          "${snapshot.data?.location}";
                                      location = "Anyone can view";
                                      return Text(
                                        location,
                                        style: TextStyle(
                                            color: Color(getDarkGreyColor),
                                            fontSize: 17),
                                      );
                                    }),
                                if (2 == 4)
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Color(getDarkGreyColor),
                                  )
                              ],
                            )),

                            // Schedule
                            if (2 == 4)
                              CustomCircularButton(
                                imagePath: null,
                                mainAlignment: Alignment.center,
                                iconColor: Color(getDarkGreyColor),
                                onPressed: onTapSchedule,
                                icon: Icons.schedule,
                                gap: 8,
                                width: 45,
                                height: 45,
                                iconSize: 35,
                                defaultBackgroundColor: Colors.transparent,
                                colorImage: true,
                                showShadow: false,
                                clickedBackgroundColor:
                                    const Color(getDarkGreyColor)
                                        .withOpacity(0.4),
                              ),

                            SizedBox(
                              width: 5,
                            ),
                            WidgetStateConsumer(
                                widgetStateNotifier: postButtonNotifier,
                                widgetStateBuilder: (context, snapshot) {
                                  return CustomPrimaryButton(
                                      buttonText: "Post",
                                      expanded: false,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      borderRadius: 50,
                                      isEnabled: snapshot ?? false,
                                      onTap: clickedOnPost);
                                })
                          ],
                        ),
                      ),
                    ]),
                  ))
            ];
          },
          body: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      WidgetStateConsumer(
                          widgetStateNotifier: iconViewNotifier,
                          widgetStateBuilder: (context, snapshot) {
                            bool isDisabled =
                                snapshot == IconListDisplay.disable;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: IconListView(
                                disabledColor: Colors.grey.shade400,
                                iconViews: iconView
                                    .asMap()
                                    .map((key, iconViews) => MapEntry(
                                        key,
                                        IconView(iconViews.icon, iconViews.text,
                                            iconViews.onTap,
                                            disabled: isDisabled &&
                                                    iconViews.canDisable ||
                                                snapshot ==
                                                    IconListDisplay.extended)))
                                    .values
                                    .toList(),
                                limitTo: 4,
                                moreIcon: Icon(Icons.more_horiz,
                                    color: isDisabled
                                        ? Colors.grey.shade400
                                        : Color(getDarkGreyColor),
                                    size: 28),
                                moreSpace: isDisabled ? 0 : 8,
                                onTappedMore: isDisabled ? null : onTapMore,
                              ),
                            );
                          }),

                      WidgetStateConsumer(
                          widgetStateNotifier: mentionsNotifier,
                          widgetStateBuilder: (context, state) {
                            if (state?.isNotEmpty == true) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          for (int index = 0;
                                              index < (state?.length ?? 0);
                                              index++)
                                            Builder(builder: (context) {
                                              ConnectInfo connectInfo =
                                                  state![index];
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 16, top: 16),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 10),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Color(getMainPinkColor),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        "@ ",
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey.shade300,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14),
                                                      ),
                                                      Text(
                                                        connectInfo
                                                            .membersFullname,
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey.shade300,
                                                            fontSize: 14),
                                                      ),
                                                      SizedBox(width: 8),
                                                      GestureDetector(
                                                        onTap: () {
                                                          mentionsNotifier.sendNewState(
                                                              mentionsNotifier
                                                                  .currentValue
                                                                  ?.where((element) =>
                                                                      element
                                                                          .membersId !=
                                                                      connectInfo
                                                                          .membersId)
                                                                  .toList());
                                                        },
                                                        child: Icon(
                                                            Icons.cancel,
                                                            color: Colors
                                                                .grey.shade300,
                                                            size: 20),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            })
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return SizedBox(
                              height: 8,
                            );
                          }),

                      SizedBox(
                        height: 8,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: postTextController,
                          maxLines: 5,
                          minLines: 2,
                          maxLength: 250,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "Engage your opinions...",
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                          ),
                        ),
                      ),

                      //   ImageView For sending
                      SizedBox(
                        height: 24,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15)),
                          child: WidgetStateConsumer(
                              widgetStateNotifier: mediaSelectionNotifier,
                              widgetStateBuilder: (context, snapshot) {
                                bool hasData = snapshot?.isNotEmpty ?? false;
                                iconViewNotifier.sendNewState(hasData
                                    ? IconListDisplay.disable
                                    : IconListDisplay.normal);
                                postButtonNotifier.sendNewState(hasData ||
                                    postTextController.text.isNotEmpty);
                                return Stack(
                                  children: [
                                    HomePageMediaHandler(
                                      media: snapshot ?? [],
                                      height: 230,
                                      clicked: handleMediaClicked,
                                      width: getScreenWidth(context),
                                      device: true,
                                    ),
                                    Positioned.fill(
                                        child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          CustomOnClickContainer(
                                            onTap: () {
                                              mediaSelectionNotifier
                                                  .sendNewState(null);
                                            },
                                            shape: BoxShape.circle,
                                            defaultColor:
                                                Colors.black.withOpacity(0.7),
                                            clickedColor: Colors.grey.shade50,
                                            child: Padding(
                                              padding: const EdgeInsets.all(5),
                                              child: Icon(Icons.cancel,
                                                  color: Colors.white,
                                                  size: 24),
                                            ),
                                          )
                                        ],
                                      ),
                                    ))
                                  ],
                                );
                              }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              StreamBuilder(
                  stream: KeyboardVisibilityController().onChange,
                  builder: (context, snapshot) {
                    if (snapshot.data == false ||
                        snapshot.data == null ||
                        !snapshot.hasData) {
                      return SizedBox();
                    }
                    return Positioned(
                      left: 0,
                      right: 0,
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                      child: CustomOnClickContainer(
                        onTap: () {
                          hideKeyboard(context);
                        },
                        defaultColor: Colors.grey.shade200,
                        clickedColor: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Hide keyboard",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Icon(
                              Icons.cancel,
                              size: 24,
                              color: Colors.red,
                            ),
                            SizedBox(
                              width: 8,
                            )
                          ],
                        ),
                      ),
                    );
                  })
            ],
          ),
        ),
      ),
    );
  }
}
