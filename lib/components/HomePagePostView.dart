import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/data/ConnectInfo.dart';
import 'package:yabnet/data/HomePageCommentData.dart';
import 'package:yabnet/data/PostProfileData.dart';
import 'package:yabnet/data/RepostData.dart';
import 'package:yabnet/data_notifiers/ConnectsNotifier.dart';
import 'package:yabnet/data_notifiers/LikesNotifier.dart';
import 'package:yabnet/data_notifiers/PostProfileNotifier.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/operations/PostOperation.dart';

import '../collections/common_collection/ProfileImage.dart';
import '../data/HomePagePostData.dart';
import '../data_notifiers/CommentsNotifier.dart';
import '../data_notifiers/RepostsNotifier.dart';
import '../handler/HomePageMediaHandler.dart';
import '../supabase/SupabaseConfig.dart';
import 'EllipsisText.dart';

class HomePagePostView extends StatefulWidget {
  final bool fromHome;
  final int? index;
  final HomePagePostData homePagePostData;
  final CommentsNotifier commentsNotifier;
  final LikesNotifier likesNotifier;
  final RepostsNotifier repostsNotifier;
  final ConnectsNotifier connectsNotifier;
  final PostProfileNotifier postProfileNotifier;
  final Function(String operation) onClickedQuick;
  final Function(ConnectInfo? connectInfo) onClickedInfo;
  final Function(int mediaIndex) onClickedMedia;

  const HomePagePostView(
      {super.key,
      required this.homePagePostData,
      required this.index,
      required this.onClickedQuick,
      required this.onClickedMedia,
      required this.commentsNotifier,
      required this.likesNotifier,
      required this.repostsNotifier,
      required this.connectsNotifier,
      required this.onClickedInfo,
      required this.postProfileNotifier,
      this.fromHome = false});

  @override
  State<HomePagePostView> createState() => _HomePagePostViewState();
}

class _HomePagePostViewState extends State<HomePagePostView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade500,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.index == -1 ? 0 : 8),
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    SizedBox(
                      height: 12,
                    ),
                    //   Top suggestion

                    //Profiling

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          // Image
                          Container(
                              height: 50,
                              width: 50,
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8)),
                              child: WidgetStateConsumer(
                                  widgetStateNotifier:
                                      widget.postProfileNotifier.state,
                                  widgetStateBuilder: (context, data) {
                                    return ProfileImage(
                                      iconSize: 50,
                                      canDisplayImage: true,
                                      fromHome: widget.fromHome,
                                      imageUri: MembersOperation()
                                          .getMemberProfileBucketPath(
                                              data?.userId ?? '',
                                              data?.profileIndex),
                                      fullName: data?.fullName ?? 'Error',
                                    );
                                  })),

                          SizedBox(
                            width: 8,
                          ),

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
                                          if (data?.userId != null) {
                                            widget.onClickedInfo(ConnectInfo(
                                                data!.userId,
                                                data.fullName,
                                                data.profileIndex));
                                          }
                                        },
                                        child: Text(
                                          data?.fullName ?? "Error",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      );
                                    }),
                                WidgetStateConsumer(
                                  widgetStateNotifier:
                                      widget.connectsNotifier.state,
                                  widgetStateBuilder: (context, data) {
                                    int connects = data?.length ?? 0;
                                    return GestureDetector(
                                      onTap: () {
                                        PostProfileData? postProfile = widget
                                            .postProfileNotifier
                                            .state
                                            .currentValue;

                                        if (postProfile?.userId != null) {
                                          widget.onClickedInfo(ConnectInfo(
                                              postProfile!.userId,
                                              postProfile.fullName,
                                              postProfile.profileIndex));
                                        }
                                      },
                                      child: Text(
                                        connects > 1
                                            ? "${PostOperation().formatNumber(connects)} Connects"
                                            : "$connects connect",
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey.shade900,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  PostOperation().formatTimeAgo(DateTime.parse(
                                      widget.homePagePostData.postCreatedAt)),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            width: 8,
                          ),
                          WidgetStateConsumer(
                              widgetStateNotifier:
                                  widget.connectsNotifier.state,
                              widgetStateBuilder: (context, data) {
                                String thisUser = SupabaseConfig
                                        .client.auth.currentUser?.id ??
                                    '';
                                bool isConnected = data
                                        ?.where((element) =>
                                            element.membersId == thisUser)
                                        .isNotEmpty ??
                                    false;

                                if (thisUser ==
                                    widget.homePagePostData.postBy) {
                                  return SizedBox();
                                }
                                return CustomOnClickContainer(
                                  onTap: () {
                                    widget.onClickedQuick("Connect");
                                  },
                                  defaultColor: Colors.transparent,
                                  clickedColor: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                  padding: EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isConnected
                                            ? Icons.check_circle
                                            : Icons.add,
                                        size: 20,
                                        color: isConnected
                                            ? Colors.green
                                            : Colors.blue,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                        isConnected ? "Connected" : "Connect",
                                        style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                );
                              })
                        ],
                      ),
                    ),

                    if (widget.homePagePostData.postMentions.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 18, right: 18, top: 12),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'Mentioned ',
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 14),
                                    ),
                                    TextSpan(
                                      text: widget.homePagePostData
                                          .postMentions[0].membersFullname,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          widget.onClickedInfo(widget
                                              .homePagePostData
                                              .postMentions[0]);
                                        },
                                    ),
                                    if (widget.homePagePostData.postMentions
                                                .length <=
                                            2 &&
                                        widget.homePagePostData.postMentions
                                                .length >
                                            1)
                                      TextSpan(
                                        text: ' and ',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    if (widget.homePagePostData.postMentions
                                            .length >
                                        2)
                                      TextSpan(
                                        text: ', ',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    if (widget.homePagePostData.postMentions
                                            .length >
                                        1)
                                      TextSpan(
                                        text: widget.homePagePostData
                                            .postMentions[1].membersFullname,
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            widget.onClickedInfo(widget
                                                .homePagePostData
                                                .postMentions[1]);
                                          },
                                      ),
                                    if (widget.homePagePostData.postMentions
                                            .length >
                                        2)
                                      TextSpan(
                                        text: ' and ',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    if (widget.homePagePostData.postMentions
                                            .length >
                                        2)
                                      TextSpan(
                                        text:
                                            '${widget.homePagePostData.postMentions.length - 2} ',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            widget.onClickedInfo(null);
                                          },
                                      ),
                                    if ((widget.homePagePostData.postMentions
                                                .length -
                                            2) ==
                                        1)
                                      TextSpan(
                                        text: 'other.',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    if ((widget.homePagePostData.postMentions
                                                .length -
                                            2) >
                                        1)
                                      TextSpan(
                                        text: 'others.',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                  ],
                                ),
                                // overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      child: EllipsisText(
                        text: widget.homePagePostData.postText,
                        maxLength: 150,
                        onMorePressed: () {},
                        textStyle: TextStyle(color: Colors.black, fontSize: 14),
                        moreText: 'more',
                      ),
                    ),

                    //   Image / Video / Document

                    if (widget.homePagePostData.postMedia.isNotEmpty)
                      SizedBox(
                        height: 12,
                      ),

                    HomePageMediaHandler(
                      media: widget.homePagePostData.postMedia,
                      height: 200,
                      width: getScreenWidth(context),
                      clicked: widget.onClickedMedia,
                    ),

                    //   Likes
                    if (widget.homePagePostData.postMedia.isNotEmpty)
                      SizedBox(
                        height: 12,
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          // Likes
                          Row(
                            children: [
                              //   Likes
                              Icon(
                                Icons.thumb_up_alt,
                                size: 20,
                                color: Colors.blue,
                              ),
                              SizedBox(
                                width: 4,
                              ),
                              WidgetStateConsumer(
                                  widgetStateNotifier:
                                      widget.likesNotifier.state,
                                  widgetStateBuilder: (context, data) {
                                    return Text(
                                      (data?.length ?? 0).toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                      ),
                                    );
                                  })
                            ],
                          ),

                          //   Comment

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 5.25),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  WidgetStateConsumer(
                                      widgetStateNotifier:
                                          widget.commentsNotifier.state,
                                      widgetStateBuilder:
                                          (context, commentsData) {
                                        int comments = (commentsData?.length ??
                                                0) +
                                            (commentsData?.fold(
                                                    0,
                                                    (previousValue, element) =>
                                                        (previousValue ?? 0) +
                                                        element.commentsPost
                                                            .length) ??
                                                0);
                                        return comments > 0
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: Row(
                                                  children: [
                                                    Builder(builder: (context) {
                                                      return Text(
                                                          comments > 1
                                                              ? "$comments Comments"
                                                              : "$comments Comment",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 14));
                                                    })
                                                  ],
                                                ),
                                              )
                                            : SizedBox();
                                      }),
                                  MultiWidgetStateConsumer(
                                      widgetStateListNotifiers: [
                                        widget.commentsNotifier.state,
                                        widget.repostsNotifier.state
                                      ],
                                      widgetStateListBuilder: (context) {
                                        List<HomePageCommentData> commentsData =
                                            widget.commentsNotifier.state
                                                    .currentValue ??
                                                [];
                                        List<RepostData> repostData = widget
                                                .repostsNotifier
                                                .state
                                                .currentValue ??
                                            [];
                                        int comments = commentsData.length +
                                            (commentsData.fold(
                                                0,
                                                (previousValue, element) =>
                                                    previousValue +
                                                    element
                                                        .commentsPost.length));
                                        return comments > 0 &&
                                                repostData.isNotEmpty
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: Container(
                                                  height: 5,
                                                  width: 5,
                                                  decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade600,
                                                      shape: BoxShape.circle),
                                                ),
                                              )
                                            : SizedBox();
                                      }),
                                  WidgetStateConsumer(
                                      widgetStateNotifier:
                                          widget.repostsNotifier.state,
                                      widgetStateBuilder:
                                          (context, repostData) {
                                        int reposts = repostData?.length ?? 0;
                                        return reposts > 0
                                            ? Row(
                                                children: [
                                                  Builder(builder: (context) {
                                                    return Text(
                                                      reposts > 1
                                                          ? "$reposts Reposts"
                                                          : "$reposts Repost",
                                                      style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 14),
                                                    );
                                                  })
                                                ],
                                              )
                                            : SizedBox();
                                      }),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),

                    // Quick Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Row(
                        children: [
                          Expanded(
                              child: Container(
                            height: 0.7,
                            color: Colors.grey.shade500,
                          )),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 5.25,
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        WidgetStateConsumer(
                            widgetStateNotifier: widget.likesNotifier.state,
                            widgetStateBuilder: (context, data) {
                              String thisUser =
                                  SupabaseConfig.client.auth.currentUser?.id ??
                                      '';
                              bool liked = data
                                      ?.where((element) =>
                                          element.membersId == thisUser)
                                      .isNotEmpty ??
                                  false;
                              return getQuickButton(
                                Icons.thumb_up,
                                "Like",
                                liked,
                              );
                            }),
                        WidgetStateConsumer(
                            widgetStateNotifier: widget.commentsNotifier.state,
                            widgetStateBuilder: (context, data) {
                              String thisUser =
                                  SupabaseConfig.client.auth.currentUser?.id ??
                                      '';
                              bool commented = false;
                              bool stop = false;

                              data?.forEach((main) {
                                if (!stop) {
                                  commented = main.commentBy == thisUser;
                                  stop = commented;
                                }
                                main.commentsPost.forEach((sub) {
                                  if (!stop) {
                                    commented = sub.commentBy == thisUser;
                                    stop = commented;
                                  }
                                });
                              });
                              return getQuickButton(
                                  Icons.message_outlined, "Comment", commented);
                            }),
                        WidgetStateConsumer(
                            widgetStateNotifier: widget.repostsNotifier.state,
                            widgetStateBuilder: (context, data) {
                              String thisUser =
                                  SupabaseConfig.client.auth.currentUser?.id ??
                                      '';
                              bool reposted = data
                                      ?.where((element) =>
                                          element.postBy == thisUser)
                                      .isNotEmpty ??
                                  false;
                              return getQuickButton(
                                  Icons.repeat, "Repost", reposted);
                            }),
                      ],
                    ),

                    SizedBox(
                      height: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getQuickButton(IconData iconData, String text, bool state) {
    return CustomOnClickContainer(
      onTap: () {
        widget.onClickedQuick(text);
      },
      defaultColor: Colors.transparent,
      clickedColor: Colors.grey.shade200,
      shape: BoxShape.circle,
      child: Row(
        children: [
          Icon(
            iconData,
            color: state ? Colors.blue : Colors.grey.shade700,
            size: 24,
          ),
          SizedBox(
            width: 4,
          ),
          Text(
            text,
            style: TextStyle(
                color: state ? Colors.blue : Colors.grey.shade700,
                fontSize: 14),
          )
        ],
      ),
    );
  }
}
