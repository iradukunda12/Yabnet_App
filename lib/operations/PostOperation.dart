import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:yabnet/data/HomePagePostData.dart';
import 'package:yabnet/db_references/Likes.dart';
import 'package:yabnet/db_references/Members.dart';
import 'package:yabnet/operations/CacheOperation.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../components/CustomProject.dart';
import '../db_references/Connect.dart';
import '../db_references/Mentions.dart';
import '../db_references/Post.dart';
import '../generator/PostFeedsGenerator.dart';

class PostOperation {
  Future<List<HomePagePostData>> getGeneralLocalData() async {
    final posts = await CacheOperation().getCacheData(
        dbReference(Post.general_database), dbReference(Post.general_data));

    if (posts != null && posts is Map) {
      return posts.values.map((e) => HomePagePostData.fromJson(e)).toList();
    }

    return [];
  }

  Future<bool> saveGeneralLocalPost(List<HomePagePostData> allPost) async {
    Map mapData = Map.fromIterable(allPost,
        key: (element) => element.postId, value: (element) => element.toJson());

    return CacheOperation().saveCacheData(dbReference(Post.general_database),
        dbReference(Post.general_data), mapData);
  }

  Future<ValueListenable<Box>?> userListenable() async {
    return await CacheOperation()
        .getListenable(dbReference(Post.user_database));
  }

  Future<ValueListenable<Box>?> generalListenable() async {
    return await CacheOperation()
        .getListenable(dbReference(Post.general_database));
  }

  Future<List<HomePagePostData>> getUserLocalData() async {
    final posts = await CacheOperation().getCacheData(
        dbReference(Post.user_database), dbReference(Post.user_data));

    if (posts != null && posts is Map) {
      return posts.values.map((e) => HomePagePostData.fromJson(e)).toList();
    }

    return [];
  }

  Future<bool> saveUserLocalData(List<HomePagePostData> allPost) async {
    Map mapData = Map.fromIterable(allPost,
        key: (element) => element.postId, value: (element) => element.toJson());
    return await CacheOperation().saveCacheData(
        dbReference(Post.user_database), dbReference(Post.user_data), mapData);
  }

  PostgrestTransformBuilder<PostgrestMap?> updatePostVerification(
      String postId, bool postVerified) {
    return SupabaseConfig.client
        .from(dbReference(Post.table))
        .update({
          dbReference(dbReference(Post.verified)): postVerified,
        })
        .eq(dbReference(dbReference(Post.id)), postId)
        .select()
        .maybeSingle();
  }

  PostgrestFilterBuilder<PostgrestList> getPostLikes(String postId) {
    return SupabaseConfig.client
        .from(dbReference(Likes.table))
        .select()
        .eq(dbReference(Likes.is_post), postId);
  }

  String getUUID() {
    return Uuid().v4();
  }

  PostgrestFilterBuilder<PostgrestList> getPostReposts(String postId) {
    return SupabaseConfig.client
        .from(dbReference(Post.table))
        .select()
        .eq(dbReference(Post.reposted), postId);
  }

  PostgrestFilterBuilder<PostgrestList> getThisMemberConnects(String memberId) {
    return SupabaseConfig.client
        .from(dbReference(Connect.table))
        .select()
        .eq(dbReference(Connect.to), memberId);
  }

  String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} sec${difference.inSeconds == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 14) {
      return '1 week ago';
    } else if (difference.inDays < 365) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }

  String formatNumber(int number) {
    if (number >= 1000000000) {
      final doubleResult = number / 1000000000;
      return '${doubleResult.toStringAsFixed(doubleResult.truncateToDouble() == doubleResult ? 0 : 1)}B';
    } else if (number >= 1000000) {
      final doubleResult = number / 1000000;
      return '${doubleResult.toStringAsFixed(doubleResult.truncateToDouble() == doubleResult ? 0 : 1)}M';
    } else if (number >= 1000) {
      final doubleResult = number / 1000;
      return '${doubleResult.toStringAsFixed(doubleResult.truncateToDouble() == doubleResult ? 0 : 1)}K';
    } else {
      return number.toString();
    }
  }

  Future<bool> userConnectedToMember(String userId, String memberId) {
    return SupabaseConfig.client
        .from(dbReference(Connect.table))
        .select()
        .match({
          dbReference(Members.id): userId,
          dbReference(Connect.to): memberId,
        })
        .maybeSingle()
        .then((value) => value?[dbReference(Connect.to)].toString() == memberId
            ? true
            : false)
        .onError((error, stackTrace) => false);
  }

  Future<bool> getUserReposted(String postId, String userId) {
    return SupabaseConfig.client
        .from(dbReference(Post.table))
        .select()
        .match({
          dbReference(Members.id): userId,
          dbReference(Post.reposted): postId,
        })
        .maybeSingle()
        .then((value) =>
            value?[dbReference(Members.id)].toString() == userId ? true : false)
        .onError((error, stackTrace) => false);
  }

  PostgrestFilterBuilder addLike(String postId, String userId) {
    return SupabaseConfig.client.from(dbReference(Likes.table)).insert({
      dbReference(Likes.is_post): postId,
      dbReference(Members.id): userId,
    });
  }

  PostgrestFilterBuilder removeLike(String postId, String userId) {
    return SupabaseConfig.client.from(dbReference(Likes.table)).delete().match({
      dbReference(Likes.is_post): postId,
      dbReference(Members.id): userId,
    });
  }

  PostgrestTransformBuilder<PostgrestMap?> sendANewPost(String postText,
      String membersId, int hasMedia, int postHasMentions, bool postVerified,
      {String? postReposted}) {
    return SupabaseConfig.client
        .from(dbReference(Post.table))
        .insert({
          dbReference(dbReference(Post.text)): postText,
          dbReference(dbReference(Post.media)): hasMedia,
          dbReference(dbReference(Post.has_mentions)): postHasMentions,
          dbReference(dbReference(Post.verified)): postVerified,
          dbReference(dbReference(Members.id)): membersId,
        })
        .select()
        .maybeSingle();
  }

  PostgrestTransformBuilder<PostgrestMap?> repostPost(
    String? postReposted,
    String membersId,
    bool postVerified,
  ) {
    return SupabaseConfig.client
        .from(dbReference(Post.table))
        .insert({
          dbReference(dbReference(Post.reposted)): postReposted,
          dbReference(dbReference(Post.verified)): postVerified,
          dbReference(dbReference(Members.id)): membersId,
        })
        .select()
        .maybeSingle();
  }

  PostgrestFilterBuilder removeRepostedPost(
    String? postId,
    String membersId,
  ) {
    return SupabaseConfig.client.from(dbReference(Post.table)).delete().match({
      dbReference(dbReference(Post.reposted)): postId,
      dbReference(dbReference(Members.id)): membersId,
    });
  }

  String getExtension(String path, String mediaType) {
    final mediaExtension = path.split(".").last.toLowerCase();
    return "${mediaType}/$mediaExtension";
  }

  String getPostBucketPath(String postId, String name) {
    final mediaPath = "/${postId}/$name";
    return SupabaseConfig.client.storage
        .from(dbReference(Post.bucket))
        .getPublicUrl(mediaPath);
  }

  String getPostMediaPath(String postId, String type, int index) {
    return "/${postId}/${type.split("/")[0]}_$index";
  }

  Future<String> uploadPostMedia(
      String postId, int index, Uint8List mediaByte, String mediaType) {
    final mediaPath = getPostMediaPath(postId, mediaType, index);
    return SupabaseConfig.client.storage
        .from(dbReference(Post.bucket))
        .uploadBinary(mediaPath, mediaByte,
            fileOptions: FileOptions(upsert: true, contentType: mediaType));
  }

  PostgrestTransformBuilder<PostgrestMap?> uploadPostMentions(
      String postId, String memberId) {
    return SupabaseConfig.client
        .from(dbReference(Mentions.table))
        .insert(
            {dbReference(Members.id): memberId, dbReference(Post.id): postId})
        .select()
        .maybeSingle();
  }

  String getPostTempDirectory(String folderName) {
    return Directory.systemTemp.path + "/" + "post/" + folderName;
  }

  Future<List<FileObject>> getMediaFiles(String postId) {
    return SupabaseConfig.client.storage
        .from(dbReference(Post.bucket))
        .list(path: postId);
  }

  PostgrestFilterBuilder<PostgrestList> getPostMention(String postId) {
    return SupabaseConfig.client
        .from(dbReference(Mentions.table))
        .select("*,${dbReference(Members.table)}(*)")
        .eq(dbReference(Post.id), postId);
  }

  Future<List<Uint8List>> createTempFolder(
      List<Uint8List> files, String folderName) async {
    final Directory tempDir = await Directory(getPostTempDirectory(folderName))
        .create(recursive: true);
    final String tempFolderPath = tempDir.path;

    for (int i = 0; i < files.length; i++) {
      final Uint8List fileBytes = files[i];
      final File tempFile = File('$tempFolderPath/file_$i');
      await tempFile.writeAsBytes(fileBytes);
    }

    return await fetchFiles(folderName);
  }

  Future<List<Uint8List>> fetchFiles(String folderName) async {
    final Directory tempDir = Directory(getPostTempDirectory(folderName));
    final List<Uint8List> files = [];

    if (await tempDir.exists()) {
      await for (FileSystemEntity entity in tempDir.list()) {
        if (entity is File) {
          List<int> bytes = await entity.readAsBytes();
          files.add(Uint8List.fromList(bytes));
        }
      }
    } else {
      showDebug(msg: "Directory does not exits");
    }

    return files;
  }

  Future<void> deleteFolder(String folderName) async {
    final Directory tempDir = Directory(getPostTempDirectory(folderName));
    if (await tempDir.exists() == false) {
      return;
    }
    await tempDir.delete(recursive: true);
  }

  void scheduleFolderDeletion(String postId) {}

  Future<List<PostgrestMap?>?> getOnlinePostList(String? postId) {
    if (postId == null) return Future.value(null);
    return SupabaseConfig.client
        .from(dbReference(Post.table))
        .select()
        .eq(dbReference(Post.id), postId)
        .maybeSingle()
        .then((value) => [value])
        .onError((error, stackTrace) => []);
  }

  Future<PostgrestMap?> getOnlinePostReposted(String postId) {
    return SupabaseConfig.client
        .from(dbReference(Post.table))
        .select()
        .eq(dbReference(Post.id), postId)
        .maybeSingle();
  }

  // Mentions Links
  Future<List> getPostMentionsLinks(String membersId, {int limitBy = 50}) {
    return SupabaseConfig.client
        .from(dbReference(Mentions.table))
        .select("*,${dbReference(Post.table)}(*)")
        .eq("${dbReference(Post.table)}.${dbReference(Members.id)}", membersId)
        .limit(limitBy)
        .then((value) => value.map((e) => e[dbReference(Members.id)]).toList());
  }

  // Connect Links
  PostgrestTransformBuilder<PostgrestList> getPostConnectsLinks(
      String membersId,
      {int limitBy = 200}) {
    return SupabaseConfig.client
        .from(dbReference(Connect.table))
        .select(dbReference(Members.id))
        .eq(dbReference(Connect.to), membersId)
        .limit(limitBy);
  }

  // ConnectionLinks
  PostgrestTransformBuilder<PostgrestList> getPostConnectionsLinks(
      String membersId,
      {int limitBy = 200}) {
    return SupabaseConfig.client
        .from(dbReference(Connect.table))
        .select(dbReference(Connect.to))
        .eq(dbReference(Members.id), membersId)
        .limit(limitBy);
  }

  // ConnectionLinks
  Future<PostgrestTransformBuilder<PostgrestList>> getLikesLinks(
      String membersId,
      {int limitBy = 200}) async {
    final postIds = await getThisUserPostId(membersId);

    return SupabaseConfig.client
        .from(dbReference(Likes.table))
        .select(dbReference(Members.id))
        .or(SupabaseConfig().filtersIn(dbReference(Likes.is_post), postIds))
        .limit(limitBy);
  }

  Future<List> getThisUserPostId(String membersId) {
    return SupabaseConfig.client
        .from(dbReference(Post.table))
        .select(dbReference(Post.id))
        .eq(dbReference(Members.id), membersId)
        .then((value) => value.map((e) => e.values.single).toList());
  }

  Future<List> getLinkedMemberId(String membersId) async {
    final thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    final mentionLink = await getPostMentionsLinks(membersId)
        .then((value) => value.map((e) => e).toList());
    final connectLink = await getPostConnectsLinks(membersId)
        .then((value) => value.map((e) => e.values.single).toList());
    final connectionLink = await getPostConnectionsLinks(membersId)
        .then((value) => value.map((e) => e.values.single).toList());
    final likesLink = (await getLikesLinks(membersId).then((result) =>
        result.then((value) => value.map((e) => e.values.single).toList())));

    List allLinkedMembers = [
      thisUser,
      ...(mentionLink),
      ...(connectLink),
      ...(connectionLink),
      ...(likesLink)
    ];
    return allLinkedMembers;
  }

  Future<PostgrestTransformBuilder<PostgrestList>> getPersonalizedPosts(
      String membersId,
      List<FeedField> personalFeed,
      String greaterThanTime,
      String? lessThanTime,
      int retry,
      {int? limitBy}) async {
    final membersIds = await getLinkedMemberId(membersId);

    final search = SupabaseConfig.client.from(dbReference(Post.table)).select();

    final check = (retry > 0)
        ? search
            .or(SupabaseConfig().filtersIn(dbReference(Members.id), membersIds))
            .gte(dbReference(Post.created_at), greaterThanTime)
        : search;

    final filter = (lessThanTime != null)
        ? check.lte(dbReference(Post.created_at), lessThanTime)
        : check;

    if (limitBy != null) {
      return filter.limit(limitBy);
    } else {
      return filter;
    }
  }

  PostgrestTransformBuilder<PostgrestList> getMembersPostsTime(
      String membersId, String lesserThanTime, bool fromStart,
      {int? limitBy}) {
    final filter = SupabaseConfig.client
        .from(dbReference(Post.table))
        .select()
        .eq(dbReference(Members.id), membersId);

    final search = fromStart == false
        ? filter
            .lte(dbReference(Post.created_at), lesserThanTime)
            .order(dbReference(Post.created_at), ascending: false)
        : filter;

    if (limitBy != null) {
      return search.limit(limitBy);
    } else {
      return search;
    }
  }

  Future<PostgrestTransformBuilder<PostgrestList>> getSuggestedPosts(
      String membersId, String greaterThanTime, String? lessThanTime, int retry,
      {int? limitBy}) async {
    final membersIds = await getLinkedMemberId(membersId);

    final search = SupabaseConfig.client.from(dbReference(Post.table)).select();

    final check = (retry > 0)
        ? search
            .not(dbReference(Members.id), "in", membersIds)
            .gte(dbReference(Post.created_at), greaterThanTime)
        : search;

    final filter = (lessThanTime != null)
        ? check.lte(dbReference(Post.created_at), lessThanTime)
        : check;

    if (limitBy != null) {
      return filter.limit(limitBy);
    } else {
      return filter;
    }
  }

  Stream<List<Map<String, dynamic>>> getAllPostsStream(
      {SupabaseStreamPaginationOption? fetchOptions}) {
    final stream = SupabaseConfig.client
        .from(dbReference(Post.table))
        .stream(primaryKey: [dbReference(Post.id)]).order(
            dbReference(Post.created_at),
            ascending: true);

    if (fetchOptions != null) {
      stream.limit(fetchOptions.supabaseStreamPaginationController.fetchBy);
    }
    return stream;
  }

  String foreignKey(
    String secondTable,
    String thisTable,
    String secondTableId,
  ) {
    return "$secondTable!${thisTable}_${secondTableId}_fkey";
  }

  PostgrestTransformBuilder<PostgrestList> getPostDataForFirstNameSearch(
      String likeText, int limitBy) {
    return SupabaseConfig.client
        .from(dbReference(Post.table))
        .select(
            "*, ${foreignKey(dbReference(Members.table), dbReference(Post.table), dbReference(Members.id))}()")
        // .contains("${dbReference(Members.table)}.${dbReference(Members.firstname)}", "%$likeText%")
        // .or("${dbReference(Members.table)}.${dbReference(Members.firstname)}.ilike.${"%$likeText%"},${dbReference(Members.table)}.${dbReference(Members.lastname)}.ilike.${"%$likeText%"}")
        .ilike(
            "${dbReference(Members.table)}.${dbReference(Members.firstname)}",
            "%$likeText%")
        .limit(limitBy);
  }

  PostgrestTransformBuilder<PostgrestList> getPostDataForLastNameSearch(
      String likeText, int limitBy) {
    return SupabaseConfig.client
        .from(dbReference(Post.table))
        .select(
            "*, ${foreignKey(dbReference(Members.table), dbReference(Post.table), dbReference(Members.id))}()")
        // .contains("${dbReference(Members.table)}.${dbReference(Members.firstname)}", "%$likeText%")
        // .or("${dbReference(Members.table)}.${dbReference(Members.firstname)}.ilike.${"%$likeText%"},${dbReference(Members.table)}.${dbReference(Members.lastname)}.ilike.${"%$likeText%"}")
        .ilike(
            "${dbReference(Members.table)}.${dbReference(Members.firstname)}",
            "%$likeText%")
        .limit(limitBy);
  }

  Stream<List<Map<String, dynamic>>> getAllUserPosts(String userId,
      {SupabaseStreamPaginationOption? fetchOptions}) {
    final stream = SupabaseConfig.client
        .from(dbReference(Post.table))
        .stream(primaryKey: [dbReference(Post.id)])
        .eq(dbReference(Members.id), userId)
        .order(dbReference(Post.created_at), ascending: true);

    if (fetchOptions != null) {
      stream.limit(fetchOptions.supabaseStreamPaginationController.fetchBy);
    }
    return stream;
  }

  HomePageMediaData getParsedData(String postId, FileObject mediaFile) {
    String name = mediaFile.name;
    HomePageMediaType mediaType = name.contains("image")
        ? HomePageMediaType.image
        : HomePageMediaType.video;
    String mediaPath = PostOperation().getPostBucketPath(postId, name);
    return HomePageMediaData(mediaType, mediaPath);
  }
}
