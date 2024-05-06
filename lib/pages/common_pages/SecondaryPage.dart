import 'dart:io';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/services/MainService.dart';

import '../../builders/ControlledStreamBuilder.dart';
import '../../components/CustomProject.dart';
import '../../components/UpdateInfoConsumer.dart';
import '../../data_notifiers/ProfileNotifier.dart';
import '../../data_notifiers/UserConnectsNotifier.dart';
import '../../db_references/Members.dart';
import '../../generator/PostFeedsGenerator.dart';
import '../../local_navigation_controller.dart';
import '../../main.dart';
import '../../services/AppFileService.dart';
import '../../services/UserProfileService.dart';
import 'AnnouncementPage.dart';
import 'BusinessPage.dart';
import 'HomePage.dart';
import 'NetworkPage.dart';
import 'PostPage.dart';

class MemberNexPageData {
  final Icon icon;
  final Widget page;

  MemberNexPageData(this.icon, this.page);
}

class SecondaryPage extends StatefulWidget {
  const SecondaryPage({super.key});

  @override
  State<SecondaryPage> createState() => _SecondaryPageState();
}

class _SecondaryPageState extends State<SecondaryPage>
    with WidgetsBindingObserver
    implements ProfileImplement, UserConnectsImplement {
  int startingIndex = 0;
  late PageController pageViewController;
  WidgetStateNotifier<int> indexNotifier = WidgetStateNotifier();
  ProfileStack profileStack = ProfileStack();
  UserConnectsStack userConnectsStack = UserConnectsStack();

  @override
  BuildContext? getLatestContext() {
    return context;
  }

  @override
  RetryStreamListener? getRetryStreamListener() {
    return null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    UserProfileService().lifeCycleNotifier.sendNewState(state);
    AppFileService().lifeCycleNotifier.sendNewState(state);
  }

  @override
  void initState() {
    super.initState();
    setNormalUiViewOverlay();
    AppFileService().beginService();
    UserProfileService().beginService();
    MainService().startService();
    ProfileNotifier().start(this, profileStack);
    PostFeedsGenerator().start();
    UserConnectsNotifier().start(this, userConnectsStack);
    pageViewController = PageController(initialPage: startingIndex);
    LocalNavigationController()
        .addNavigatorKey(LocalNavigationController.useNavigatorKey);

    handleRestriction();

    WidgetsBinding.instance.addObserver(this);
  }

  void handleRestriction() async {
    final restricted = await MembersOperation()
        .getUserRecord(field: dbReference(Members.restricted));

    if (restricted == true) {
      UserProfileService().handleRestriction(true);
    }
  }

  @override
  void dispose() {
    super.dispose();
    UserConnectsNotifier().stop(userConnectsStack);
    WidgetsBinding.instance.addObserver(this);
    pageViewController.dispose();
    ProfileNotifier().stop(profileStack);
    UserProfileService().endService();
    AppFileService().endService();
  }

  List<MemberNexPageData> pages = [
    MemberNexPageData(
        const Icon(Icons.home, color: Colors.white), const HomePage()),
    MemberNexPageData(const Icon(Icons.people_sharp, color: Colors.white),
        const NetworkPage()),
    MemberNexPageData(const Icon(Icons.add_circle_rounded, color: Colors.white),
        const PostPage()),
    MemberNexPageData(
        const Icon(
          Icons.notifications_rounded,
          color: Colors.white,
        ),
        const AnnouncementPage()),
    MemberNexPageData(
        const Icon(Icons.business, color: Colors.white), const BusinessPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return UpdateInfoConsumer(
      updateAppInfoNotifier: MainService().updateAppInfoNotifier,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: SafeArea(
          bottom: Platform.isIOS ? false : true,
          child: WidgetStateConsumer(
              widgetStateNotifier: indexNotifier,
              widgetStateBuilder: (context, snapshot) {
                return CurvedNavigationBar(
                  index: snapshot ?? startingIndex,
                  height: Platform.isIOS ? 75 : 50,
                  backgroundColor: Colors.transparent,
                  color: const Color(getMainPinkColor),
                  onTap: (index) {
                    pageViewController.jumpToPage(index);
                  },
                  items: pages.map((e) => e.icon).toList(),
                );
              }),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  physics: NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    indexNotifier.sendNewState(index);
                  },
                  controller: pageViewController,
                  children: pages.map((e) => e.page).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
