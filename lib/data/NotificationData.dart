import 'package:yabnet/data/HomePageCommentData.dart';
import 'package:yabnet/data/HomePagePostData.dart';
import 'package:yabnet/data/LikesData.dart';
import 'package:yabnet/data_notifiers/PostProfileNotifier.dart';

import 'MentionsData.dart';
import 'UserData.dart';

class NotificationData {
  final String runTimeIdentity;
  final String? notificationId;
  final HomePagePostData? notificationIsOtherPost;
  final LikesData? notificationIsUserLike;
  final HomePageCommentData? notificationIsUserComment;
  final HomePagePostData? notificationLikeAndCommentData;
  final HomePagePostData? notificationIsUserRepost;
  final MentionsData? notificationIsMentions;
  final PostProfileNotifier? postProfileNotifier;
  final String? notificationIsSuggestion;
  final String? notificationCreatedAt;

  NotificationData(
      this.runTimeIdentity,
      this.notificationId,
      this.notificationIsOtherPost,
      this.notificationIsUserLike,
      this.notificationIsUserComment,
      this.notificationLikeAndCommentData,
      this.notificationIsUserRepost,
      this.notificationIsMentions,
      this.postProfileNotifier,
      this.notificationIsSuggestion,
      this.notificationCreatedAt);

  Map<String, dynamic> toJson() {
    return {
      'runTimeIdentity': runTimeIdentity,
      'notificationId': notificationId,
      'notificationIsOtherPost': notificationIsOtherPost?.toJson(),
      'notificationIsUserLike': notificationIsUserLike?.toJson(),
      'notificationIsUserComment': notificationIsUserComment?.toJson(),
      'notificationLikeAndCommentData':
          notificationLikeAndCommentData?.toJson(),
      'notificationIsUserRepost': notificationIsUserRepost?.toJson(),
      'notificationIsMentions': notificationIsMentions?.toJson(),
      'postProfileData': null,
      'notificationIsSuggestion': notificationIsSuggestion,
      'notificationCreatedAt': notificationCreatedAt,
    };
  }

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      json['runTimeIdentity'],
      json['notificationId'],
      json['notificationIsOtherPost'] != null
          ? HomePagePostData.fromJson(json['notificationIsOtherPost'])
          : null,
      json['notificationIsUserLike'] != null
          ? LikesData.fromJson(json['notificationIsUserLike'])
          : null,
      json['notificationIsUserComment'] != null
          ? HomePageCommentData.fromJson(json['notificationIsUserComment'])
          : null,
      json['notificationLikeAndCommentData'] != null
          ? HomePagePostData.fromJson(json['notificationLikeAndCommentData'])
          : null,
      json['notificationIsUserRepost'] != null
          ? HomePagePostData.fromJson(json['notificationIsUserRepost'])
          : null,
      json['notificationIsMentions'] != null
          ? MentionsData.fromJson(json['notificationIsMentions'])
          : null,
      null,
      json['notificationIsSuggestion'],
      json['notificationCreatedAt'],
    );
  }

  NotificationData copyWith({
    String? notificationId,
    HomePagePostData? notificationIsOtherPost,
    LikesData? notificationIsUserLike,
    HomePageCommentData? notificationIsUserComment,
    HomePagePostData? notificationLikeAndCommentData,
    HomePagePostData? notificationIsUserRepost,
    MentionsData? notificationIsMentions,
    PostProfileNotifier? postProfileNotifier,
    String? notificationIsSuggestion,
    UserData? userData,
    String? notificationCreatedAt,
  }) {
    return NotificationData(
      this.runTimeIdentity,
      notificationId ?? this.notificationId,
      notificationIsOtherPost ?? this.notificationIsOtherPost,
      notificationIsUserLike ?? this.notificationIsUserLike,
      notificationIsUserComment ?? this.notificationIsUserComment,
      notificationLikeAndCommentData ?? this.notificationLikeAndCommentData,
      notificationIsUserRepost ?? this.notificationIsUserRepost,
      notificationIsMentions ?? this.notificationIsMentions,
      postProfileNotifier ?? this.postProfileNotifier,
      notificationIsSuggestion ?? this.notificationIsSuggestion,
      notificationCreatedAt ?? this.notificationCreatedAt,
    );
  }
}
