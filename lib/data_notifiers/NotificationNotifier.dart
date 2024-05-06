// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:open_document/my_files/init.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/data/HomePageCommentData.dart';
import 'package:yabnet/data/HomePagePostData.dart';
import 'package:yabnet/data/LikesData.dart';
import 'package:yabnet/data/MentionsData.dart';
import 'package:yabnet/data/NotificationData.dart';
import 'package:yabnet/data_notifiers/CommentsNotifier.dart';
import 'package:yabnet/data_notifiers/PostNotifier.dart';
import 'package:yabnet/data_notifiers/PostProfileNotifier.dart';
import 'package:yabnet/data_notifiers/UserConnectsNotifier.dart';
import 'package:yabnet/db_references/NotifierType.dart';
import 'package:yabnet/operations/NotificationOperation.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../builders/CustomWrapListBuilder.dart';
import '../components/CustomProject.dart';
import '../db_references/Comments.dart';
import '../db_references/Likes.dart';
import '../db_references/Members.dart';
import '../db_references/Mentions.dart';
import '../db_references/Notification.dart' as not;
import '../db_references/Post.dart';

class NotificationImplement {
  BuildContext? getLatestContext() => null;

  RetryStreamListener? getRetryStreamListener() => null;

  PaginationProgressController? getPaginationProgressController() => null;
}

class NotificationNotifier {
  WidgetStateNotifier<List<NotificationData>> state = WidgetStateNotifier();

  List<NotificationData> _data = [];

  NotificationImplement? _notificationImplements;

  bool started = false;
  String otherPostFromTime = DateTime.now().toUtc().toString();
  String likePostFromTime = DateTime.now().toUtc().toString();
  String commentFromTime = DateTime.now().toUtc().toString();
  String mentionFromTime = DateTime.now().toUtc().toString();
  String commentLikePostFromTime = DateTime.now().toUtc().toString();

  static final NotificationNotifier instance = NotificationNotifier.internal();

  factory NotificationNotifier() => instance;

  NotificationNotifier.internal();

  StreamSubscription? postLikeStream;

  NotificationNotifier start(NotificationImplement notificationImplement,
      {bool startFetching = true}) {
    BuildContext? buildContext = notificationImplement.getLatestContext();
    if (buildContext != null) {
      _notificationImplements = notificationImplement;
      if (startFetching) {
        _startFetching();
      }
      _attachListeners(notificationImplement);
    }
    return this;
  }

  void _startFetching() {
    started = true;
    _fetchPostOnline();
  }

  List<NotificationData> getLatestData() {
    return _data;
  }

  void _retryListener() {
    restart();
  }

  void _attachListeners(NotificationImplement commentImplement) {
    RetryStreamListener? _retryStreamListener =
        commentImplement.getRetryStreamListener();
    _retryStreamListener?.addListener(_retryListener);
  }

  void restart() {
    if (started) {
      _fetchPostOnline();
    }
  }

  void stop() {
    _notificationImplements
        ?.getRetryStreamListener()
        ?.removeListener(_retryListener);
  }

  Future<void> _fetchPostOnline() async {
    _fetchNotification();
  }

  void _fetchNotification() async {
    final connectionsIds =
        UserConnectsNotifier().state.currentValue?.connection;
    final otherPost =
        _fetchOtherPost(connectionsIds?.map((e) => e.membersId).toList() ?? []);
    final postLikes = _getPostLike();
    final commentLikes = _getCommentLike();
    final comment = _getComment();
    final mentions = _fetchMentionedPost();

    final operation = await Future.wait(
        [otherPost, postLikes, comment, commentLikes, mentions]);

    final data = operation.fold(<NotificationData>[], (previousValue, element) {
      previousValue.addAll(element);
      return previousValue;
    });

    _configure(data);
  }

  String foreignKey(String secondTable, String thisTable, String onTableKey) {
    return "$secondTable!${thisTable}_${onTableKey}_fkey";
  }

  Future<List<NotificationData>> _fetchMentionedPost() async {
    String? thisUser = SupabaseConfig.client.auth.currentUser?.id;

    if (thisUser != null) {
      // Fetch Mentions
      final mentions = await NotificationOperation()
          .getPostMentions(thisUser, mentionFromTime, 10);

      // Get their notification status
      final notificationCheckFuture = mentions
          .asMap()
          .map((key, value) {
            final mentionId = value[dbReference(Mentions.id)];
            final notification =
                NotificationOperation().getNotificationAboutMention(mentionId);
            return MapEntry(key, notification);
          })
          .values
          .toList();

      // Get status result
      final notificationCheck = await Future.wait(notificationCheckFuture);

      // Return the post Data
      final notificationFuture = notificationCheck
          .asMap()
          .map((key, value) {
            final otherPost = PostNotifier().getPublicPostLinkedData(
                mentions[key][dbReference(Post.table)], [
              mentions[key][dbReference(Post.table)][dbReference(Members.id)]
            ]);
            return MapEntry(key, otherPost);
          })
          .values
          .toList();

      // Get the post data result
      final notification = await Future.wait(notificationFuture);

      // Parse to notification
      final data = notification
          .asMap()
          .map((key, value) {
            String? notificationId =
                notificationCheck[key]?[dbReference(not.Notification.id)];
            HomePagePostData? homePagePostData = notification[key];
            PostProfileNotifier? postProfileNotifier = PostNotifier()
                .getPostProfileNotifier(
                    homePagePostData?.postBy ?? '', NotifierType.external);

            MentionsData? mentionsData = MentionsData(
              mentionId: mentions[key][dbReference(Mentions.id)],
              mentionWho: mentions[key][dbReference(Members.id)],
              membersId: mentions[key][dbReference(Post.table)]
                  [dbReference(Members.id)],
            );

            return MapEntry(
                key,
                NotificationData(
                    NotificationOperation().getNotificationRunTimeId(),
                    notificationId,
                    null,
                    null,
                    null,
                    homePagePostData,
                    null,
                    mentionsData,
                    postProfileNotifier,
                    null,
                    homePagePostData?.postCreatedAt));
          })
          .values
          .toList();

      final dates = notification.map((e) => e?.postCreatedAt).toList();
      dates.sort();
      getMentionReceived(dates.reversed.lastOrNull);
      return data;
    } else {
      return [];
    }
  }

  Future<List<NotificationData>> _getComment() async {
    String? thisUser = SupabaseConfig.client.auth.currentUser?.id;
    if (thisUser != null) {
      //  Get other comments
      final comments = await NotificationOperation()
          .getPostComments(thisUser, commentFromTime, 10);

      // Get their notification status
      final notificationCheckFuture = comments
          .asMap()
          .map((key, value) {
            final commentId = value[dbReference(Comments.id)];
            final notification =
                NotificationOperation().getNotificationAboutComment(commentId);
            return MapEntry(key, notification);
          })
          .values
          .toList();

      // Get status result
      final notificationCheck = await Future.wait(notificationCheckFuture);

      // Return the post Data
      final notificationPostFuture = notificationCheck
          .asMap()
          .map((key, value) {
            final otherPost = PostNotifier().getPublicPostLinkedData(
                comments[key][dbReference(Post.table)],
                [comments[key][dbReference(Members.id)]]);
            return MapEntry(key, otherPost);
          })
          .values
          .toList();

      // Get the post data result
      final notificationPost = await Future.wait(notificationPostFuture);

      // Return comment data
      final notificationCommentsFuture = notificationPost
          .asMap()
          .map((key, value) {
            final otherPost = CommentsNotifier().getPublicCommentLinkedData(
                comments[key], notificationPost[key]?.postId);
            return MapEntry(key, otherPost);
          })
          .values
          .toList();

      // Get the comment data result
      final notificationComments =
          await Future.wait(notificationCommentsFuture);

      // Parse to notification
      final data = notificationComments
          .asMap()
          .map((key, value) {
            String? notificationId =
                notificationCheck[key]?[dbReference(not.Notification.id)];
            HomePagePostData? homePagePostData = notificationPost[key];

            PostProfileNotifier? postProfileNotifier = PostNotifier()
                .getPostProfileNotifier(comments[key][dbReference(Members.id)],
                    NotifierType.external);

            HomePageCommentData? homePageCommentData = value;

            return MapEntry(
                key,
                NotificationData(
                    NotificationOperation().getNotificationRunTimeId(),
                    notificationId,
                    null,
                    null,
                    homePageCommentData,
                    homePagePostData,
                    null,
                    null,
                    postProfileNotifier,
                    null,
                    comments[key][dbReference(Comments.created_at)]));
          })
          .values
          .toList();

      final dates =
          comments.map((e) => e[dbReference(Comments.created_at)]).toList();
      dates.sort();
      getCommentReceived(dates.reversed.lastOrNull);

      return data;
    } else {
      return [];
    }
  }

  Future<List<NotificationData>> _getCommentLike() async {
    String? thisUser = SupabaseConfig.client.auth.currentUser?.id;
    if (thisUser != null) {
      //  Get other likes
      final likes = await NotificationOperation()
          .getPostCommentLike(thisUser, commentLikePostFromTime, 10);

      // Get their notification status
      final notificationCheckFuture = likes
          .asMap()
          .map((key, value) {
            final likeId = value[dbReference(Likes.id)];
            final notification =
                NotificationOperation().getNotificationAboutLikes(likeId);
            return MapEntry(key, notification);
          })
          .values
          .toList();

      // Get status result
      final notificationCheck = await Future.wait(notificationCheckFuture);

      // Return the post Data
      final notificationPostFuture = notificationCheck
          .asMap()
          .map((key, value) {
            final otherPost = PostNotifier().getPublicPostLinkedData(
                likes[key][dbReference(Comments.table)]
                    [dbReference(Post.table)],
                [likes[key][dbReference(Members.id)]]);
            return MapEntry(key, otherPost);
          })
          .values
          .toList();

      // Get the post data result
      final notificationPost = await Future.wait(notificationPostFuture);

      // Return comment data
      final notificationCommentsFuture = notificationPost
          .asMap()
          .map((key, value) {
            final otherPost = CommentsNotifier().getPublicCommentLinkedData(
                likes[key][dbReference(Comments.table)],
                notificationPost[key]?.postId);
            return MapEntry(key, otherPost);
          })
          .values
          .toList();

      // Get the comment data result
      final notificationComments =
          await Future.wait(notificationCommentsFuture);

      // Parse to notification
      final data = notificationComments
          .asMap()
          .map((key, value) {
            String? notificationId =
                notificationCheck[key]?[dbReference(not.Notification.id)];
            HomePagePostData? homePagePostData = notificationPost[key];

            PostProfileNotifier? postProfileNotifier = PostNotifier()
                .getPostProfileNotifier(
                    likes[key][dbReference(Members.id)], NotifierType.external);

            HomePageCommentData? homePageCommentData = value;
            LikesData likesData = LikesData.fromOnline(likes[key],
                postProfileNotifier?.getLatestData()?.fullName ?? 'Error');

            return MapEntry(
                key,
                NotificationData(
                    NotificationOperation().getNotificationRunTimeId(),
                    notificationId,
                    null,
                    likesData,
                    homePageCommentData,
                    homePagePostData,
                    null,
                    null,
                    postProfileNotifier,
                    null,
                    likes[key][dbReference(Likes.created_at)]));
          })
          .values
          .toList();

      final dates = likes.map((e) => e[dbReference(Likes.created_at)]).toList();
      dates.sort();
      getCommentLikeReceived(dates.reversed.lastOrNull);

      return data;
    } else {
      return [];
    }
  }

  Future<List<NotificationData>> _getPostLike() async {
    String? thisUser = SupabaseConfig.client.auth.currentUser?.id;
    if (thisUser != null) {
      //  Get other likes
      final likes = await NotificationOperation()
          .getPostLikes(thisUser, likePostFromTime, 10);

      likes.removeWhere((element) =>
          element[dbReference(Post.table)][dbReference(Post.reposted)] != null);

      // Get their notification status
      final notificationCheckFuture = likes
          .asMap()
          .map((key, value) {
            final likeId = value[dbReference(Likes.id)];
            final notification =
                NotificationOperation().getNotificationAboutLikes(likeId);
            return MapEntry(key, notification);
          })
          .values
          .toList();

      // Get status result
      final notificationCheck = await Future.wait(notificationCheckFuture);

      // Return the post Data
      final notificationFuture = notificationCheck
          .asMap()
          .map((key, value) {
            final otherPost = PostNotifier().getPublicPostLinkedData(
                likes[key][dbReference(Post.table)],
                [likes[key][dbReference(Members.id)]]);
            return MapEntry(key, otherPost);
          })
          .values
          .toList();

      // Get the post data result
      final notification = await Future.wait(notificationFuture);

      // Parse to notification
      final data = notification
          .asMap()
          .map((key, value) {
            String? notificationId =
                notificationCheck[key]?[dbReference(not.Notification.id)];
            HomePagePostData? homePagePostData = notification[key];

            PostProfileNotifier? postProfileNotifier = PostNotifier()
                .getPostProfileNotifier(
                    likes[key][dbReference(Members.id)], NotifierType.external);

            LikesData likesData = LikesData.fromOnline(likes[key],
                postProfileNotifier?.getLatestData()?.fullName ?? 'Error');

            return MapEntry(
                key,
                NotificationData(
                    NotificationOperation().getNotificationRunTimeId(),
                    notificationId,
                    null,
                    likesData,
                    null,
                    homePagePostData,
                    null,
                    null,
                    postProfileNotifier,
                    null,
                    likes[key][dbReference(Likes.created_at)]));
          })
          .values
          .toList();

      final dates = likes.map((e) => e[dbReference(Likes.created_at)]).toList();
      dates.sort();
      getPostLikeReceived(dates.reversed.lastOrNull);

      return data;
    } else {
      return [];
    }
  }

  void updateThisNotificationId(String runTimeId, String notificationId) {
    int found =
        _data.indexWhere((element) => element.runTimeIdentity == runTimeId);
    if (found != -1) {
      _data[found] = _data[found].copyWith(notificationId: notificationId);
      sendUpdateToUi();
    }
  }

  Future<List<NotificationData>> _fetchOtherPost(
      List<String> connectionIds) async {
    // Fetch Other post
    final posts = await NotificationOperation()
        .getOtherPost(connectionIds, otherPostFromTime, 10);

    // Remove any repost
    posts.removeWhere((element) => element[dbReference(Post.reposted)] != null);

    // Get their notification status
    final notificationCheckFuture = posts
        .asMap()
        .map((key, value) {
          final postId = value[dbReference(Post.id)];
          final notification =
              NotificationOperation().getNotificationAboutOther(postId);
          return MapEntry(key, notification);
        })
        .values
        .toList();

    // Get status result
    final notificationCheck = await Future.wait(notificationCheckFuture);

    // Return the post Data
    final notificationFuture = notificationCheck
        .asMap()
        .map((key, value) {
          final otherPost = PostNotifier().getPublicPostLinkedData(
              posts[key], [posts[key][dbReference(Members.id)]]);
          return MapEntry(key, otherPost);
        })
        .values
        .toList();

    // Get the post data result
    final notification = await Future.wait(notificationFuture);

    // Parse to notification
    final data = notification
        .asMap()
        .map((key, value) {
          String? notificationId =
              notificationCheck[key]?[dbReference(not.Notification.id)];
          HomePagePostData? homePagePostData = notification[key];
          PostProfileNotifier? postProfileNotifier = PostNotifier()
              .getPostProfileNotifier(
                  homePagePostData?.postBy ?? '', NotifierType.external);

          return MapEntry(
              key,
              NotificationData(
                  NotificationOperation().getNotificationRunTimeId(),
                  notificationId,
                  homePagePostData,
                  null,
                  null,
                  null,
                  null,
                  null,
                  postProfileNotifier,
                  null,
                  homePagePostData?.postCreatedAt));
        })
        .values
        .toList();

    final dates = notification.map((e) => e?.postCreatedAt).toList();
    dates.sort();
    getOtherPostReceived(dates.reversed.lastOrNull);
    return data;
  }

  Future<void> getOtherPostReceived(String? time) async {
    if (time != null) {
      otherPostFromTime = time;
    }
  }

  Future<void> getPostLikeReceived(String? time) async {
    if (time != null) {
      likePostFromTime = time;
    }
  }

  Future<void> getCommentLikeReceived(String? time) async {
    if (time != null) {
      commentLikePostFromTime = time;
    }
  }

  Future<void> getCommentReceived(String? time) async {
    if (time != null) {
      commentFromTime = time;
    }
  }

  Future<void> getMentionReceived(String? time) async {
    if (time != null) {
      mentionFromTime = time;
    }
  }

  void updateLatestData(List<NotificationData> allNotifications) {
    _data.addAll(allNotifications);

    _data.sort((a, b) {
      if (a.notificationCreatedAt != null && b.notificationCreatedAt != null) {
        return DateTime.parse(a.notificationCreatedAt!)
                .isBefore(DateTime.parse(b.notificationCreatedAt!))
            ? 1
            : 0;
      }
      return 0;
    });
  }

  void _configure(List<NotificationData> allNotifications) {
    updateLatestData(allNotifications);
    sendUpdateToUi();
  }

  void sendUpdateToUi() {
    if (_data.isNotEmpty) {
      state.sendNewState(_data);
    }
  }
}
