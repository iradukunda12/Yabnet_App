import 'package:flutter/material.dart';
import 'package:yabnet/data_notifiers/LikesNotifier.dart';
import 'package:yabnet/data_notifiers/MemberPostNotifier.dart';
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
import '../db_references/NotifierType.dart';
import '../main.dart';
import 'HomePagePostViewHandler.dart';

class MemberProfilePagePostHandler extends StatefulWidget {
  final String membersId;

  const MemberProfilePagePostHandler({super.key, required this.membersId});

  @override
  State<MemberProfilePagePostHandler> createState() =>
      _MemberProfilePagePostHandlerState();
}

class _MemberProfilePagePostHandlerState
    extends State<MemberProfilePagePostHandler> implements PostImplement {
  RetryStreamListener retryStreamListener = RetryStreamListener();
  PostSessionIdentifier userPostStack = PostSessionIdentifier();
  PaginationProgressController paginationProgressController =
      PaginationProgressController();

  late MemberPostNotifier memberPostNotifier;

  @override
  void initState() {
    super.initState();
    memberPostNotifier = MemberPostNotifier(widget.membersId);
    memberPostNotifier.start(this, userPostStack);
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
    memberPostNotifier.stop(userPostStack);
  }

  @override
  Widget build(BuildContext context) {
    return ControlledStreamBuilder(
        retryStreamListener: retryStreamListener,
        initialData: memberPostNotifier.state.currentValue,
        streamProvider: (context) {
          return memberPostNotifier.state.stream;
        },
        builder: (context, snapshot) {
          List<HomePagePostData>? postData = snapshot.data;

          if (memberPostNotifier.getLatestData().isEmpty) {
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
            postData = memberPostNotifier.getLatestData();
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
                    memberPostNotifier.requestPaginate();
                  });
                }
              },
              paginationSizeChanged: (size, paginate) {},
              wrapListBuilder: (context, index) {
                HomePagePostData homePagePostData = postData![index];

                CommentsNotifier? commentNotifier =
                    memberPostNotifier.getCommentNotifier(
                        homePagePostData.postId, NotifierType.normal);

                LikesNotifier? likesNotifier =
                    memberPostNotifier.getLikeNotifier(
                        homePagePostData.postId, NotifierType.normal);

                RepostsNotifier? repostNotifier =
                    memberPostNotifier.getRepostsNotifier(
                        homePagePostData.postId, NotifierType.normal);

                ConnectsNotifier? connectsNotifier =
                    memberPostNotifier.getConnectsNotifier(
                        homePagePostData.postBy, NotifierType.normal);

                PostProfileNotifier? postProfileNotifier =
                    memberPostNotifier.getPostProfileNotifier(
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
                        postNotifier: memberPostNotifier,
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
