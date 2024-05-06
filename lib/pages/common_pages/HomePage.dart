import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/builders/CustomWrapListBuilder.dart';
import 'package:yabnet/components/CustomButtonRefreshCard.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';
import 'package:yabnet/data/HomePagePostData.dart';
import 'package:yabnet/data_notifiers/CommentsNotifier.dart';
import 'package:yabnet/data_notifiers/ConnectsNotifier.dart';
import 'package:yabnet/data_notifiers/LikesNotifier.dart';
import 'package:yabnet/data_notifiers/PostProfileNotifier.dart';
import 'package:yabnet/db_references/NotifierType.dart';
import 'package:yabnet/drawer/ProfileDrawer.dart';
import 'package:yabnet/generator/PostFeedsGenerator.dart';
import 'package:yabnet/handler/HomePagePostViewHandler.dart';
import 'package:yabnet/main.dart';
import 'package:yabnet/pages/common_pages/SearchedPage.dart';

import '../../collections/common_collection/ProfileImage.dart';
import '../../collections/common_collection/WhoWeAreCollection.dart';
import '../../components/CustomCircularButton.dart';
import '../../components/CustomProject.dart';
import '../../components/FeatureComingSoonWidget.dart';
import '../../components/WrappingSilverAppBar.dart';
import '../../data/UserData.dart';
import '../../data_notifiers/PostNotifier.dart';
import '../../data_notifiers/ProfileNotifier.dart';
import '../../data_notifiers/RepostsNotifier.dart';
import '../../operations/MembersOperation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> implements PostImplement {
  RetryStreamListener retryStreamListener = RetryStreamListener();
  PostSessionIdentifier postStack = PostSessionIdentifier();
  PaginationProgressController paginationProgressController =
      PaginationProgressController();
  ScrollController scrollController = ScrollController();

  PostNotifier postNotifier = PostNotifier();

  @override
  BuildContext? getLatestContext() {
    return context;
  }

  @override
  RetryStreamListener? getRetryStreamListener() {
    return retryStreamListener;
  }

  @override
  PaginationProgressController? getPaginationProgressController() {
    return paginationProgressController;
  }

  @override
  void initState() {
    super.initState();
    postNotifier.start(this, postStack);
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
    postNotifier.stop(postStack);
  }

  void openNavigationBar(BuildContext scaffoldContext) {
    Scaffold.of(scaffoldContext).openDrawer();
  }

  void messageButtonClicked() {
    showDialog(
        context: context,
        builder: (context) {
          return const FeatureComingSoon(
            icon: Icons.message,
            featureName: 'Messaging',
            description:
                'Stay connected with industry peers, thought leaders, and potential collaborators with ease.',
          );
        });
  }

  void openSearchPage() {
    Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SearchedPage()))
        .then((value) {
      setNormalUiViewOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const ProfileDrawer(),
      body: SafeArea(
        child: NestedScrollView(
          controller: scrollController,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              WrappingSliverAppBar(
                  titleSpacing: 0,
                  elevation: 0,
                  snap: true,
                  floating: true,
                  forceMaterialTransparency: true,
                  title: Container(
                    color: Colors.white,
                    child: Column(children: [
                      // Top buttons
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 24, bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      iconSize: 45,
                                      imageUrl: (imageAddress) {},
                                      imageUri: MembersOperation()
                                          .getMemberProfileBucketPath(
                                              snapshot?.userId ?? '',
                                              snapshot?.profileIndex),
                                      fullName: snapshot?.fullName ?? "Error",
                                    );
                                  }),
                            ),

                            const SizedBox(
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
                                          const SizedBox(
                                            width: 8,
                                          ),
                                          Text(
                                            "Search here",
                                            textScaler: TextScaler.noScaling,
                                            style: TextStyle(
                                                color: Colors.black
                                                    .withOpacity(0.7),
                                                fontSize: 16),
                                          )
                                        ],
                                      ),
                                    ),
                                  )),
                            ),

                            // Message
                            CustomCircularButton(
                              imagePath: null,
                              mainAlignment: Alignment.center,
                              iconColor: const Color(getDarkGreyColor),
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
                    ]),
                  ))
            ];
          },
          // SizedBox(height: 24,),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 12),
          //   child: StatisticsCollection(),
          // ),
          // SizedBox(height: 24,),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 12),
          //   child: CalenderCollection(),
          // ),
          // SizedBox(height: 100,),

          body: ControlledStreamBuilder(
              retryStreamListener: retryStreamListener,
              initialData: postNotifier.state.currentValue,
              streamProvider: (context) {
                return postNotifier.state.stream;
              },
              builder: (context, snapshot) {
                List<HomePagePostData>? postData = snapshot.data;

                if (postNotifier.getLatestData().isEmpty) {
                  if (snapshot.noConnection) {
                    return Center(
                        child: CustomButtonRefreshCard(
                            topIcon: const Icon(
                              Icons.signal_wifi_connected_no_internet_4,
                              size: 50,
                            ),
                            retryStreamListener: retryStreamListener,
                            displayText: "Unable to connect to the server!!!"));
                  }
                  if (!snapshot.hasData ||
                      snapshot.forcedRetry ||
                      snapshot.data == null) {
                    return SizedBox(
                        height: getScreenHeight(context) * 0.5,
                        child: Center(
                          child: progressBarWidget(),
                        ));
                  } else {
                    if (postData?.isEmpty == true) {
                      return Center(
                          child: CustomButtonRefreshCard(
                              topIcon: const Icon(
                                Icons.not_interested,
                                size: 50,
                              ),
                              retryStreamListener: retryStreamListener,
                              displayText: "There are no post yet."));
                    }
                  }
                } else {
                  postData = postNotifier.getLatestData();
                }

                return CustomWrapListBuilder(
                    paginateSize:
                        PostFeedsGenerator().getPersonalizedLimitBy(reduce: 10),
                    paginationProgressController: paginationProgressController,
                    paginationProgressStyle: PaginationProgressStyle(
                        padding: const EdgeInsets.only(bottom: 50),
                        useDefaultTimeOut: true,
                        progressMaxDuration: const Duration(seconds: 60),
                        scrollThreshold: 25),
                    itemCount: postData?.length,
                    alwaysPaginating: true,
                    retryStreamListener: retryStreamListener,
                    wrapEdgePosition: (edgePosition) {
                      if (edgePosition == WrapEdgePosition.normalBottom) {
                        retryStreamListener
                            .controlRequestCall(const Duration(seconds: 5), () {
                          postNotifier.requestPaginate();
                        });
                      }
                    },
                    bottomPaginateWidget: const Icon(
                      Icons.add_circle_outline_sharp,
                      size: 50,
                      color: Color(getDarkGreyColor),
                    ),
                    paginationSizeChanged: (size, paginate) {},
                    wrapListBuilder: (context, index) {
                      HomePagePostData homePagePostData = postData![index];
                      CommentsNotifier? commentNotifier =
                          postNotifier.getCommentNotifier(
                              homePagePostData.postId, NotifierType.normal);
                      LikesNotifier? likesNotifier =
                          postNotifier.getLikeNotifier(
                              homePagePostData.postId, NotifierType.normal);

                      RepostsNotifier? repostNotifier =
                          postNotifier.getRepostsNotifier(
                              homePagePostData.postId, NotifierType.normal);

                      ConnectsNotifier? connectsNotifier =
                          postNotifier.getConnectsNotifier(
                              homePagePostData.postBy, NotifierType.normal);

                      PostProfileNotifier? postProfileNotifier =
                          postNotifier.getPostProfileNotifier(
                              homePagePostData.postBy, NotifierType.normal);

                      bool showPost = commentNotifier != null &&
                          likesNotifier != null &&
                          repostNotifier != null &&
                          connectsNotifier != null &&
                          postProfileNotifier != null;

                      return Column(
                        children: [
                          if (index == 0) const WhoWeAreCollection(),
                          if (showPost)
                            HomePagePostViewHandler(
                              index: index,
                              homePagePostData: homePagePostData,
                              commentsNotifier: commentNotifier,
                              postNotifier: postNotifier,
                              likesNotifier: likesNotifier,
                              repostsNotifier: repostNotifier,
                              connectsNotifier: connectsNotifier,
                              postProfileNotifier: postProfileNotifier,
                              fromHome: true,
                            ),
                          if (index + 1 == postData.length && showPost)
                            const SizedBox(
                              height: 25,
                            ),
                        ],
                      );
                    });
              }),
        ),
      ),
    );
  }
}
