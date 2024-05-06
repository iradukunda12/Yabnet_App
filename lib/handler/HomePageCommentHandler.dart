import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/HomePageCommentView.dart';
import 'package:yabnet/data/HomePageCommentData.dart';
import 'package:yabnet/data/HomePagePostData.dart';
import 'package:yabnet/data_notifiers/CommentLikesNotifier.dart';
import 'package:yabnet/data_notifiers/CommentsNotifier.dart';
import 'package:yabnet/data_notifiers/PostProfileNotifier.dart';
import 'package:yabnet/db_references/NotifierType.dart';
import 'package:yabnet/main.dart';
import 'package:yabnet/operations/CommentOperation.dart';

import '../builders/ControlledStreamBuilder.dart';
import '../builders/CustomWrapListBuilder.dart';
import '../components/CustomButtonRefreshCard.dart';
import '../components/CustomProject.dart';
import '../data/ConnectInfo.dart';
import '../pages/common_pages/MemberProfilePage.dart';
import '../pages/common_pages/ProfilePage.dart';
import '../supabase/SupabaseConfig.dart';
import 'HomePageCommentingHandler.dart';

class CommentingReplyInfoData {
  final HomePageCommentData homePageCommentData;
  final PostProfileNotifier postProfileNotifier;
  final PostProfileNotifier? postToProfileNotifier;

  CommentingReplyInfoData(this.homePageCommentData, this.postProfileNotifier,
      this.postToProfileNotifier);
}

class HomePageCommentHandler {
  HomePageCommentHandler(
      BuildContext context,
      HomePagePostData homePagePostData,
      CommentsNotifier commentsNotifier,
      RetryStreamListener retryStreamListener,
      PaginationProgressController paginationProgressController,
      {bool fromHome = false,
      bool fromExtended = false}) {
    WidgetStateNotifier<CommentingReplyInfoData> commentReplyNotifier =
        WidgetStateNotifier();
    WidgetStateNotifier<bool> focusNotifier = WidgetStateNotifier();

    void addLocalLike(HomePageCommentData homePageCommentData,
        CommentLikesNotifier commentLikesNotifier) {
      String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
      String? commentTo = homePageCommentData.commentTo;
      String? commentParent = homePageCommentData.commentParent;
      if (commentTo == null && commentParent == null) {
        commentsNotifier.makeUpdateOnFindByCommentId(
            homePageCommentData.commentId,
            online: false);
      } else {
        commentsNotifier.makeUpdateOnSubCommentByCommentId(
            homePageCommentData.commentId, commentParent ?? commentTo!,
            online: false);
      }
      commentLikesNotifier.addLikes(thisUser);
    }

    void removeLocalLike(HomePageCommentData homePageCommentData,
        CommentLikesNotifier commentLikesNotifier) {
      String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
      String? commentTo = homePageCommentData.commentTo;
      String? commentParent = homePageCommentData.commentParent;
      if (commentTo == null) {
        commentsNotifier.makeUpdateOnFindByCommentId(
            homePageCommentData.commentId,
            online: false);
      } else {
        commentsNotifier.makeUpdateOnSubCommentByCommentId(
            homePageCommentData.commentId, commentParent ?? commentTo,
            online: false);
      }
      commentLikesNotifier.removeLikes(thisUser);
    }

    void addOnlineLike(HomePageCommentData homePageCommentData) async {
      String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
      CommentOperation()
          .addLike(homePageCommentData.commentId, thisUser)
          .then((value) {
        if (value != null) {
          String? commentTo = homePageCommentData.commentTo;
          String? commentParent = homePageCommentData.commentParent;
          if (commentTo == null) {
            commentsNotifier.makeUpdateOnFindByCommentId(
                homePageCommentData.commentId,
                online: true);
          } else {
            commentsNotifier.makeUpdateOnSubCommentByCommentId(
                homePageCommentData.commentId, commentParent ?? commentTo,
                online: true);
          }
        }
      }).onError((error, stackTrace) {
        showDebug(msg: "$error $stackTrace");
        showToastMobile(msg: "Unable to like comment right now");
      });
    }

    void removeOnlineLike(HomePageCommentData homePageCommentData) {
      String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
      CommentOperation()
          .removeLike(homePageCommentData.commentId, thisUser)
          .then((value) {
        String? commentTo = homePageCommentData.commentTo;
        String? commentParent = homePageCommentData.commentParent;
        if (commentTo == null) {
          commentsNotifier.makeUpdateOnFindByCommentId(
              homePageCommentData.commentId,
              online: true);
        } else {
          commentsNotifier.makeUpdateOnSubCommentByCommentId(
              homePageCommentData.commentId, commentParent ?? commentTo,
              online: true);
        }
      }).onError((error, stackTrace) {
        showDebug(msg: "$error $stackTrace");
        showToastMobile(msg: "Unable to remove like from comment");
      });
    }

    void clickOnLike(HomePageCommentData homePageCommentData,
        CommentLikesNotifier commentLikesNotifier) {
      String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
      bool online = homePagePostData.online;
      bool isLiked = commentLikesNotifier
          .getLatestData()
          .where((element) => element.membersId == thisUser)
          .isNotEmpty;

      if (homePageCommentData.commentId.contains("->")) {
        showToastMobile(msg: "Comment has to be updated");
        return;
      }

      if (online) {
        if (!isLiked) {
          addLocalLike(homePageCommentData, commentLikesNotifier);
          addOnlineLike(homePageCommentData);
        } else {
          removeLocalLike(homePageCommentData, commentLikesNotifier);
          removeOnlineLike(homePageCommentData);
        }
      } else {
        if (isLiked) {
          removeLocalLike(homePageCommentData, commentLikesNotifier);
          removeOnlineLike(homePageCommentData);
        } else {
          addOnlineLike(homePageCommentData);
          addLocalLike(homePageCommentData, commentLikesNotifier);
        }
      }
    }

    void deleteComment(HomePageCommentData homePageCommentData) {
      showCustomProgressBar(context);
      CommentOperation()
          .deleteComment(homePageCommentData.commentId)
          .then((value) {
        if (homePageCommentData.commentTo != null) {
          commentsNotifier.deleteLocalSubComment(
              homePageCommentData.commentId, homePageCommentData.commentTo!);
        } else {
          commentsNotifier
              .deleteLocalMainComment(homePageCommentData.commentId);
        }
        closeCustomProgressBar(context);
      }).onError((error, stackTrace) {
        closeCustomProgressBar(context);
        showToastMobile(msg: "An error occurred");
        showDebug(msg: "$error $stackTrace");
      });
    }

    void replyComment(HomePageCommentData homePageCommentData) {
      focusNotifier.sendNewState(true);
      PostProfileNotifier? postProfileNotifier =
          commentsNotifier.getPostProfileNotifier(
              homePageCommentData.commentBy, NotifierType.normal);
      PostProfileNotifier? postToProfileNotifier =
          commentsNotifier.getPostProfileNotifier(
              homePageCommentData.commentToBy ?? '', NotifierType.normal);

      if (postProfileNotifier != null &&
          (postToProfileNotifier != null ||
              homePageCommentData.commentToBy == null)) {
        commentReplyNotifier.sendNewState(CommentingReplyInfoData(
            homePageCommentData, postProfileNotifier, postToProfileNotifier));
      }
    }

    void handleCommentClicks(HomePageCommentData homePageCommentData,
        CommentLikesNotifier commentLikesNotifier, action) {
      if (action == "Like") {
        clickOnLike(homePageCommentData, commentLikesNotifier);
      } else if (action == "Delete") {
        deleteComment(homePageCommentData);
      } else if (action == "Reply") {
        replyComment(homePageCommentData);
      } else if (action == "Retry") {}
    }

    void handleClickedInfo(ConnectInfo connectInfo) {
      String membersId = connectInfo.membersId;
      String? thisUser = SupabaseConfig.client.auth.currentUser?.id;

      if (thisUser == membersId) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => ProfilePage()));
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MembersProfilePage(
                      membersId: membersId,
                    ))).then((value) {
          setDarkGreyUiViewOverlay();
        });
      }
    }

    openBottomSheet(context, Builder(builder: (context) {
      setDarkGreyUiViewOverlay();
      return Container(
        height: getScreenHeight(context) * 0.88,
        decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(15))),
        child: Stack(
          children: [
            Positioned.fill(
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
                      height: 16,
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Text(
                          "Comments",
                          style: TextStyle(
                              color: Color(
                                getDarkGreyColor,
                              ),
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        )),
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Container(
                          height: 0.6,
                          color: Color(getDarkGreyColor),
                        ))
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Expanded(
                      child: ControlledStreamBuilder(
                          retryStreamListener: retryStreamListener,
                          initialData: commentsNotifier.state.currentValue,
                          streamProvider: (context) {
                            return commentsNotifier.state.stream;
                          },
                          builder: (context, snapshot) {
                            List<HomePageCommentData>? commentData =
                                snapshot.data;

                            if (commentsNotifier.getLatestData().isEmpty) {
                              if (snapshot.noConnection) {
                                return Center(
                                    child: CustomButtonRefreshCard(
                                        topIcon: const Icon(
                                          Icons
                                              .signal_wifi_connected_no_internet_4,
                                          size: 50,
                                        ),
                                        retryStreamListener:
                                            retryStreamListener,
                                        displayText:
                                            "Unable to connect to the server!!!"));
                              } else if (!snapshot.hasData ||
                                  snapshot.forcedRetry) {
                                return SizedBox(
                                    height: getScreenHeight(context) * 0.5,
                                    child: Center(
                                      child: progressBarWidget(),
                                    ));
                              } else if (commentData?.isEmpty == true) {
                                return Center(
                                    child: CustomButtonRefreshCard(
                                        topIcon: const Icon(
                                          Icons.not_interested,
                                          size: 50,
                                        ),
                                        retryStreamListener:
                                            retryStreamListener,
                                        displayText:
                                            "There are no comments yet."));
                              }
                            } else {
                              commentData = commentsNotifier.getLatestData();
                            }
                            return CustomWrapListBuilder(
                                paginateSize: 20,
                                paginationProgressController:
                                    paginationProgressController,
                                paginationProgressStyle:
                                    PaginationProgressStyle(
                                        padding: EdgeInsets.all(16),
                                        useDefaultTimeOut: true,
                                        progressMaxDuration:
                                            const Duration(seconds: 15),
                                        scrollThreshold: 50),
                                itemCount: commentData?.length,
                                alwaysPaginating: true,
                                retryStreamListener: retryStreamListener,
                                wrapEdgePosition: (edgePosition) {
                                  // paginationProgressController.showLoading();
                                },
                                wrapListBuilder: (context, index) {
                                  HomePageCommentData homePageCommentData =
                                      commentData![index];

                                  CommentLikesNotifier? commentLikesNotifier =
                                      commentsNotifier.getCommentLikeNotifier(
                                          homePageCommentData.commentId,
                                          NotifierType.normal);

                                  PostProfileNotifier? postProfileNotifier =
                                      commentsNotifier.getPostProfileNotifier(
                                          homePageCommentData.commentBy,
                                          NotifierType.normal);

                                  PostProfileNotifier? postToProfileNotifier =
                                      commentsNotifier.getPostProfileNotifier(
                                          homePageCommentData.commentToBy ?? '',
                                          NotifierType.normal);

                                  bool showComment =
                                      commentLikesNotifier != null &&
                                          postProfileNotifier != null;

                                  return showComment
                                      ? Padding(
                                          padding: EdgeInsets.only(
                                              left: 16,
                                              right: 16,
                                              bottom: (index + 1) ==
                                                      commentData.length
                                                  ? 150
                                                  : 0),
                                          child: HomePageCommentView(
                                            index: index,
                                            imageSize: 35,
                                            fromComment: true,
                                            homePagePostData: homePagePostData,
                                            onClickedQuick: (action,
                                                clickedHomePageCommentData,
                                                thisCommentLikeNotifier) {
                                              handleCommentClicks(
                                                  clickedHomePageCommentData,
                                                  thisCommentLikeNotifier,
                                                  action);
                                            },
                                            homePageCommentData:
                                                homePageCommentData,
                                            textSize: 12,
                                            commentLikesNotifier:
                                                commentLikesNotifier,
                                            commentsNotifier: commentsNotifier,
                                            onClickedInfo:
                                                (ConnectInfo? connectInfo) {
                                              if (connectInfo != null) {
                                                handleClickedInfo(connectInfo);
                                              }
                                            },
                                            postProfileNotifier:
                                                postProfileNotifier,
                                            postToProfileNotifier:
                                                postToProfileNotifier,
                                          ),
                                        )
                                      : SizedBox();
                                });
                          }),
                    ),
                  ]),
            ),
            StreamBuilder(
                stream: KeyboardVisibilityController().onChange,
                builder: (context, snapshot) {
                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border(
                              top: BorderSide(
                                  color: Color(getDarkGreyColor), width: 0.6))),
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: getScreenHeight(context) * 0.04),
                        child: HomePageCommentingHandler(
                          commentingInfo: commentReplyNotifier,
                          commentsNotifier: commentsNotifier,
                          homePagePostData: homePagePostData,
                          openTextFocus: focusNotifier,
                          openKeyboard: snapshot.data ?? false,
                        ),
                      ),
                    ),
                  );
                })
          ],
        ),
      );
    }), color: Colors.grey.shade200)
        .then((value) {
      if (fromHome) {
        setNormalUiViewOverlay();
      } else if (fromExtended) {
        setDarkUiViewOverlay();
      } else {
        setLightUiViewOverlay();
      }
    });
  }
}
