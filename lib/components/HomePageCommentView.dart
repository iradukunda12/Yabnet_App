import 'dart:async';

import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/components/CustomWrappingLayout.dart';
import 'package:yabnet/data_notifiers/CommentLikesNotifier.dart';
import 'package:yabnet/data_notifiers/CommentsNotifier.dart';
import 'package:yabnet/data_notifiers/PostProfileNotifier.dart';
import 'package:yabnet/db_references/NotifierType.dart';
import 'package:yabnet/main.dart';
import 'package:yabnet/operations/CommentOperation.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../builders/CustomWrapListBuilder.dart';
import '../collections/common_collection/ProfileImage.dart';
import '../data/ConnectInfo.dart';
import '../data/HomePageCommentData.dart';
import '../data/HomePagePostData.dart';
import '../data/PostProfileData.dart';
import 'EllipsisText.dart';

class HomePageCommentView extends StatefulWidget {
  final bool fromComment;
  final int? index;
  final double imageSize;
  final double textSize;
  final HomePagePostData homePagePostData;
  final HomePageCommentData homePageCommentData;
  final CommentsNotifier commentsNotifier;
  final CommentLikesNotifier commentLikesNotifier;
  final PostProfileNotifier postProfileNotifier;
  final PostProfileNotifier? postToProfileNotifier;
  final Function(ConnectInfo? connectInfo) onClickedInfo;

  final Function(String operation, HomePageCommentData clickedCommentData,
      CommentLikesNotifier commentLikesNotifier) onClickedQuick;

  const HomePageCommentView(
      {super.key,
      this.index,
      this.imageSize = 30,
      required this.homePagePostData,
      required this.onClickedQuick,
      required this.homePageCommentData,
      required this.textSize,
      required this.commentLikesNotifier,
      required this.commentsNotifier,
      required this.onClickedInfo,
      required this.postProfileNotifier,
      required this.postToProfileNotifier,
      this.fromComment = false});

  @override
  State<HomePageCommentView> createState() => _HomePageCommentViewState();
}

class _HomePageCommentViewState extends State<HomePageCommentView> {
  int defaultCommentPaginate = 2;
  WidgetStateNotifier subCommentPaginateSizeNotifier =
      WidgetStateNotifier(currentValue: 2);
  WidgetStateNotifier retryNotifier = WidgetStateNotifier(currentValue: false);

  Timer? retryTimer;

  @override
  Widget build(BuildContext context) {
    retryNotifier.sendNewState(widget.homePageCommentData.online);

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: CustomWrappingLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        wlChildren: [
          //   Image
          // Image
          WLView(
            // expandMain: true,
            crossDimension: WlDimension.match,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    height: widget.imageSize,
                    width: widget.imageSize,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300,
                    ),
                    child: WidgetStateConsumer(
                        widgetStateNotifier: widget.postProfileNotifier.state,
                        widgetStateBuilder: (context, data) {
                          return ProfileImage(
                            iconSize: widget.imageSize,
                            textSize: widget.textSize,
                            canDisplayImage: true,
                            fromComment: widget.fromComment,
                            imageUri: MembersOperation()
                                .getMemberProfileBucketPath(
                                    data?.userId ?? "", data?.profileIndex),
                            fullName: data?.fullName ?? "Error",
                          );
                        })),
                if (!widget.homePageCommentData.online)
                  WidgetStateConsumer(
                      widgetStateNotifier: retryNotifier,
                      widgetStateBuilder: (context, data) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: data == false
                              ? IconButton(
                                  onPressed: () {
                                    widget.onClickedQuick(
                                        "Retry",
                                        widget.homePageCommentData,
                                        widget.commentLikesNotifier);

                                    retryNotifier.sendNewState(true);
                                    retryTimer ??=
                                        Timer(Duration(seconds: 5), () {
                                      retryTimer?.cancel();
                                      retryTimer = null;
                                      retryNotifier.sendNewState(false);
                                    });
                                  },
                                  icon: Icon(
                                    Icons.refresh,
                                    size: 24,
                                    color: Color(getDarkGreyColor),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child:
                                          progressBarWidget(pad: 8, size: 8)),
                                ),
                        );
                      })
              ],
            ),
          ),

          WLView(
            expandMain: true,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            WidgetStateConsumer(
                                widgetStateNotifier:
                                    widget.postProfileNotifier.state,
                                widgetStateBuilder: (context, data) {
                                  return GestureDetector(
                                    onTap: () {
                                      if (data != null) {
                                        widget.onClickedInfo(ConnectInfo(
                                            data.userId,
                                            data.fullName,
                                            data.profileIndex));
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          data?.fullName ?? "Error",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          CommentOperation().formatTimeAgo(
                                              DateTime.parse(widget
                                                  .homePageCommentData
                                                  .commentCreatedAt)),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            if (widget.homePageCommentData.commentToBy != null)
                              WidgetStateConsumer(
                                  widgetStateNotifier:
                                      widget.postToProfileNotifier!.state,
                                  widgetStateBuilder: (context, data) {
                                    PostProfileData? postProfile = data;

                                    return Row(
                                      children: [
                                        Text(
                                          "Replied",
                                          textScaler: TextScaler.noScaling,
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 11),
                                        ),
                                        SizedBox(
                                          width: 1,
                                        ),
                                        Icon(
                                          Icons.arrow_right,
                                          color: Colors.grey.shade600,
                                        ),
                                        SizedBox(
                                          width: 1,
                                        ),
                                        Expanded(
                                            child: GestureDetector(
                                          onTap: () {
                                            if (postProfile?.userId != null) {
                                              widget.onClickedInfo(ConnectInfo(
                                                  postProfile!.userId,
                                                  postProfile.fullName,
                                                  postProfile.profileIndex));
                                            }
                                          },
                                          child: Text(
                                            data?.fullName ?? "Error",
                                            textScaler: TextScaler.noScaling,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 11),
                                          ),
                                        )),
                                      ],
                                    );
                                  }),
                            if (widget.homePageCommentData.commentToBy == null)
                              SizedBox(
                                height: 4,
                              ),
                            EllipsisText(
                              text: widget.homePageCommentData.commentText,
                              maxLength: 80,
                              onMorePressed: () {},
                              textStyle:
                                  TextStyle(color: Colors.black, fontSize: 11),
                              moreText: 'more',
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Builder(builder: (context) {
                              String? thisUser =
                                  SupabaseConfig.client.auth.currentUser?.id;
                              bool commentIsThisUser = thisUser ==
                                  widget.homePageCommentData.commentBy;
                              return Row(
                                children: [
                                  CustomOnClickContainer(
                                    onTap: () {
                                      widget.onClickedQuick(
                                          "Reply",
                                          widget.homePageCommentData,
                                          widget.commentLikesNotifier);
                                    },
                                    defaultColor: Colors.transparent,
                                    clickedColor: Colors.grey.shade200,
                                    child: Text(
                                      "Reply",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.7),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (commentIsThisUser)
                                    SizedBox(
                                      width: 16,
                                    ),
                                  if (commentIsThisUser)
                                    CustomOnClickContainer(
                                      onTap: () {
                                        widget.onClickedQuick(
                                            "Delete",
                                            widget.homePageCommentData,
                                            widget.commentLikesNotifier);
                                      },
                                      defaultColor: Colors.transparent,
                                      clickedColor: Colors.grey.shade200,
                                      child: Text(
                                        "Delete",
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.red.withOpacity(0.8),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (!widget.homePageCommentData.online)
                                          Text(
                                            "Not Synced",
                                            style: TextStyle(
                                                color: Color(getDarkGreyColor),
                                                fontSize: 12),
                                          )
                                      ],
                                    ),
                                  )
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      CustomOnClickContainer(
                        onTap: () {
                          widget.onClickedQuick(
                              "Like",
                              widget.homePageCommentData,
                              widget.commentLikesNotifier);
                        },
                        defaultColor: Colors.transparent,
                        clickedColor: Colors.grey.shade200,
                        child: WidgetStateConsumer(
                            widgetStateNotifier:
                                widget.commentLikesNotifier.state,
                            widgetStateBuilder: (context, commentLikes) {
                              String thisUser =
                                  SupabaseConfig.client.auth.currentUser?.id ??
                                      '';
                              bool isLiked = commentLikes
                                      ?.where((element) =>
                                          element.membersId == thisUser)
                                      .isNotEmpty ??
                                  false;

                              return Column(
                                children: [
                                  Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isLiked ? Colors.red : Colors.black,
                                    size: 24,
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Builder(builder: (context) {
                                    int likes = commentLikes?.length ?? 0;
                                    if (likes < 1) {
                                      return SizedBox();
                                    }
                                    return Text(
                                      likes.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    );
                                  })
                                ],
                              );
                            }),
                      )
                    ],
                  ),
                  if (widget.homePageCommentData.commentsPost.isNotEmpty)
                    SizedBox(
                      height: 8,
                    ),
                  if (widget.homePageCommentData.commentsPost.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: WidgetStateConsumer(
                              widgetStateNotifier:
                                  subCommentPaginateSizeNotifier,
                              widgetStateBuilder: (context, paginateSize) {
                                int listLength() {
                                  int length = widget
                                      .homePageCommentData.commentsPost.length;
                                  if (paginateSize > length) {
                                    return length;
                                  }
                                  return paginateSize;
                                }

                                int size = listLength();
                                return CustomWrapListBuilder(
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: size,
                                    wrapListBuilder: (context, index) {
                                      HomePageCommentData homePageCommentData =
                                          widget.homePageCommentData
                                              .commentsPost.reversed
                                              .toList()
                                              .sublist(
                                                0,
                                              )[index];

                                      CommentLikesNotifier?
                                          commentLikesNotifier = widget
                                              .commentsNotifier
                                              .getCommentLikeNotifier(
                                                  homePageCommentData.commentId,
                                                  NotifierType.normal);

                                      PostProfileNotifier? postProfileNotifier =
                                          widget.commentsNotifier
                                              .getPostProfileNotifier(
                                                  homePageCommentData.commentBy,
                                                  NotifierType.normal);

                                      PostProfileNotifier?
                                          postToProfileNotifier = widget
                                              .commentsNotifier
                                              .getPostProfileNotifier(
                                                  homePageCommentData
                                                          .commentToBy ??
                                                      "",
                                                  NotifierType.normal);

                                      bool showComment =
                                          commentLikesNotifier != null &&
                                              postProfileNotifier != null;

                                      return showComment
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 16),
                                              child: Column(
                                                children: [
                                                  HomePageCommentView(
                                                    index: index,
                                                    imageSize: 30,
                                                    textSize: widget.textSize,
                                                    homePagePostData:
                                                        widget.homePagePostData,
                                                    onClickedQuick:
                                                        widget.onClickedQuick,
                                                    homePageCommentData:
                                                        homePageCommentData,
                                                    commentLikesNotifier:
                                                        commentLikesNotifier,
                                                    commentsNotifier:
                                                        widget.commentsNotifier,
                                                    onClickedInfo:
                                                        widget.onClickedInfo,
                                                    postProfileNotifier:
                                                        postProfileNotifier,
                                                    postToProfileNotifier:
                                                        postToProfileNotifier,
                                                    fromComment:
                                                        widget.fromComment,
                                                  ),
                                                  if (index + 1 == size)
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        // Show More
                                                        if (paginateSize <
                                                            widget
                                                                .homePageCommentData
                                                                .commentsPost
                                                                .length)
                                                          CustomOnClickContainer(
                                                              defaultColor: Colors
                                                                  .transparent,
                                                              clickedColor:
                                                                  Colors.grey
                                                                      .shade200,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              onTap: () {
                                                                subCommentPaginateSizeNotifier.sendNewState(
                                                                    subCommentPaginateSizeNotifier
                                                                            .currentValue +
                                                                        defaultCommentPaginate);
                                                              },
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(4),
                                                                child: Text(
                                                                  "Show more",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.7),
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                              )),
                                                        // Show Less
                                                        if (paginateSize >
                                                            defaultCommentPaginate)
                                                          CustomOnClickContainer(
                                                              defaultColor: Colors
                                                                  .transparent,
                                                              clickedColor:
                                                                  Colors.grey
                                                                      .shade200,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              onTap: () {
                                                                if (subCommentPaginateSizeNotifier
                                                                        .currentValue >
                                                                    defaultCommentPaginate) {
                                                                  subCommentPaginateSizeNotifier.sendNewState(
                                                                      subCommentPaginateSizeNotifier
                                                                              .currentValue -
                                                                          defaultCommentPaginate);
                                                                }
                                                              },
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(4),
                                                                child: Text(
                                                                  "Show less",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.7),
                                                                      fontSize:
                                                                          13,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                              )),
                                                      ],
                                                    )
                                                ],
                                              ),
                                            )
                                          : SizedBox();
                                    });
                              }),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
