import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yabnet/db_references/Comments.dart';

import '../components/CustomProject.dart';
import '../db_references/Likes.dart';
import '../db_references/Members.dart';
import '../db_references/Post.dart';
import '../local_database.dart';
import '../supabase/SupabaseConfig.dart';
import 'CacheOperation.dart';

class CommentOperation {
  Future<ValueListenable<Box>?> listenable() async {
    return await CacheOperation().getListenable(dbReference(Comments.database));
  }

  PostgrestFilterBuilder<PostgrestList> getCommentLikes(String commentId) {
    return SupabaseConfig.client
        .from(dbReference(Likes.table))
        .select()
        .eq(dbReference(Likes.is_comment), commentId);
  }

  String foreignKey(String secondTable, String thisTable, String secondTableId,
      {String schema = "public_"}) {
    return "${secondTable}!${schema}${thisTable}_${secondTableId}_fkey";
  }

  String joinOn(String secondTable, String thisTableId, String fields) {
    return "${secondTable}:${thisTableId}($fields)";
  }

  // comments_table!public_comments_table_comments_to_fkey

  // Unhandled Exception: PostgrestException(message: Could not embed because more than
  // one relationship was found for 'comments_table' and 'comments_table',
  // code: PGRST201, details: [{cardinality: one-to-many, embedding: comments_table with
  // comments_table, relationship: public_comments_table_comments_parent_fkey
  // using comments_table(comments_id) and comments_table(comments_parent)},
  // {cardinality: one-to-many, embedding: comments_table with comments_table,
  // relationship: public_comments_table_comments_to_fkey using comments_table(comments_id)
  // and comments_table(comments_to)}], hint: Try changing 'comments_table' to one of the
  // following: 'comments_table!public_comments_table_comments_parent_fkey',
  // 'comments_table!public_comments_table_comments_to_fkey'. Find the desired relationship in the 'details' key.)

  PostgrestTransformBuilder<PostgrestList> getPostComments(
      String postId, String greaterThanTime, bool fromStart, int retry,
      {int? limitBy}) {
    final filter = SupabaseConfig.client
        .from(dbReference(Comments.table))
        .select("*")
        .eq(dbReference(Post.id), postId);

    final search = fromStart == false
        ? filter.gte(dbReference(Comments.created_at), greaterThanTime)
        : filter;

    if (limitBy != null) {
      return search.limit(limitBy);
    } else {
      return search;
    }
  }

  PostgrestTransformBuilder<PostgrestMap?> getPostCommentsTo(
      String commentsId) {
    return SupabaseConfig.client
        .from(dbReference(Comments.table))
        .select("*")
        .eq(dbReference(Comments.id), commentsId)
        .maybeSingle();
  }

  Stream<List<Map<String, dynamic>>> getAllComments(String postId,
      {SupabaseStreamPaginationOption? fetchOptions}) {
    final stream = SupabaseConfig.client
        .from(dbReference(Comments.table))
        .stream(primaryKey: [dbReference(Comments.id)])
        .eq(dbReference(Post.id), postId)
        .order(dbReference(Comments.created_at), ascending: true);

    if (fetchOptions != null) {
      stream.limit(fetchOptions.supabaseStreamPaginationController.fetchBy);
    }
    return stream;
  }

  PostgrestFilterBuilder<PostgrestList> getCommentTo(String commentId) {
    return SupabaseConfig.client
        .from(dbReference(Comments.table))
        .select()
        .eq(dbReference(Comments.parent), commentId);
  }

  Future<PostgrestMap?> getCommentToIdentity(String? commentId) {
    if (commentId == null) return Future.value(null);
    return SupabaseConfig.client
        .from(dbReference(Comments.table))
        .select('*,${dbReference(Members.table)}(*)')
        .eq(dbReference(Comments.id), commentId)
        .maybeSingle();
  }

  List<dynamic> getLocalComments() {
    Box commentBox = LocalDatabase().getBox(dbReference(Comments.database));
    final allPosts =
        commentBox.keys.toList().map((id) => commentBox.get(id)).toList();
    return allPosts;
  }

  PostgrestTransformBuilder<PostgrestMap?> sendANewComment(
      String commentText, String membersId, String postId,
      {String? commentTo, String? commentParent}) {
    return SupabaseConfig.client
        .from(dbReference(Comments.table))
        .insert({
          dbReference(dbReference(Comments.text)): commentText,
          dbReference(dbReference(Members.id)): membersId,
          dbReference(dbReference(Post.id)): postId,
          dbReference(dbReference(Comments.to)): commentTo,
          dbReference(dbReference(Comments.parent)): commentParent,
        })
        .select()
        .maybeSingle();
  }

  PostgrestTransformBuilder<PostgrestMap?> addLike(
      String commentId, String userId) {
    return SupabaseConfig.client
        .from(dbReference(Likes.table))
        .insert({
          dbReference(Likes.is_comment): commentId,
          dbReference(Members.id): userId,
        })
        .select()
        .maybeSingle();
  }

  PostgrestFilterBuilder removeLike(String commentId, String userId) {
    return SupabaseConfig.client.from(dbReference(Likes.table)).delete().match({
      dbReference(Likes.is_comment): commentId,
      dbReference(Members.id): userId,
    });
  }

  PostgrestFilterBuilder deleteComment(String commentId) {
    return SupabaseConfig.client
        .from(dbReference(Comments.table))
        .delete()
        .eq(dbReference(Comments.id), commentId);
  }

  String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} sec${difference.inSeconds == 1 ? '' : 's'}';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min${difference.inMinutes == 1 ? '' : 's'}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inDays < 14) {
      return '1 week';
    } else if (difference.inDays < 365) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'}';
    }
  }
}
