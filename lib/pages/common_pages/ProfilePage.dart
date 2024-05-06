import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/data/UserConnectsData.dart';
import 'package:yabnet/data_notifiers/ProfileNotifier.dart';
import 'package:yabnet/data_notifiers/UserConnectsNotifier.dart';
import 'package:yabnet/handler/ProfilePageUserPostHandler.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/pages/common_pages/DisplayConnectInfoPage.dart';
import 'package:yabnet/pages/common_pages/EditPage.dart';
import 'package:yabnet/services/UserProfileService.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../../collections/common_collection/ProfileImage.dart';
import '../../components/CustomAppBar.dart';
import '../../components/CustomCircularButton.dart';
import '../../components/CustomOnClickContainer.dart';
import '../../components/CustomProject.dart';
import '../../components/CustomTextFilterScrollView.dart';
import '../../components/WrappingSilverAppBar.dart';
import '../../data/UserData.dart';
import '../../db_references/Connect.dart';
import '../../db_references/Profile.dart';
import '../../handler/ProfilePagePollHandler.dart';
import '../../main.dart';
import '../../operations/ProfileOperation.dart';
import 'SearchedPage.dart';
import 'SettingsPage.dart';

class ProfilePageHandlerData {
  final FilterItem filterItem;
  final Widget handler;

  ProfilePageHandlerData(this.filterItem, this.handler);
}

class ProfilePage extends StatefulWidget {
  final Map? homePagePostMapData;

  const ProfilePage({super.key, this.homePagePostMapData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    implements UserConnectsImplement {
  String? imageUrl;
  bool canOpen = true;

  ScrollController scrollController = ScrollController();
  TextFilterController typeFilterController = TextFilterController(toIndex: 0);
  WidgetStateNotifier<int> handlerNotifier =
      WidgetStateNotifier(currentValue: 0);
  UserConnectsStack userConnectsStack = UserConnectsStack();

  RetryStreamListener retryStreamListener = RetryStreamListener();

  List<ProfilePageHandlerData> get filterItemHandler => [
        ProfilePageHandlerData(
            FilterItem(filterText: "Posts"),
            ProfilePageUserPostHandler(
              homePagePostMapData: widget.homePagePostMapData,
            )),
        ProfilePageHandlerData(
            FilterItem(filterText: "Polls"), ProfilePagePollHandler()),
      ];

  @override
  BuildContext? getLatestContext() {
    return context;
  }

  @override
  RetryStreamListener? getRetryStreamListener() {
    return retryStreamListener;
  }

  @override
  void initState() {
    super.initState();
    setLightUiViewOverlay();
    hideKeyboard(context);
    retryStreamListener.addListener(listenToRetry);
  }

  void listenToRetry() {
    if (retryStreamListener.retrying) {
      UserConnectsNotifier().restart(true, true);
    }
  }

  @override
  void dispose() {
    super.dispose();
    typeFilterController.dispose();
    retryStreamListener.removeListener(listenToRetry);
  }

  void onChangeProfilePicture(BuildContext thisContext, bool? downloaded) {
    showMenu(
            context: thisContext,
            items: [
              // Upload
              PopupMenuItem(
                  child: Row(
                children: [
                  Expanded(
                    child: CustomOnClickContainer(
                        onTap: () {
                          Navigator.pop(context);
                          onUploadProfilePicture();
                        },
                        defaultColor: Colors.transparent,
                        clickedColor: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            downloaded != null ? "Change" : "Upload",
                            style: const TextStyle(fontSize: 18),
                            textScaleFactor: 1,
                          ),
                        )),
                  ),
                ],
              )),

              // Remove
              downloaded == true
                  ? PopupMenuItem(
                      child: Row(
                      children: [
                        Expanded(
                          child: CustomOnClickContainer(
                              onTap: () {
                                Navigator.pop(context);
                                onRemoveProfilePicture();
                              },
                              defaultColor: Colors.transparent,
                              clickedColor: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  "Remove",
                                  style: TextStyle(fontSize: 18),
                                  textScaleFactor: 1,
                                ),
                              )),
                        ),
                      ],
                    ))
                  : const PopupMenuItem(height: 0, child: SizedBox()),
            ],
            position: const RelativeRect.fromLTRB(0, 170, 0, 0))
        .then((value) {
      canOpen = true;
    });
  }

  void onRemoveProfilePicture() {
    openDialog(
        context,
        const Text(
          "Remove Image",
          style: TextStyle(color: Colors.red, fontSize: 17),
        ),
        const Text("Are you sure you want remove the picture?"),
        [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("No", style: TextStyle(fontSize: 15))),
          TextButton(
              onPressed: onConfirmRemoveProfilePicture,
              child: const Text("Yes", style: TextStyle(fontSize: 15))),
        ],
        color: Colors.grey.shade200);
  }

  void onConfirmRemoveProfilePicture() async {
    Navigator.pop(context);
    showCustomProgressBar(context);
    final id = SupabaseConfig.client.auth.currentUser?.id ?? "";
    final lastIndex = await MembersOperation()
        .getUserRecord(field: dbReference(Profile.image_index));

    // Future remove online image
    final lastImagePath = "${id}_$lastIndex";
    final removingPath = [lastImagePath];
    final removeLastImage = SupabaseConfig.client.storage
        .from(dbReference(Profile.bucket))
        .remove(removingPath);

    // Future to notify the index change
    final updateIndex = ProfileOperation().saveUserProfileIndex("", id);

    // Delete cached image
    final lastImageUrl = SupabaseConfig.client.storage
        .from(dbReference(Profile.bucket))
        .getPublicUrl(lastImagePath);
    final removeCachedImage =
        DefaultCacheManager().removeFile(lastImageUrl).then((value) => true);

    //  Future to wait for partial operation
    final waitOperation = Future.wait([updateIndex, removeLastImage]);

    waitOperation.timeout(const Duration(minutes: 1)).then((value) {
      removeCachedImage.timeout(const Duration(minutes: 1)).then((value) {
        MembersOperation.updateTheValue(dbReference(Profile.image_index), null)
            .timeout(const Duration(minutes: 1))
            .then((value) {
          closeCustomProgressBar(context);
          showToastMobile(msg: "Successfully removed the image");
        });
      });
    }).onError((error, stackTrace) {
      showDebug(msg: "$error $stackTrace");
      closeCustomProgressBar(context);
      showToastMobile(msg: "Unable to perform action at the moment");
    });
  }

  void onUploadProfilePicture() async {
    try {
      final index = ProfileOperation().generateIndexCode();
      final lastIndex = await MembersOperation()
          .getUserRecord(field: dbReference(Profile.image_index));
      Future picker = Platform.isIOS
          ? FilePicker.platform
              .pickFiles(type: FileType.image)
              .then((value) => value?.paths.singleOrNull)
          : ImagePicker()
              .pickImage(source: ImageSource.gallery)
              .then((value) => value?.path);

      picker.then((image) {
        if (image == null) {
          showToastMobile(msg: "No image was selected");
          return;
        }

        showCustomProgressBar(context);

        FlutterNativeImage.compressImage(image, quality: 25, percentage: 75)
            .then((compressedFile) {
          compressedFile.readAsBytes().then((imageByte) {
            final id = SupabaseConfig.client.auth.currentUser?.id ?? "";
            final imagePath = "/${id}_$index";
            final imageExtension =
                compressedFile.path.split(".").last.toLowerCase();

            // Flag Uploading Profile
            UserProfileService().profilePictureUploading = true;

            // Future to change image
            final changeImage = SupabaseConfig.client.storage
                .from(dbReference(Profile.bucket))
                .uploadBinary(imagePath, imageByte,
                    fileOptions: FileOptions(
                        upsert: true, contentType: "image/$imageExtension"));

            // Future to delete last Index
            final lastImagePath = "${id}_$lastIndex";
            final removingPath = [lastImagePath];
            final removeLastImage = SupabaseConfig.client.storage
                .from(dbReference(Profile.bucket))
                .remove(removingPath);

            // Future to save Index
            final updateIndex =
                ProfileOperation().saveUserProfileIndex(index, id);

            // Delete previous image
            final lastImageUrl = SupabaseConfig.client.storage
                .from(dbReference(Profile.bucket))
                .getPublicUrl(lastImagePath);
            final removeCachedImage = DefaultCacheManager()
                .removeFile(lastImageUrl)
                .then((value) => true);

            // Future to wait for operation
            final waitForOperation = Future.wait(
                [updateIndex, removeLastImage, changeImage, removeCachedImage]);

            waitForOperation.timeout(const Duration(minutes: 2)).then((value) {
              final imageSaved = value[2];
              final lastImageRemoved = value[1];
              final indexed = value[0][dbReference(Profile.image_index)];
              showDebug(msg: index);
              showDebug(msg: imageSaved);
              showDebug(msg: indexed);

              closeCustomProgressBar(context);
              if (imageSaved is String &&
                  imageSaved.isNotEmpty &&
                  indexed == index) {
              } else {
                showToastMobile(msg: "An error M10 has occurred");
                return;
              }

              final imageUrl = SupabaseConfig.client.storage
                  .from(dbReference(Profile.bucket))
                  .getPublicUrl(imagePath);

              // Flag off Uploading Profile
              UserProfileService().profilePictureUploading = false;

              MembersOperation.updateTheValue(
                      dbReference(Profile.image_index), index,
                      forceUpdate: true)
                  .timeout(const Duration(minutes: 1));
              showToastMobile(msg: "Successfully uploaded the image");

              showDebug(msg: imageUrl);
            }).onError((error, stackTrace) {
              // Flag off Uploading Profile
              UserProfileService().profilePictureUploading = false;

              showDebug(msg: "$error $stackTrace");
              closeCustomProgressBar(context);
              showToastMobile(msg: "Unable to connect to internet");
            });
          }).onError((error, stackTrace) {
            closeCustomProgressBar(context);
            showToastMobile(
                msg: "An error M11 has occurred. Please, try again");
          });
        }).onError((error, stackTrace) {
          closeCustomProgressBar(context);
          showToastMobile(msg: "An error M12 has occurred. Please, try again ");
        });
      });
    } catch (e, s) {
      showDebug(msg: "$e $s");
    }
  }

  void goToSettings() {
    Navigator.push(
            context, MaterialPageRoute(builder: (context) => SettingsPage()))
        .then((value) {
      setLightUiViewOverlay();
    });
  }

  void performBackPressed() {
    try {
      if (KeyboardVisibilityProvider.isKeyboardVisible(context)) {
        hideKeyboard(context);
      } else {
        Navigator.pop(context);
        setNormalUiViewOverlay();
      }
    } catch (e) {
      Navigator.pop(context);
      setNormalUiViewOverlay();
    }
  }

  void editProfile() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => EditPage()));
  }

  void openSearchPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SearchedPage()));
  }

  Widget getHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        SizedBox(
          height: getSpanLimiter(24, getScreenHeight(context) * 0.05),
        ),
        // Top buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomCircularButton(
              imagePath: null,
              mainAlignment: Alignment.center,
              iconColor: Color(getDarkGreyColor),
              onPressed: performBackPressed,
              icon: Icons.arrow_back,
              gap: 8,
              width: getSpanLimiter(45, getScreenHeight(context) * 0.1),
              height: getSpanLimiter(45, getScreenHeight(context) * 0.1),
              iconSize: getSpanLimiter(35, getScreenHeight(context) * 0.075),
              defaultBackgroundColor: Colors.transparent,
              colorImage: true,
              showShadow: false,
              clickedBackgroundColor:
                  const Color(getDarkGreyColor).withOpacity(0.4),
            ),

            SizedBox(
              width: 8,
            ),
            Expanded(
              child: SizedBox(
                height: getSpanLimiter(40, getScreenHeight(context) * 0.1),
                child: CustomOnClickContainer(
                  onTap: openSearchPage,
                  defaultColor: Colors.transparent,
                  clickedColor: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade500),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text(
                          "Search here",
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                              color: Colors.black.withOpacity(0.7),
                              fontSize: 16),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(
              width: 8,
            ),

            // Menu
            CustomCircularButton(
              imagePath: null,
              mainAlignment: Alignment.center,
              iconColor: Color(getDarkGreyColor),
              onPressed: goToSettings,
              icon: Icons.settings,
              gap: 8,
              width: getSpanLimiter(45, getScreenHeight(context) * 0.1),
              height: getSpanLimiter(45, getScreenHeight(context) * 0.1),
              iconSize: getSpanLimiter(35, getScreenHeight(context) * 0.075),
              defaultBackgroundColor: Colors.transparent,
              colorImage: true,
              showShadow: false,
              clickedBackgroundColor:
                  const Color(getDarkGreyColor).withOpacity(0.4),
            ),
          ],
        ),
      ]),
    );
  }

  void handleFilterTypeChange(int index) {
    handlerNotifier.sendNewState(index);
    if (index == 0) {
    } else if (index == 1) {
    } else if (index == 2) {}
  }

  void handleConnect() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DisplayConnectInfoPage(
                forMember: ProfileNotifier().state.currentValue?.fullName ?? '',
                titleType: Connect.connect,
                userConnectsNotifier: UserConnectsNotifier(),
                connectionRetryStreamListener: retryStreamListener)));
  }

  void handleConnection() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DisplayConnectInfoPage(
                forMember: ProfileNotifier().state.currentValue?.fullName ?? '',
                titleType: Connect.connection,
                userConnectsNotifier: UserConnectsNotifier(),
                connectionRetryStreamListener: retryStreamListener)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        size: Size(getScreenWidth(context),
            getSpanLimiter(80, getScreenHeight(context) * 0.2)),
        child: Row(
          children: [
            Expanded(child: getHeader()),
          ],
        ),
      ),
      body: SafeArea(
        child: NestedScrollView(
          scrollDirection: Axis.vertical,
          controller: scrollController,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              WrappingSliverAppBar(
                titleSpacing: 0,
                elevation: 0,
                backgroundColor: Colors.transparent,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 16,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Picture
                          Stack(
                            children: [
                              // Image
                              CustomOnClickContainer(
                                defaultColor: Colors.grey.shade200,
                                clickedColor: Colors.grey.shade300,
                                height: 100,
                                width: 100,
                                clipBehavior: Clip.hardEdge,
                                shape: BoxShape.circle,
                                child: WidgetStateConsumer(
                                    widgetStateNotifier:
                                        ProfileNotifier().state,
                                    widgetStateBuilder: (context, snapshot) {
                                      UserData? userData = snapshot;
                                      return ProfileImage(
                                        fullName: userData?.fullName ?? 'Error',
                                        canDisplayImage: true,
                                        iconSize: 50,
                                        imageUri: MembersOperation()
                                            .getMemberProfileBucketPath(
                                                snapshot?.userId ?? '',
                                                snapshot?.profileIndex),
                                        imageUrl: (imageAddress) {
                                          imageUrl = imageAddress;
                                        },
                                      );
                                    }),
                              ),
                              //   Change Profile Picture

                              Positioned.fill(
                                child: SizedBox(
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: CustomOnClickContainer(
                                        onTap: () {
                                          if (!canOpen) {
                                            return;
                                          }
                                          canOpen = false;
                                          if (imageUrl == null) {
                                            onChangeProfilePicture(
                                                context, null);
                                          } else {
                                            DefaultCacheManager()
                                                .getSingleFile(imageUrl!)
                                                .then((value) {
                                              onChangeProfilePicture(
                                                  context, value.existsSync());
                                            }).onError((error, stackTrace) {
                                              showDebug(
                                                  msg: "$error $stackTrace");
                                              showToastMobile(
                                                  msg:
                                                      "Unable to download image file");
                                              onChangeProfilePicture(
                                                  context, false);
                                            });
                                          }
                                        },
                                        defaultColor:
                                            const Color(getMainPinkColor),
                                        clickedColor:
                                            const Color(getMainPinkColor)
                                                .withOpacity(0.75),
                                        shape: BoxShape.circle,
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.add,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        )),
                                  ),
                                ),
                              )
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CustomOnClickContainer(
                              onTap: editProfile,
                              shape: BoxShape.circle,
                              defaultColor: Colors.transparent,
                              clickedColor: Colors.grey.shade200,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.edit,
                                    color: Color(getDarkGreyColor), size: 28),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: WidgetStateConsumer(
                                widgetStateNotifier: ProfileNotifier().state,
                                widgetStateBuilder: (context, snapshot) {
                                  UserData? userData = snapshot;
                                  String fullname = "${userData?.fullName}";
                                  String email = "${userData?.email}";
                                  String phoneNumber =
                                      "+${userData?.phoneCode ?? ""}${userData?.phone}";
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              fullname,
                                              textScaler: TextScaler.noScaling,
                                              style: TextStyle(
                                                  color:
                                                      Color(getDarkGreyColor),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              email,
                                              textScaler: TextScaler.noScaling,
                                              style: TextStyle(
                                                  color: Colors.black
                                                      .withOpacity(0.8),
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              phoneNumber,
                                              textScaler: TextScaler.noScaling,
                                              style: TextStyle(
                                                  color: Colors.black
                                                      .withOpacity(0.7),
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),

                                      //   Connects

                                      WidgetStateConsumer(
                                          widgetStateNotifier:
                                              UserConnectsNotifier().state,
                                          widgetStateBuilder:
                                              (context, snapshot) {
                                            if (snapshot == null) {
                                              return SizedBox(
                                                height: 16,
                                              );
                                            }
                                            UserConnectsData userConnectData =
                                                snapshot;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 10, bottom: 6),
                                              child: Row(
                                                children: [
                                                  if (userConnectData
                                                          .connects !=
                                                      null)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Row(
                                                        children: [
                                                          Builder(builder:
                                                              (context) {
                                                            int connects =
                                                                userConnectData
                                                                    .connects!
                                                                    .length;
                                                            return CustomOnClickContainer(
                                                              onTap:
                                                                  handleConnect,
                                                              defaultColor: Colors
                                                                  .transparent,
                                                              clickedColor: Colors
                                                                  .transparent,
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(4),
                                                              child: Text(
                                                                  connects > 1
                                                                      ? "$connects Connects"
                                                                      : "$connects Connect",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .black,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          14)),
                                                            );
                                                          })
                                                        ],
                                                      ),
                                                    ),
                                                  if (userConnectData
                                                              .connects !=
                                                          null &&
                                                      userConnectData
                                                              .connection !=
                                                          null)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Container(
                                                        height: 5,
                                                        width: 5,
                                                        decoration:
                                                            BoxDecoration(
                                                                color: Colors
                                                                    .grey
                                                                    .shade600,
                                                                shape: BoxShape
                                                                    .circle),
                                                      ),
                                                    ),
                                                  if (userConnectData
                                                          .connection !=
                                                      null)
                                                    Row(
                                                      children: [
                                                        Builder(
                                                            builder: (context) {
                                                          int connections =
                                                              userConnectData
                                                                  .connection!
                                                                  .length;
                                                          return CustomOnClickContainer(
                                                            onTap:
                                                                handleConnection,
                                                            defaultColor: Colors
                                                                .transparent,
                                                            clickedColor: Colors
                                                                .transparent,
                                                            padding:
                                                                EdgeInsets.all(
                                                                    4),
                                                            child: Text(
                                                              connections > 1
                                                                  ? "$connections Connections"
                                                                  : "$connections Connection",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14),
                                                            ),
                                                          );
                                                        })
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            );
                                          })
                                    ],
                                  );
                                }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ];
          },
          body: StickyHeaderBuilder(
            builder: (context, stick) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextFilterScrollView(
                    textFilterController: typeFilterController,
                    currentItem: handleFilterTypeChange,
                    offsetAddon: getScreenWidth(context) * 0.20,
                    textSize: 14,
                    filterItems:
                        filterItemHandler.map((e) => e.filterItem).toList(),
                    borderRadius: BorderRadius.circular(5),
                    textPadding: 14,
                    textActiveColor: Colors.white,
                    boldUnSelected: true,
                    textNormalColor: Colors.grey.shade500,
                    bottomDividerHeight: 0,
                    textActiveBackground: Color(getMainPinkColor),
                    padding: const EdgeInsets.only(
                        left: 24, right: 24, top: 16, bottom: 16),
                  ),
                ],
              );
            },
            content: WidgetStateConsumer(
              widgetStateNotifier: handlerNotifier,
              widgetStateBuilder: (context, snapshot) {
                return filterItemHandler
                    .map((e) => e.handler)
                    .toList()
                    .elementAt(snapshot ?? 0);
              },
            ),
          ),
        ),
      ),
    );
  }
}
