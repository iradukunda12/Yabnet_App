import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/data/HomePagePostData.dart';
import 'package:yabnet/data_notifiers/PostNotifier.dart';
import 'package:yabnet/handler/SingleHomePagePostViewHandler.dart';
import 'package:yabnet/operations/NotificationOperation.dart';

import '../builders/ControlledStreamBuilder.dart';
import '../builders/CustomWrapListBuilder.dart';
import '../components/CustomProject.dart';
import '../components/NotificationView.dart';
import '../data/NotificationData.dart';
import '../data_notifiers/CommentsNotifier.dart';
import '../data_notifiers/ConnectsNotifier.dart';
import '../data_notifiers/LikesNotifier.dart';
import '../data_notifiers/NotificationNotifier.dart';
import '../data_notifiers/PostProfileNotifier.dart';
import '../data_notifiers/RepostsNotifier.dart';
import '../db_references/NotifierType.dart';
import '../main.dart';

class AnnouncementPageAllNotificationHandler extends StatefulWidget {
  final WidgetStateNotifier<int> handlerNotifier;

  const AnnouncementPageAllNotificationHandler(
      {super.key, required this.handlerNotifier});

  @override
  State<AnnouncementPageAllNotificationHandler> createState() =>
      _AnnouncementPageAllNotificationHandlerState();
}

class _AnnouncementPageAllNotificationHandlerState
    extends State<AnnouncementPageAllNotificationHandler>
    implements NotificationImplement {
  @override
  BuildContext? getLatestContext() {
    return context;
  }

  @override
  PaginationProgressController? getPaginationProgressController() {
    return null;
  }

  @override
  RetryStreamListener? getRetryStreamListener() {
    return null;
  }

  @override
  void initState() {
    super.initState();
    NotificationNotifier().start(this);
  }

  @override
  void dispose() {
    super.dispose();
    NotificationNotifier().stop();
  }

  String getText(int? filter, bool? isEmpty) {
    final title = {
      0: "posts",
      1: "post activities",
      2: "post mentions",
    };
    if (filter != null && isEmpty == true)
      return "There are no ${title[filter] ?? "post"}";
    return "An error has occurred";
    ;
  }

  List<NotificationData>? getMappedData(
      List<NotificationData>? notification, int? filter) {
    if (filter == 1) {
      return notification
          ?.where((element) =>
              element.notificationIsOtherPost == null &&
              element.notificationIsMentions == null)
          .toList();
    } else if (filter == 2) {
      return notification
          ?.where((element) => element.notificationIsMentions != null)
          .toList();
    }

    return notification;
  }

  void handleNotificationPresses(NotificationData notification) async {
    void created(dynamic value) {
      closeCustomProgressBar(context);
    }

    if (notification.notificationId == null) {
      if (notification.notificationIsOtherPost == null) {
        bool isLikedActivity = notification.notificationIsUserLike != null;
        bool isCommentLikedActivity =
            notification.notificationIsUserLike != null &&
                notification.notificationLikeAndCommentData != null;
        bool isCommentActivity =
            notification.notificationLikeAndCommentData != null &&
                notification.notificationIsUserComment != null &&
                notification.notificationIsUserLike == null;
        bool isMention = notification.notificationIsMentions != null;

        if (isLikedActivity) {
          String likeId = notification.notificationIsUserLike!.likesId;
          NotificationOperation()
              .handleNotificationChecked(likeId, notification.runTimeIdentity);
          NotificationOperation().sendNotificationLikedChecked(
              likeId, notification.runTimeIdentity);
        } else if (isCommentLikedActivity) {
          String likeId = notification.notificationIsUserLike!.likesId;
          NotificationOperation()
              .handleNotificationChecked(likeId, notification.runTimeIdentity);
          NotificationOperation().sendNotificationLikedChecked(
              likeId, notification.runTimeIdentity);
        } else if (isCommentActivity) {
          String commentId = notification.notificationIsUserComment!.commentId;
          NotificationOperation().handleNotificationChecked(
              commentId, notification.runTimeIdentity);
          NotificationOperation().sendNotificationCommentChecked(
              commentId, notification.runTimeIdentity);
        } else if (isMention) {
          String mentionId = notification.notificationIsMentions!.mentionId;
          NotificationOperation().handleNotificationChecked(
              mentionId, notification.runTimeIdentity);
          NotificationOperation().sendNotificationMentionChecked(
              mentionId, notification.runTimeIdentity);
        }
      }
    }

    late HomePagePostData homePagePostData;
    if (notification.notificationIsOtherPost == null) {
      homePagePostData = notification.notificationLikeAndCommentData!;
    } else {
      homePagePostData = notification.notificationIsOtherPost!;
    }

    showCustomProgressBar(context);
    await PostNotifier()
        .getPublicPostLinkedNotifiers(
            homePagePostData.postId, homePagePostData.postBy)
        .then(created);

    PostNotifier postNotifier = PostNotifier();
    CommentsNotifier? commentsNotifier = postNotifier.getCommentNotifier(
        homePagePostData.postId, NotifierType.external);
    LikesNotifier? likesNotifier = postNotifier.getLikeNotifier(
        homePagePostData.postId, NotifierType.external);

    RepostsNotifier? repostsNotifier = postNotifier.getRepostsNotifier(
        homePagePostData.postId, NotifierType.external);

    ConnectsNotifier? connectsNotifier = postNotifier.getConnectsNotifier(
        homePagePostData.postBy, NotifierType.external);

    PostProfileNotifier? postProfileNotifier = postNotifier
        .getPostProfileNotifier(homePagePostData.postBy, NotifierType.external);

    bool check = commentsNotifier != null &&
        likesNotifier != null &&
        repostsNotifier != null &&
        connectsNotifier != null &&
        postProfileNotifier != null;

    // Likes
    likesNotifier?.restart();
    // Repost
    repostsNotifier?.restart();
    // connects
    connectsNotifier?.restart();
    if (check) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SingleHomePagePostViewHandler(
                  homePagePostData: homePagePostData,
                  commentsNotifier: commentsNotifier,
                  likesNotifier: likesNotifier,
                  repostsNotifier: repostsNotifier,
                  connectsNotifier: connectsNotifier,
                  postProfileNotifier: postProfileNotifier))).then((value) {
        setNormalUiViewOverlay();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WidgetStateConsumer(
        widgetStateNotifier: widget.handlerNotifier,
        widgetStateBuilder: (context, filter) {
          return WidgetStateConsumer(
              widgetStateNotifier: NotificationNotifier().state,
              widgetStateBuilder: (context, notification) {
                List<NotificationData>? data =
                    getMappedData(notification, filter);
                if (data == null && filter != null) {
                  return SizedBox(
                      height: getScreenHeight(context) * 0.5,
                      child: Center(child: progressBarWidget()));
                }

                if (data?.isEmpty == true || filter == null) {
                  return Container(
                    height: 0.25 * getScreenHeight(context),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(),
                        border: Border(
                            top: BorderSide(
                                color: Color(getDarkGreyColor), width: 0.3))),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(
                                getText(filter, data?.isEmpty),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17),
                              )),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }

                return CustomWrapListBuilder(
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: data!.length,
                    wrapListBuilder: (context, index) {
                      NotificationData notification = data[index];
                      return Padding(
                        padding: EdgeInsets.only(
                            bottom: (index + 1 == data.length) ? 8.0 : 0),
                        child: NotificationWidget(
                          notification: notification,
                          onTap: () {
                            handleNotificationPresses(notification);
                          },
                        ),
                      );
                    });
              });
        });
  }
}
