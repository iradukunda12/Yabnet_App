import 'package:flutter/material.dart';
import 'package:yabnet/data_notifiers/LikesNotifier.dart';
import 'package:yabnet/data_notifiers/PostProfileNotifier.dart';
import 'package:yabnet/data_notifiers/RepostsNotifier.dart';

import '../builders/ControlledStreamBuilder.dart';
import '../builders/CustomWrapListBuilder.dart';
import '../components/CustomButtonRefreshCard.dart';
import '../components/CustomProject.dart';
import '../data/HomePagePostData.dart';
import '../data_notifiers/CommentsNotifier.dart';
import '../data_notifiers/ConnectsNotifier.dart';
import '../data_notifiers/PostNotifier.dart';
import '../data_notifiers/UserPostNotifier.dart';
import '../db_references/NotifierType.dart';
import '../db_references/Post.dart';
import '../main.dart';
import 'HomePagePostViewHandler.dart';

class ProfilePageUserPostHandler extends StatefulWidget {
  final Map? homePagePostMapData;

  const ProfilePageUserPostHandler({super.key, this.homePagePostMapData});

  @override
  State<ProfilePageUserPostHandler> createState() =>
      _ProfilePageUserPostHandlerState();
}

class _ProfilePageUserPostHandlerState extends State<ProfilePageUserPostHandler>
    implements PostImplement {
  RetryStreamListener retryStreamListener = RetryStreamListener();
  PostSessionIdentifier userPostStack = PostSessionIdentifier();
  PaginationProgressController paginationProgressController =
      PaginationProgressController();

  @override
  void initState() {
    super.initState();
    UserPostNotifier().start(this, userPostStack);

    if (widget.homePagePostMapData?[dbReference(Post.id)] != null) {
      UserPostNotifier().addUserPost(widget.homePagePostMapData!);
    }
  }

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
  void dispose() {
    super.dispose();
    UserPostNotifier().stop(userPostStack);
  }

  @override
  Widget build(BuildContext context) {
    return ControlledStreamBuilder(
        retryStreamListener: retryStreamListener,
        initialData: UserPostNotifier().state.currentValue,
        streamProvider: (context) {
          return UserPostNotifier().state.stream;
        },
        builder: (context, snapshot) {
          List<HomePagePostData>? postData = snapshot.data;

          if (UserPostNotifier().getLatestData().isEmpty) {
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
            if (!snapshot.hasData || snapshot.forcedRetry) {
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
            postData = UserPostNotifier().getLatestData();
          }

          return CustomWrapListBuilder(
              paginateSize: 20,
              paginationProgressController: paginationProgressController,
              paginationProgressStyle: PaginationProgressStyle(
                  useDefaultTimeOut: true,
                  progressMaxDuration: const Duration(seconds: 60),
                  padding: EdgeInsets.only(bottom: 100),
                  scrollThreshold: 50),
              itemCount: postData?.length,
              retryStreamListener: retryStreamListener,
              alwaysPaginating: true,
              bottomPaginateWidget: Icon(
                Icons.add_circle_outline_sharp,
                size: 50,
                color: Color(getDarkGreyColor),
              ),
              wrapEdgePosition: (edgePosition) {
                if (edgePosition == WrapEdgePosition.normalBottom) {
                  retryStreamListener.controlRequestCall(Duration(seconds: 5),
                      () {
                    UserPostNotifier().requestPaginate();
                  });
                }
              },
              paginationSizeChanged: (size, paginate) {},
              wrapListBuilder: (context, index) {
                HomePagePostData homePagePostData = postData![index];

                CommentsNotifier? commentNotifier = UserPostNotifier()
                    .getCommentNotifier(
                        homePagePostData.postId, NotifierType.normal);

                LikesNotifier? likesNotifier = UserPostNotifier()
                    .getLikeNotifier(
                        homePagePostData.postId, NotifierType.normal);

                RepostsNotifier? repostNotifier = UserPostNotifier()
                    .getRepostsNotifier(
                        homePagePostData.postId, NotifierType.normal);

                ConnectsNotifier? connectsNotifier = UserPostNotifier()
                    .getConnectsNotifier(
                        homePagePostData.postBy, NotifierType.normal);

                PostProfileNotifier? postProfileNotifier = UserPostNotifier()
                    .getPostProfileNotifier(
                        homePagePostData.postBy, NotifierType.normal);

                bool showPost = commentNotifier != null &&
                    likesNotifier != null &&
                    repostNotifier != null &&
                    connectsNotifier != null &&
                    postProfileNotifier != null;

                return Column(
                  children: [
                    if (showPost)
                      HomePagePostViewHandler(
                        index: index,
                        homePagePostData: homePagePostData,
                        commentsNotifier: commentNotifier,
                        fromHomePage: false,
                        postNotifier: UserPostNotifier(),
                        likesNotifier: likesNotifier,
                        repostsNotifier: repostNotifier,
                        connectsNotifier: connectsNotifier,
                        postProfileNotifier: postProfileNotifier,
                      ),
                    if (index + 1 == postData.length && showPost)
                      SizedBox(
                        height: 25,
                      ),
                  ],
                );
              });
        });
  }
}
