// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/data/HomePagePostData.dart';
import 'package:yabnet/data_notifiers/CommentsNotifier.dart';
import 'package:yabnet/data_notifiers/LikesNotifier.dart';
import 'package:yabnet/data_notifiers/PostNotifier.dart';
import 'package:yabnet/data_notifiers/RepostsNotifier.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/operations/PostOperation.dart';

import '../components/CustomProject.dart';
import '../data/ConnectInfo.dart';
import '../data/HomePageCommentData.dart';
import '../data/NotifierDataClass.dart';
import '../db_references/Comments.dart';
import '../db_references/Likes.dart';
import '../db_references/Members.dart';
import '../db_references/NotifierType.dart';
import '../db_references/Post.dart';
import '../db_references/Profile.dart';
import '../operations/CacheOperation.dart';
import 'ConnectsNotifier.dart';
import 'PostProfileNotifier.dart';

class MemberPostNotifier implements PostNotifier {
  MemberPostNotifier(String membersIds) {
    _membersIds = membersIds;
  }

  WidgetStateNotifier<List<HomePagePostData>> state = WidgetStateNotifier();

  List<HomePagePostData> _data = [];

  PostImplement? _userPostImplement;
  NotifierDataClass<CommentsNotifier?, NotifierType> _commentNotifiers =
      NotifierDataClass();
  NotifierDataClass<LikesNotifier?, NotifierType> _likesNotifiers =
      NotifierDataClass();
  NotifierDataClass<RepostsNotifier?, NotifierType> _repostsNotifiers =
      NotifierDataClass();
  NotifierDataClass<ConnectsNotifier?, NotifierType> _connectsNotifiers =
      NotifierDataClass();
  NotifierDataClass<PostProfileNotifier?, NotifierType>
      _postProfileImageNotifiers = NotifierDataClass();

  bool started = false;
  bool _fromStart = false;
  String userPostFromTime = DateTime.now().toUtc().toString();
  String? _membersIds;

  String fromWhere = dbReference(Members.database);

  Future<void> start(
    PostImplement postImplement,
    PostSessionIdentifier postStack,
  ) async {
    BuildContext? buildContext = postImplement.getLatestContext();
    if (buildContext != null) {
      started = true;
      _attachListeners(postImplement);
      _fetchPostOnline();
    }
  }

  Future<void> getLatestPostReceived(String? time) async {
    if (time != null) {
      userPostFromTime = time;
    }
  }

  List<HomePagePostData> getLatestData() {
    return _data;
  }

  void _retryListener() {
    restart();
  }

  void _attachListeners(PostImplement userPostImplement) {
    _userPostImplement
        ?.getRetryStreamListener()
        ?.removeListener(_retryListener);
    _userPostImplement = userPostImplement;
    userPostImplement.getRetryStreamListener()?.addListener(_retryListener);
  }

  void restart() {
    if (started) {
      _fetchPostOnline();
    }
  }

  void stop(PostSessionIdentifier userPostStack) {
    if (userPostStack.getIdentity() != null) {
      _userPostImplement
          ?.getRetryStreamListener()
          ?.removeListener(_retryListener);
      _userPostImplement = null;
    }
  }

  PostImplement? getPostImplement() {
    return _userPostImplement;
  }

  Future<CommentsNotifier?> createACommentNotifier(
      String postId, NotifierType notifierType) async {
    if (!_commentNotifiers.containIdentity(postId, notifierType)) {
      CommentsNotifier commentsNotifier = CommentsNotifier()
          .attachPostId(postId, fromWhere, startFetching: true);
      _commentNotifiers.addReplacementData(
          postId, notifierType, commentsNotifier);
      return _commentNotifiers.getData(postId, forWhich: notifierType);
    } else {
      CommentsNotifier? commentsNotifier =
          _commentNotifiers.getData(postId, forWhich: notifierType);
      return commentsNotifier;
    }
  }

  Future<LikesNotifier?> createALikeNotifier(
      String postId, NotifierType notifierType) async {
    if (!_likesNotifiers.containIdentity(postId, notifierType)) {
      LikesNotifier likesNotifiers =
          LikesNotifier().attachPostId(postId, fromWhere, startFetching: true);
      _likesNotifiers.addReplacementData(postId, notifierType, likesNotifiers);
      return _likesNotifiers.getData(postId, forWhich: notifierType);
    } else {
      LikesNotifier? likesNotifiers =
          _likesNotifiers.getData(postId, forWhich: notifierType);
      return likesNotifiers;
    }
  }

  Future<RepostsNotifier?> createARepostsNotifier(
      String postId, NotifierType notifierType) async {
    if (!_repostsNotifiers.containIdentity(postId, notifierType)) {
      RepostsNotifier repostsNotifiers = RepostsNotifier()
          .attachPostId(postId, fromWhere, startFetching: true);
      _repostsNotifiers.addReplacementData(
          postId, notifierType, repostsNotifiers);
      return _repostsNotifiers.getData(postId, forWhich: notifierType);
    } else {
      RepostsNotifier? repostsNotifiers =
          _repostsNotifiers.getData(postId, forWhich: notifierType);
      return repostsNotifiers;
    }
  }

  Future<ConnectsNotifier?> createAConnectsNotifier(
      String userId, NotifierType notifierType) async {
    if (!_connectsNotifiers.containIdentity(userId, notifierType)) {
      ConnectsNotifier connectsNotifiers = ConnectsNotifier()
          .attachMembersId(userId, fromWhere, startFetching: true);
      _connectsNotifiers.addReplacementData(
          userId, notifierType, connectsNotifiers);
      return _connectsNotifiers.getData(userId, forWhich: notifierType);
    } else {
      ConnectsNotifier? connectsNotifiers =
          _connectsNotifiers.getData(userId, forWhich: notifierType);
      return connectsNotifiers;
    }
  }

  Future<PostProfileNotifier?> createAPostProfileNotifier(
      String userId, NotifierType notifierType) async {
    if (!_postProfileImageNotifiers.containIdentity(userId, notifierType)) {
      PostProfileNotifier postProfileNotifier = PostProfileNotifier()
          .attachMembersId(userId, fromWhere, startFetching: true);
      _postProfileImageNotifiers.addReplacementData(
          userId, notifierType, postProfileNotifier);
      return _postProfileImageNotifiers.getData(userId, forWhich: notifierType);
    } else {
      PostProfileNotifier? postProfileNotifier =
          _postProfileImageNotifiers.getData(userId, forWhich: notifierType);
      return postProfileNotifier;
    }
  }

  CommentsNotifier? getCommentNotifier(
      String postId, NotifierType notifierType) {
    return _commentNotifiers.getData(postId, forWhich: notifierType);
  }

  LikesNotifier? getLikeNotifier(String postId, NotifierType notifierType) {
    return _likesNotifiers.getData(postId, forWhich: notifierType);
  }

  RepostsNotifier? getRepostsNotifier(
      String postId, NotifierType notifierType) {
    return _repostsNotifiers.getData(postId, forWhich: notifierType);
  }

  ConnectsNotifier? getConnectsNotifier(
      String userId, NotifierType notifierType) {
    return _connectsNotifiers.getData(userId, forWhich: notifierType);
  }

  PostProfileNotifier? getPostProfileNotifier(
      String userId, NotifierType notifierType) {
    return _postProfileImageNotifiers.getData(userId, forWhich: notifierType);
  }

  void adjustLatestNotifiersByPostId() async {
    List<String> allPostId = _data.map((e) => e.postId).toList();
    _commentNotifiers.removeWhere((key, value) => !allPostId.contains(key));
    _likesNotifiers.removeWhere((key, value) => !allPostId.contains(key));
    _repostsNotifiers.removeWhere((key, value) => !allPostId.contains(key));

    // Cache Comments & Likes
    CacheOperation()
        .getCacheKeys(dbReference(Comments.database))
        .then((cacheIds) {
      cacheIds.forEach((postId) async {
        if (!allPostId.contains(postId)) {
          final postComments = await CacheOperation()
              .getCacheData(dbReference(Comments.database), postId);

          if (postComments != null) {
            List<HomePageCommentData> commentData = postComments.values
                .map((value) => HomePageCommentData.fromJson(value))
                .toList();
            commentData.forEach((comment) {
              CacheOperation().deleteCacheData(
                  dbReference(Likes.comment_database), comment.commentId);
            });
          }

          CacheOperation()
              .deleteCacheData(dbReference(Comments.database), postId);
        }
      });
    });

    // Cache Post Likes
    CacheOperation()
        .getCacheKeys(dbReference(Likes.post_database))
        .then((cacheIds) {
      cacheIds.forEach((postId) async {
        if (!allPostId.contains(postId)) {
          CacheOperation()
              .deleteCacheData(dbReference(Likes.post_database), postId);
        }
      });
    });

    // Cache Post Repost
    CacheOperation()
        .getCacheKeys(dbReference(Post.repost_database))
        .then((cacheIds) {
      cacheIds.forEach((postId) async {
        if (!allPostId.contains(postId)) {
          CacheOperation()
              .deleteCacheData(dbReference(Post.repost_database), postId);
        }
      });
    });
  }

  void adjustLatestNotifiersByUserId() async {
    List<String> allPostBy = getLatestData().map((e) => e.postBy).toList();
    _connectsNotifiers.removeWhere((key, value) => !allPostBy.contains(key));

    _postProfileImageNotifiers.removeWhere((identity, notifierType) {
      bool remove =
          !allPostBy.contains(identity) && notifierType == NotifierType.normal;

      if (remove) {
        _postProfileImageNotifiers
            .getData(identity, forWhich: NotifierType.normal)
            ?.endSubscription();
      }
      return remove;
    });

    // Cache Connect
    CacheOperation()
        .getCacheKeys(dbReference(Post.repost_database))
        .then((cacheIds) {
      cacheIds.forEach((userId) async {
        if (!allPostBy.contains(userId)) {
          CacheOperation()
              .deleteCacheData(dbReference(Post.repost_database), userId);
        }
      });
    });
  }

  @override
  void makeUpdateOnFindByPostId(
    String postId, {
    String? profileImage,
    String? postIdentity,
    bool? online,
  }) {
    int found = _data.indexWhere((element) => element.postId == postId);

    if (found != -1) {
      _data[found] = _data[found].copyWith(online: online);
      sendNewUpdateToUi();
    }
  }

  @override
  void removeOnFindByPostId(String postId) {
    int found = _data.indexWhere((element) => element.postId == postId);

    if (found != -1) {
      _data.removeAt(found);
      sendNewUpdateToUi();
    }
  }

  List<HomePagePostData> getAllPostByUserId(String userId) {
    return _data.where((element) => element.postBy == userId).toList();
  }

  void _fetchPostOnline() async {
    if (_membersIds == null) return null;

    _getPostLinkedData(
        (await PostOperation().getMembersPostsTime(
            _membersIds!, userPostFromTime, _fromStart,
            limitBy: 10)),
        false);
  }

  Future<List<HomePagePostData>> _getPostLinkedData(
      List<Map<String, dynamic>> allOnlinePosts, bool restarted,
      {bool mainPosts = true, bool userAdded = false}) async {
    List<PostgrestMap> allPosts =
        await resolveRepostedPost(allOnlinePosts).then((value) => value.cast());

    final postMediaList = await _fetchPostMedia(allPosts);
    final postMentions = await _fetchPostMentions(allPosts);
    if (mainPosts) {
      await _fetchPostComments(allPosts);
    }
    await _fetchPostLikes(allPosts);
    await _fetchMembersProfile(allPosts);
    await _fetchMembersConnects(allPosts);
    await _fetchPostRepost(allPosts);

    final posts = allPosts
        .asMap()
        .map((key, value) {
          Map<dynamic, dynamic> post = allPosts[key];

          List<HomePageMediaData> postMedia = postMediaList[key];
          List<ConnectInfo> postMention = postMentions[key];
          String postCreatedAt = post[dbReference(Post.created_at)].toString();
          String postId = post[dbReference(Post.id)];
          String postBy = post[dbReference(Members.id)];
          String postText = post[dbReference(Post.text)];

          return MapEntry(
              key,
              HomePagePostData(postId, postBy, postCreatedAt, postText,
                  postMedia, postMention, true, null));
        })
        .values
        .toList();

    if (mainPosts) {
      _configure(posts, true, restarted, userAdded: userAdded);
    }
    return posts;
  }

  Future<List<LikesNotifier?>> _fetchPostLikes(
      List<Map<String, dynamic>> allPosts) async {
    return await Future.wait([
      ...(await allPosts
          .asMap()
          .map((key, value) {
            String postId = value[dbReference(Post.id)];
            return MapEntry(
                key, createALikeNotifier(postId, NotifierType.normal));
          })
          .values
          .toList())
    ]);
  }

  Future<List<CommentsNotifier?>> _fetchPostComments(
      List<Map<String, dynamic>> allPosts) async {
    return await Future.wait([
      ...(allPosts
          .asMap()
          .map((key, value) {
            String postId = value[dbReference(Post.id)];
            return MapEntry(
                key, createACommentNotifier(postId, NotifierType.normal));
          })
          .values
          .toList())
    ]);
  }

  Future<List<RepostsNotifier?>> _fetchPostRepost(
      List<Map<String, dynamic>> allPosts) async {
    return await Future.wait([
      ...(await allPosts
          .asMap()
          .map((key, value) {
            String postId = value[dbReference(Post.id)];
            return MapEntry(
                key, createARepostsNotifier(postId, NotifierType.normal));
          })
          .values
          .toList())
    ]);
  }

  Future<List<ConnectsNotifier?>> _fetchMembersConnects(
      List<Map<String, dynamic>> allPosts) async {
    return await Future.wait([
      ...(await allPosts
          .asMap()
          .map((key, value) {
            String membersId = value[dbReference(Members.id)];
            return MapEntry(
                key, createAConnectsNotifier(membersId, NotifierType.normal));
          })
          .values
          .toList())
    ]);
  }

  Future<List<PostProfileNotifier?>> _fetchMembersProfile(
      List<Map<String, dynamic>> allPosts) async {
    return await Future.wait([
      ...(await allPosts
          .asMap()
          .map((key, value) {
            String membersId = value[dbReference(Members.id)];
            return MapEntry(key,
                createAPostProfileNotifier(membersId, NotifierType.normal));
          })
          .values
          .toList())
    ]);
  }

  Future<List<List<HomePageMediaData>>> _fetchPostMedia(
      List<Map<String, dynamic>> allPosts) async {
    final postMedia = await allPosts.map((value) async {
      String postId = value[dbReference(Post.id)];
      List<FileObject> mediaFiles = await PostOperation().getMediaFiles(postId);
      return await mediaFiles
          .asMap()
          .map((key, mediaFile) {
            HomePageMediaData parsedData =
                PostOperation().getParsedData(postId, mediaFile);
            return MapEntry(key, parsedData);
          })
          .values
          .toList();
    }).toList();

    return Future.wait(postMedia);
  }

  Future<List<List<ConnectInfo>>> _fetchPostMentions(
      List<Map<String, dynamic>> allPosts) async {
    final postMedia = await allPosts.map((value) async {
      String postId = value[dbReference(Post.id)];
      final postMentions = await PostOperation().getPostMention(postId);
      return await postMentions
          .asMap()
          .map((key, postMention) {
            return MapEntry(
                key,
                ConnectInfo(
                    postMention[dbReference(Members.id)],
                    "${postMention[dbReference(Members.table)][dbReference(Members.lastname)] ?? ''} ${postMention[dbReference(Members.table)][dbReference(Members.firstname)] ?? ''}",
                    postMention[dbReference(Members.table)]
                        [dbReference(Profile.image_index)]));
          })
          .values
          .toList();
    }).toList();
    return Future.wait(postMedia);
  }

  Future<List> _fetchRequiredUsers(List<Map<String, dynamic>> allPosts) async {
    return await Future.wait([
      ...(await allPosts
          .asMap()
          .map((key, value) {
            String userId = value[dbReference(Members.id)];
            return MapEntry(key, MembersOperation().userOnlineRecord(userId));
          })
          .values
          .toList())
    ]);
  }

  Future<List> resolveRepostedPost(
      List<Map<String, dynamic>> allOnlinePosts) async {
    return await Future.wait([
      ...(await allOnlinePosts
          .asMap()
          .map((key, post) {
            String? postReposted = post[dbReference(Post.reposted)];

            return MapEntry(
                key,
                (postReposted != null)
                    ? PostOperation().getOnlinePostReposted(postReposted)
                    : Future.value(post));
          })
          .values
          .toList())
    ]);
  }

  void mergeSort<T>(List<T> list, {required Comparator<T> compare}) {
    if (list.length <= 1) {
      return;
    }

    final int middle = list.length ~/ 2;
    final List<T> left = list.sublist(0, middle);
    final List<T> right = list.sublist(middle);

    mergeSort(left, compare: compare);
    mergeSort(right, compare: compare);

    int i = 0, j = 0, k = 0;

    while (i < left.length && j < right.length) {
      if (compare(left[i], right[j]) <= 0) {
        list[k++] = left[i++];
      } else {
        list[k++] = right[j++];
      }
    }

    while (i < left.length) {
      list[k++] = left[i++];
    }

    while (j < right.length) {
      list[k++] = right[j++];
    }
  }

  void updateLatestData(
      List<HomePagePostData> allPost, bool online, bool restarted,
      {bool userNewLyAdded = false}) {
    _data.addAll(allPost);
    List<String> date = _data.map((e) => e.postCreatedAt).toList();
    date.sort();
    _data = date
        .map((e) => _data.where((element) => element.postCreatedAt == e).single)
        .toList()
        .reversed
        .toList();
  }

  // List<HomePagePostData> removeDuplicates<HomePagePostData>(List<HomePagePostData> list) {
  //   Set<HomePagePostData> seen = {};
  //   List<HomePagePostData> result = [];
  //   for (var item in list) {
  //     if (!seen.contains(item)) {
  //       result.add(item);
  //       seen.add(item);
  //     }
  //   }
  //   return result;
  // }

  List<HomePagePostData> removeDuplicates(List<HomePagePostData> list) {
    Map<String, HomePagePostData> seen = {};
    List<HomePagePostData> result = [];
    for (var item in list) {
      if (!seen.containsKey(item.postId)) {
        result.add(item);
        seen[item.postId] = item;
      }
    }
    return result;
  }

  Future<void> _configure(
      List<HomePagePostData> allPosts, bool online, bool restarted,
      {bool userAdded = false}) async {
    List<HomePagePostData> allPost = removeDuplicates(allPosts);

    if (allPost.isEmpty && getLatestData().isEmpty && !_fromStart && online) {
      _fromStart = true;
      requestPaginate(canForceRetry: true);
      return;
    }

    List<String> postIds = getLatestData().map((e) => e.postId).toList();

    allPost.removeWhere((element) => postIds.contains(element.postId));

    postIds.addAll(allPost.map((e) => e.postId).toList());

    updateLatestData(allPost, false, restarted);
    if (_data.isNotEmpty) {
      await getLatestPostReceived(_data.lastOrNull?.postCreatedAt);
    }
    sendNewUpdateToUi();
  }

  void sendNewUpdateToUi() {
    getPostImplement()?.getPaginationProgressController()?.sendNewState(false);
    if (_data.isNotEmpty) {
      state.sendNewState(getLatestData());
    }
    adjustLatestNotifiersByPostId();
    adjustLatestNotifiersByUserId();
  }

  @override
  void requestPaginate({bool canForceRetry = false}) {
    if (started) {
      if (canForceRetry) {
        getPostImplement()?.getRetryStreamListener()?.sendForcedRetry();
      }
      _fetchPostOnline();
    }
  }

  @override
  void startBatchedPosts(String membersId) {}

  @override
  void startSuggestion(String membersId, bool restarted) {}

  @override
  Future<void> addUserNewPost(HomePagePostData homePagePostData) async {
    return;
  }

  @override
  Future<HomePagePostData?> getPublicPostLinkedData(
      Map<String, dynamic> allPost, List<String> postProfileConnectNotifiers) {
    return Future.value(null);
  }

  @override
  Future<void> getPublicPostLinkedNotifiers(
      String postId, String postBy) async {}
}
