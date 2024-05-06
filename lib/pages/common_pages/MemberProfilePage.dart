import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/data/PostProfileData.dart';
import 'package:yabnet/data/UserConnectsData.dart';
import 'package:yabnet/data_notifiers/MemberConnectsNotifier.dart';
import 'package:yabnet/data_notifiers/PostProfileNotifier.dart';
import 'package:yabnet/data_notifiers/UserConnectsNotifier.dart';
import 'package:yabnet/handler/MemberProfilePagePostHandler.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/pages/common_pages/DisplayConnectInfoPage.dart';

import '../../collections/common_collection/ProfileImage.dart';
import '../../components/CustomAppBar.dart';
import '../../components/CustomCircularButton.dart';
import '../../components/CustomOnClickContainer.dart';
import '../../components/CustomProject.dart';
import '../../components/CustomTextFilterScrollView.dart';
import '../../components/WrappingSilverAppBar.dart';
import '../../db_references/Connect.dart';
import '../../db_references/Members.dart';
import '../../handler/ProfilePagePollHandler.dart';
import '../../main.dart';
import 'SearchedPage.dart';

class MembersProfilePageHandlerData {
  final FilterItem filterItem;
  final Widget handler;

  MembersProfilePageHandlerData(this.filterItem, this.handler);
}

class MembersProfilePage extends StatefulWidget {
  final String membersId;

  const MembersProfilePage({
    super.key,
    required this.membersId,
  });

  @override
  State<MembersProfilePage> createState() => _MembersProfilePageState();
}

class _MembersProfilePageState extends State<MembersProfilePage>
    implements UserConnectsImplement {
  String? imageUrl;
  bool canOpen = true;

  ScrollController scrollController = ScrollController();
  TextFilterController typeFilterController = TextFilterController(toIndex: 0);
  WidgetStateNotifier<int> handlerNotifier =
      WidgetStateNotifier(currentValue: 0);
  UserConnectsStack userConnectsStack = UserConnectsStack();

  RetryStreamListener retryStreamListener = RetryStreamListener();

  PostProfileNotifier postProfileNotifier = PostProfileNotifier();
  MemberConnectsNotifier membersConnectNotifier = MemberConnectsNotifier();

  List<MembersProfilePageHandlerData> get filterItemHandler => [
        MembersProfilePageHandlerData(
            FilterItem(filterText: "Posts"),
            MemberProfilePagePostHandler(
              membersId: widget.membersId,
            )),
        MembersProfilePageHandlerData(
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
    membersConnectNotifier.attachMembersId(
        widget.membersId, dbReference(Members.user_profile));
    membersConnectNotifier.start(this, userConnectsStack);
    postProfileNotifier.attachMembersId(
        widget.membersId, dbReference(Members.user_profile),
        startFetching: true);

    hideKeyboard(context);
  }

  @override
  void dispose() {
    super.dispose();
    typeFilterController.dispose();
    postProfileNotifier.endSubscription();
  }

  void performBackPressed() {
    setLightUiViewOverlay();
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
                forMember:
                    postProfileNotifier.state.currentValue?.fullName ?? '',
                titleType: Connect.connect,
                userConnectsNotifier: membersConnectNotifier,
                connectionRetryStreamListener: retryStreamListener)));
  }

  void handleConnection() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DisplayConnectInfoPage(
                forMember:
                    postProfileNotifier.state.currentValue?.fullName ?? '',
                titleType: Connect.connection,
                userConnectsNotifier: membersConnectNotifier,
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
        child: StreamBuilder(
            initialData: postProfileNotifier.state.currentValue,
            stream: postProfileNotifier.state.stream,
            builder: (context, snapshot) {
              PostProfileData? userData = snapshot.data;

              if (userData == null) {
                return Center(
                  child: progressBarWidget(),
                );
              }

              String userId = userData.userId;
              String fullName = userData.fullName;
              String email = userData.email;
              String phoneNumber =
                  "+${userData.phoneCode ?? ""}${userData.phone}";
              return NestedScrollView(
                scrollDirection: Axis.vertical,
                controller: scrollController,
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
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
                                        child: ProfileImage(
                                          fullName: fullName,
                                          canDisplayImage: true,
                                          iconSize: 50,
                                          imageUri: MembersOperation()
                                              .getMemberProfileBucketPath(
                                                  userId ?? '',
                                                  userData.profileIndex),
                                          imageUrl: (imageAddress) {
                                            imageUrl = imageAddress;
                                          },
                                        )),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 16,
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            fullName,
                                            textScaler: TextScaler.noScaling,
                                            style: TextStyle(
                                                color: Color(getDarkGreyColor),
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
                                            membersConnectNotifier.state,
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
                                                if (userConnectData.connects !=
                                                    null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 8.0),
                                                    child: Row(
                                                      children: [
                                                        Builder(
                                                            builder: (context) {
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
                                                                EdgeInsets.all(
                                                                    4),
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
                                                if (userConnectData.connects !=
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
                                                      decoration: BoxDecoration(
                                                          color: Colors
                                                              .grey.shade600,
                                                          shape:
                                                              BoxShape.circle),
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
                                                              EdgeInsets.all(4),
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
                                )),
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
                          filterItems: filterItemHandler
                              .map((e) => e.filterItem)
                              .toList(),
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
              );
            }),
      ),
    );
  }
}
