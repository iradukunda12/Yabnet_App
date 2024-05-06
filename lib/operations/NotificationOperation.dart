import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/data/HomePageCommentData.dart';
import 'package:yabnet/data/HomePagePostData.dart';
import 'package:yabnet/data/NotificationData.dart';
import 'package:yabnet/data_notifiers/NotificationNotifier.dart';
import 'package:yabnet/db_references/Mentions.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../components/CustomProject.dart';
import '../db_references/Comments.dart';
import '../db_references/Likes.dart';
import '../db_references/Members.dart';
import '../db_references/Notification.dart' as not;
import '../db_references/Post.dart';
import 'CacheOperation.dart';

class NotificationOperation {
  Future<ValueListenable<Box>?> listenable() async {
    return await CacheOperation()
        .getListenable(dbReference(not.Notification.database));
  }

  PostgrestTransformBuilder<PostgrestMap?> getNotificationAboutOther(
      String postId) {
    return SupabaseConfig.client
        .from(dbReference(not.Notification.table))
        .select()
        .eq(dbReference(not.Notification.is_other_post), postId)
        .maybeSingle();
  }

  PostgrestTransformBuilder<PostgrestMap?> getNotificationAboutMention(
      String mentionId) {
    return SupabaseConfig.client
        .from(dbReference(not.Notification.table))
        .select()
        .eq(dbReference(not.Notification.is_mentions), mentionId)
        .maybeSingle();
  }

  PostgrestTransformBuilder<PostgrestMap?> getNotificationAboutLikes(likeId) {
    return SupabaseConfig.client
        .from(dbReference(not.Notification.table))
        .select()
        .eq(dbReference(not.Notification.is_user_post_like), likeId)
        .maybeSingle();
  }

  PostgrestTransformBuilder<PostgrestMap?> getNotificationAboutComment(
      commentId) {
    return SupabaseConfig.client
        .from(dbReference(not.Notification.table))
        .select()
        .eq(dbReference(not.Notification.is_user_post_comment), commentId)
        .maybeSingle();
  }

  PostgrestTransformBuilder<PostgrestList> getPostLikes(
      String thisUser, String lesserThanTime, int limitBy) {
    return SupabaseConfig.client
        .from(dbReference(Likes.table))
        .select("*, ${dbReference(Post.table)}!inner(*)")
        .eq("${dbReference(Post.table)}.${dbReference(Members.id)}", thisUser)
        .neq(dbReference(dbReference(Members.id)), thisUser)
        .lte(dbReference(Likes.created_at), lesserThanTime)
        .order(dbReference(Likes.created_at), ascending: false)
        .limit(limitBy);
  }

  PostgrestTransformBuilder<PostgrestList> getPostCommentLike(
      String thisUser, String lesserThanTime, int limitBy) {
    return SupabaseConfig.client
        .from(dbReference(Likes.table))
        .select(
            "*, ${dbReference(Comments.table)}!inner(*, ${dbReference(Post.table)}!inner(*))")
        .eq("${dbReference(Comments.table)}.${dbReference(Members.id)}",
            thisUser)
        .neq(dbReference(dbReference(Members.id)), thisUser)
        .lte(dbReference(Likes.created_at), lesserThanTime)
        .order(dbReference(Likes.created_at), ascending: false)
        .limit(limitBy);
  }

  PostgrestTransformBuilder<PostgrestList> getPostComments(
      String thisUser, String lesserThanTime, int limitBy) {
    return SupabaseConfig.client
        .from(dbReference(Comments.table))
        .select("*, ${dbReference(Post.table)}!inner(*)")
        .eq("${dbReference(Post.table)}.${dbReference(Members.id)}", thisUser)
        .neq(dbReference(dbReference(Members.id)), thisUser)
        .lte(dbReference(Comments.created_at), lesserThanTime)
        .order(dbReference(Comments.created_at), ascending: false)
        .limit(limitBy);
  }

  PostgrestTransformBuilder<PostgrestList> getPostMentions(
      String thisUser, String lesserThanTime, int limitBy) {
    return SupabaseConfig.client
        .from(dbReference(Mentions.table))
        .select("*, ${dbReference(Post.table)}!inner(*)")
        .eq(dbReference(Members.id), thisUser)
        .neq(
            "${dbReference(Post.table)}.${dbReference(dbReference(Members.id))}",
            thisUser)
        .lte(dbReference(Mentions.created_at), lesserThanTime)
        .order(dbReference(Mentions.created_at), ascending: false)
        .limit(limitBy);
  }

  PostgrestTransformBuilder<PostgrestList> getOtherPost(
      List<String> connectionIds, String lesserThanTime, int limitBy) {
    return SupabaseConfig.client
        .from(dbReference(Post.table))
        .select()
        .or(SupabaseConfig().filtersIn(dbReference(Members.id), connectionIds))
        .lte(dbReference(Post.created_at), lesserThanTime)
        .order(dbReference(Post.created_at), ascending: false)
        .limit(limitBy);
  }

  Widget getNotificationText(NotificationData notificationData) {
    if (notificationData.postProfileNotifier == null) return SizedBox();

    return WidgetStateConsumer(
        widgetStateNotifier: notificationData.postProfileNotifier!.state,
        widgetStateBuilder: (context, data) {
          TextStyle textStyle = TextStyle(color: Colors.black, fontSize: 13);
          int maxLines = 3;
          TextOverflow overflow = TextOverflow.ellipsis;
          // Check if notificationData has other post information

          if (notificationData.notificationIsOtherPost != null) {
            // Extract post media information
            String postText =
                notificationData.notificationIsOtherPost!.postText;
            int pictures = notificationData.notificationIsOtherPost!.postMedia
                .where(
                    (element) => element.mediaType == HomePageMediaType.image)
                .length;
            int video = notificationData.notificationIsOtherPost!.postMedia
                .where(
                    (element) => element.mediaType == HomePageMediaType.video)
                .length;

            // Generate media text based on the presence of pictures and videos
            String mediaText = ((pictures > 0) ? "$pictures pictures" : '') +
                ((pictures > 0 && video > 0) ? " and " : '') +
                ((video > 0) ? "$video video" : "");

            // Construct notification text based on postText and mediaText
            "${data!.fullName} ";

            return RichText(
                maxLines: maxLines,
                overflow: overflow,
                text: TextSpan(children: [
                  TextSpan(
                      style: textStyle.copyWith(fontWeight: FontWeight.bold),
                      text: "${data!.fullName} "),
                  TextSpan(
                      style: textStyle,
                      text:
                          "posted: ${postText.isNotEmpty ? postText : mediaText}")
                ]));
          } else if (notificationData.notificationIsUserLike != null &&
              notificationData.notificationLikeAndCommentData != null &&
              notificationData.notificationIsUserComment == null) {
            // Extract post media information
            String postText =
                notificationData.notificationLikeAndCommentData!.postText;
            int pictures = notificationData
                .notificationLikeAndCommentData!.postMedia
                .where(
                    (element) => element.mediaType == HomePageMediaType.image)
                .length;
            int video = notificationData
                .notificationLikeAndCommentData!.postMedia
                .where(
                    (element) => element.mediaType == HomePageMediaType.video)
                .length;

            // Generate media text based on the presence of pictures and videos
            String mediaText = ((pictures > 0) ? "$pictures pictures" : '') +
                ((pictures > 0 && video > 0) ? " and " : '') +
                ((video > 0) ? "$video video" : "");

            // Construct notification text based on postText and mediaText
            "${data!.fullName} ";

            return RichText(
                maxLines: maxLines,
                overflow: overflow,
                text: TextSpan(children: [
                  TextSpan(
                      style: textStyle.copyWith(fontWeight: FontWeight.bold),
                      text: "${data.fullName} "),
                  TextSpan(
                      style: textStyle,
                      text:
                          "liked your post: ${postText.isNotEmpty ? postText : mediaText}")
                ]));
          } else if (notificationData.notificationIsUserLike != null &&
              notificationData.notificationLikeAndCommentData != null &&
              notificationData.notificationIsUserComment != null) {
            String commentText =
                notificationData.notificationIsUserComment!.commentText;

            return RichText(
                maxLines: maxLines,
                overflow: overflow,
                text: TextSpan(children: [
                  TextSpan(
                      style: textStyle.copyWith(fontWeight: FontWeight.bold),
                      text: "${data!.fullName} "),
                  TextSpan(
                      style: textStyle,
                      text: "liked your comment: $commentText")
                ]));
          } else if (notificationData.notificationIsUserLike == null &&
              notificationData.notificationLikeAndCommentData != null &&
              notificationData.notificationIsUserComment != null) {
            HomePageCommentData commentData =
                notificationData.notificationIsUserComment!;
            String commentText = commentData.commentText;

            return RichText(
                maxLines: maxLines,
                overflow: overflow,
                text: TextSpan(children: [
                  TextSpan(
                      style: textStyle.copyWith(fontWeight: FontWeight.bold),
                      text: "${data!.fullName} "),
                  TextSpan(
                      style: textStyle,
                      text: "commented on your post: $commentText")
                ]));
          } else if (notificationData.notificationLikeAndCommentData != null &&
              notificationData.notificationIsMentions != null) {
            // Extract post media information
            String postText =
                notificationData.notificationLikeAndCommentData!.postText;
            int pictures = notificationData
                .notificationLikeAndCommentData!.postMedia
                .where(
                    (element) => element.mediaType == HomePageMediaType.image)
                .length;
            int video = notificationData
                .notificationLikeAndCommentData!.postMedia
                .where(
                    (element) => element.mediaType == HomePageMediaType.video)
                .length;

            // Generate media text based on the presence of pictures and videos
            String mediaText = ((pictures > 0) ? "$pictures pictures" : '') +
                ((pictures > 0 && video > 0) ? " and " : '') +
                ((video > 0) ? "$video video" : "");

            // Construct notification text based on postText and mediaText
            "${data!.fullName} ";

            return RichText(
                maxLines: maxLines,
                overflow: overflow,
                text: TextSpan(children: [
                  TextSpan(
                      style: textStyle.copyWith(fontWeight: FontWeight.bold),
                      text: "${data!.fullName} "),
                  TextSpan(
                      style: textStyle,
                      text: "mentions you on the post: $postText")
                ]));
          }

          // Return default testing notification if other post information is not available
          return Text(
            "Error Loading notification",
            overflow: overflow,
            style: textStyle,
            maxLines: maxLines,
          );
        });
  }

  DateTime getNotificationTime(NotificationData notification) {
    if (notification.notificationCreatedAt != null) {
      return DateTime.parse(notification.notificationCreatedAt!);
    }
    return DateTime.now();
  }

  String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 14) {
      return '1w';
    } else if (difference.inDays < 365) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y';
    }
  }

  void sendNotificationLikedChecked(String likeId, String runTimeId) {
    String? thisUser = SupabaseConfig.client.auth.currentUser?.id;
    if (thisUser != null) {
      SupabaseConfig.client
          .from(dbReference(not.Notification.table))
          .select()
          .match({
            dbReference(not.Notification.is_user_post_like): likeId,
            dbReference(Members.id): thisUser,
          })
          .maybeSingle()
          .then((check) {
            if (check == null) {
              SupabaseConfig.client
                  .from(dbReference(not.Notification.table))
                  .insert({
                    dbReference(not.Notification.is_user_post_like): likeId,
                    dbReference(Members.id): thisUser,
                  })
                  .select()
                  .maybeSingle()
                  .then((value) {
                    if (value != null) {
                      String notificationId =
                          value[dbReference(not.Notification.id)];
                      handleNotificationChecked(notificationId, runTimeId);
                    }
                  });
            }
          });
    }
  }

  void sendNotificationCommentChecked(String commentId, String runTimeId) {
    String? thisUser = SupabaseConfig.client.auth.currentUser?.id;
    if (thisUser != null) {
      SupabaseConfig.client
          .from(dbReference(not.Notification.table))
          .select()
          .match({
            dbReference(not.Notification.is_user_post_comment): commentId,
            dbReference(Members.id): thisUser,
          })
          .maybeSingle()
          .then((check) {
            if (check == null) {
              SupabaseConfig.client
                  .from(dbReference(not.Notification.table))
                  .insert({
                    dbReference(not.Notification.is_user_post_comment):
                        commentId,
                    dbReference(Members.id): thisUser,
                  })
                  .select()
                  .maybeSingle()
                  .then((value) {
                    if (value != null) {
                      String notificationId =
                          value[dbReference(not.Notification.id)];
                      handleNotificationChecked(notificationId, runTimeId);
                    }
                  });
            }
          });
    }
  }

  void sendNotificationMentionChecked(String mentionId, String runTimeId) {
    String? thisUser = SupabaseConfig.client.auth.currentUser?.id;
    if (thisUser != null) {
      SupabaseConfig.client
          .from(dbReference(not.Notification.table))
          .select()
          .match({
            dbReference(not.Notification.is_mentions): mentionId,
            dbReference(Members.id): thisUser,
          })
          .maybeSingle()
          .then((check) {
            if (check == null) {
              SupabaseConfig.client
                  .from(dbReference(not.Notification.table))
                  .insert({
                    dbReference(not.Notification.is_mentions): mentionId,
                    dbReference(Members.id): thisUser,
                  })
                  .select()
                  .maybeSingle()
                  .then((value) {
                    if (value != null) {
                      String notificationId =
                          value[dbReference(not.Notification.id)];
                      handleNotificationChecked(notificationId, runTimeId);
                    }
                  });
            }
          });
    }
  }

  String getNotificationRunTimeId() => Uuid().v4();

  void handleNotificationChecked(String notificationId, String runTimeId) {
    NotificationNotifier().updateThisNotificationId(runTimeId, notificationId);
  }

  Future<bool> changeNotificationStatus(
      AuthorizationStatus authorizationStatus) {
    return CacheOperation().saveCacheData(
        dbReference(not.Notification.database),
        dbReference(not.Notification.status),
        dbReference(authorizationStatus));
  }
}
