import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/components/CustomTextFilterScrollView.dart';
import 'package:yabnet/drawer/ProfileDrawer.dart';
import 'package:yabnet/handler/AnnouncementPageAllNotificationHandler.dart';
import 'package:yabnet/main.dart';

import '../../collections/common_collection/ProfileImage.dart';
import '../../components/CustomCircularButton.dart';
import '../../components/FeatureComingSoonWidget.dart';
import '../../components/WrappingSilverAppBar.dart';
import '../../data/UserData.dart';
import '../../data_notifiers/ProfileNotifier.dart';
import '../../operations/MembersOperation.dart';
import 'SearchedPage.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  ScrollNotifier scrollNotifier = ScrollNotifier();

  TextFilterController textFilterController = TextFilterController();
  WidgetStateNotifier<int> handlerNotifier =
      WidgetStateNotifier(currentValue: 0);

  List<FilterItem> get filterItem => [
        FilterItem(filterText: "All"),
        FilterItem(filterText: "My posts"),
        FilterItem(filterText: "Mentions"),
      ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void handleFilterItemChange(int index) {
    handlerNotifier.sendNewState(index);
  }

  void openNavigationBar(BuildContext scaffoldContext) {
    Scaffold.of(scaffoldContext).openDrawer();
  }

  void messageButtonClicked() {
    showDialog(
        context: context,
        builder: (context) {
          return FeatureComingSoon(
            icon: Icons.message,
            featureName: 'Messaging',
            description:
                'Stay connected with industry peers, thought leaders, and potential collaborators with ease.',
          );
        });
  }

  void openSearchPage() {
    Navigator.push(
            context, MaterialPageRoute(builder: (context) => SearchedPage()))
        .then((value) {
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
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                WrappingSliverAppBar(
                    titleSpacing: 0,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    title: Column(children: [
                      // Top buttons
                      SizedBox(
                        height: 24,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomOnClickContainer(
                              onTap: () {
                                openNavigationBar(context);
                              },
                              defaultColor: Colors.grey.shade200,
                              clickedColor: Colors.grey.shade300,
                              height: 50,
                              width: 50,
                              clipBehavior: Clip.hardEdge,
                              shape: BoxShape.circle,
                              child: WidgetStateConsumer(
                                  widgetStateNotifier: ProfileNotifier().state,
                                  widgetStateBuilder: (context, snapshot) {
                                    UserData? userData = snapshot;
                                    return ProfileImage(
                                      iconSize: 50,
                                      imageUrl: (imageAddress) {},
                                      imageUri: MembersOperation()
                                          .getMemberProfileBucketPath(
                                              userData?.userId ?? '',
                                              userData?.profileIndex),
                                      fullName: userData?.fullName ?? 'Error',
                                    );
                                  }),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: CustomOnClickContainer(
                                  onTap: openSearchPage,
                                  defaultColor: Colors.transparent,
                                  clickedColor: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(25),
                                  border:
                                      Border.all(color: Colors.grey.shade500),
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
                                              color:
                                                  Colors.black.withOpacity(0.7),
                                              fontSize: 16),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // SizedBox(
                            //   width: 8,
                            // ),
                            // CustomCircularButton(
                            //   imagePath: null,
                            //   mainAlignment: Alignment.center,
                            //   iconColor: Color(getDarkGreyColor),
                            //   onPressed: () {},
                            //   icon: Icons.settings,
                            //   gap: 8,
                            //   width: 45,
                            //   height: 45,
                            //   iconSize: 35,
                            //   defaultBackgroundColor: Colors.transparent,
                            //   colorImage: true,
                            //   showShadow: false,
                            //   clickedBackgroundColor:
                            //       const Color(getDarkGreyColor)
                            //           .withOpacity(0.4),
                            // ),

                            SizedBox(
                              width: 8,
                            ),
                            // Message
                            CustomCircularButton(
                              imagePath: null,
                              mainAlignment: Alignment.center,
                              iconColor: Color(getDarkGreyColor),
                              onPressed: messageButtonClicked,
                              icon: Icons.message,
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
                          ],
                        ),
                      ),
                    ])),
                WrappingSliverAppBar(
                  notifier: scrollNotifier,
                  titleSpacing: 0,
                  elevation: 0,
                  forceMaterialTransparency: true,
                  pinned: true,
                  backgroundColor: Colors.white,
                  title: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 16,
                        ),
                        CustomTextFilterScrollView(
                          textFilterController: textFilterController,
                          currentItem: handleFilterItemChange,
                          offsetAddon: getScreenWidth(context) * 0.20,
                          textSize: 16,
                          filterItems: filterItem,
                          borderRadius: BorderRadius.circular(5),
                          textPadding: 14,
                          textActiveColor: Colors.white,
                          boldUnSelected: true,
                          textNormalColor: Colors.grey.shade500,
                          bottomDividerHeight: 0,
                          textActiveBackground: Color(getMainPinkColor),
                          padding: const EdgeInsets.only(
                              left: 24, right: 24, top: 8, bottom: 16),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: AnnouncementPageAllNotificationHandler(
              handlerNotifier: handlerNotifier,
            )),
      ),
    );
  }
}
