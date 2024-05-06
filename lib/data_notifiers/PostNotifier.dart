// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/builders/CustomWrapListBuilder.dart';
import 'package:yabnet/data/ConnectInfo.dart';
import 'package:yabnet/data/HomePagePostData.dart';
import 'package:yabnet/data_notifiers/CommentsNotifier.dart';
import 'package:yabnet/data_notifiers/ConnectsNotifier.dart';
import 'package:yabnet/data_notifiers/LikesNotifier.dart';
import 'package:yabnet/data_notifiers/PostProfileNotifier.dart';
import 'package:yabnet/data_notifiers/RepostsNotifier.dart';
import 'package:yabnet/generator/PostFeedsGenerator.dart';
import 'package:yabnet/operations/CacheOperation.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/operations/PostOperation.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../components/CustomProject.dart';
import '../data/NotifierDataClass.dart';
import '../db_references/Comments.dart';
import '../db_references/Likes.dart';
import '../db_references/Members.dart';
import '../db_references/NotifierType.dart';
import '../db_references/Post.dart';
import '../db_references/Profile.dart';

class PostSessionIdentifier {
  int? _identity;

  int? getIdentity() {
    return _identity;
  }

  int createStack(BuildContext context) {
    if (_identity == null) {
      _identity = Random().nextInt(999) + Random().nextInt(9999);
    }
    return _identity!;
  }
}

class PostImplement {
  BuildContext? getLatestContext() => null;

  RetryStreamListener? getRetryStreamListener() => null;

  PaginationProgressController? getPaginationProgressController() => null;
}

class UnattendedNotifier {}

class PostNotifier implements UnattendedNotifier {
  static final PostNotifier instance = PostNotifier.internal();

  factory PostNotifier() => instance;

  WidgetStateNotifier<List<HomePagePostData>> state = WidgetStateNotifier();

  List<HomePagePostData> _data = [];

  PostNotifier.internal();

  int? _identity;
  PostImplement? _postImplement;

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

  String fromWhere = dbReference(Post.table);

  Future<void> start(
      PostImplement postImplement, PostSessionIdentifier postStack) async {
    BuildContext? buildContext = postImplement.getLatestContext();
    if (buildContext != null) {
      _identity = postStack.createStack(buildContext);
      started = true;
      _attachListeners(postImplement);
      _fetchPostLocal();
      if (getLatestData().isEmpty) {
        _fetchPostOnline(true);
      }
    }
  }

  List<HomePagePostData> getLatestData() {
    return _data;
  }

  void _retryListener() {
    restart();
  }

  void _attachListeners(PostImplement postImplement) {
    _postImplement?.getRetryStreamListener()?.removeListener(_retryListener);
    _postImplement = postImplement;
    postImplement.getRetryStreamListener()?.addListener(_retryListener);
  }

  void restart() {
    if (started &&
        getPostImplement()?.getRetryStreamListener()?.retrying == true) {
      // Likes
      _likesNotifiers.getDataList().forEach((element) {
        (element.data as LikesNotifier?)?.restart();
      });
      // Repost
      _repostsNotifiers.getDataList().forEach((element) {
        (element.data as RepostsNotifier?)?.restart();
      });
      // connects
      _connectsNotifiers.getDataList().forEach((element) {
        (element.data as ConnectsNotifier?)?.restart();
      });
      _fetchPostOnline(true);
    }
  }

  void requestPaginate({bool canForceRetry = false}) {
    if (started) {
      if (canForceRetry) {
        getPostImplement()?.getRetryStreamListener()?.sendForcedRetry();
      }
      _fetchPostOnline(false);
    }
  }

  void stop(PostSessionIdentifier postStack) {
    if (postStack._identity != null) {
      _postImplement?.getRetryStreamListener()?.removeListener(_retryListener);
      _postImplement = null;
    }
  }

  PostImplement? getPostImplement() {
    return _postImplement;
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
    List<String> allPostId = getLatestData().map((e) => e.postId).toList();
    _commentNotifiers.removeWhere((identity, notifierType) =>
        !allPostId.contains(identity) && notifierType == NotifierType.normal);
    _likesNotifiers.removeWhere((identity, notifierType) =>
        !allPostId.contains(identity) && notifierType == NotifierType.normal);
    _repostsNotifiers.removeWhere((identity, notifierType) =>
        !allPostId.contains(identity) && notifierType == NotifierType.normal);

    // Cache Comments & Likes
    CacheOperation()
        .getCacheKeys(dbReference(Comments.database))
        .then((cacheIds) {
      cacheIds.forEach((postId) async {
        if (!allPostId.contains(postId)) {
          final postComments = await CacheOperation()
              .getCacheData(dbReference(Comments.database), postId);

          if (postComments != null && postComments is List) {
            postComments.forEach((comment) {
              CacheOperation().deleteCacheData(
                  dbReference(Likes.comment_database), comment["commentId"]);
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
    _connectsNotifiers.removeWhere((identity, notifierType) =>
        !allPostBy.contains(identity) && notifierType == NotifierType.normal);

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

  void makeUpdateOnFindByPostId(
    String postId, {
    bool? online,
  }) {
    int found = _data.indexWhere((element) => element.postId == postId);

    if (found != -1) {
      _data[found] = _data[found].copyWith(online: online);
      sendNewUpdateToUi();
    }
  }

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

  void _fetchPostOnline(bool restarted) async {
    String membersId = SupabaseConfig.client.auth.currentUser?.id ?? '';

    bool process = true;
    // Restarted the feed when there are existing post in ui
    if (getLatestData().isNotEmpty) {
      if (restarted) {
        // If restarted
        // Get Post on batch to ui
        List<HomePagePostData> newPostWasGotten =
            PostFeedsGenerator().getNextPostToBeDisplayed(this);

        // If there was, clear old feeds and configure them
        if (newPostWasGotten.isNotEmpty) {
          process = false;
          getPostImplement()
              ?.getPaginationProgressController()
              ?.sendNewState(false);
          _configure(newPostWasGotten, restarted);
        }
      } else {
        // If paginated
        // get Post on batch to ui if there is maybe posts
        _configure(PostFeedsGenerator().getNextPostToBeDisplayed(this), false);
      }
    }

    try {
      // Fetch Suggestion Post asynchronously if permitted
      startSuggestion(membersId, restarted);

      // Get A new batch for displaying as per request
      _getPostLinkedData(
          (await await PostOperation().getPersonalizedPosts(
                  membersId,
                  PostFeedsGenerator().personalizedTool,
                  PostFeedsGenerator().getPostGreaterThanTime(restarted),
                  PostFeedsGenerator().getPostLesserThanTime(restarted),
                  PostFeedsGenerator().getPostRetry(),
                  limitBy: PostFeedsGenerator().getPersonalizedLimitBy()))
              .where((element) => element[dbReference(Post.reposted)] == null)
              .toList(),
          restarted,
          NotifierType.normal,
          processForOffset: process);

      // Fetch Personalized Post asynchronously for next batch
      startBatchedPosts(membersId);
    } catch (e) {
      getPostImplement()
          ?.getRetryStreamListener()
          ?.controlRequestCall(Duration(seconds: 15), () {
        showToastMobile(msg: "Unable to get feeds");
      });
      getPostImplement()
          ?.getPaginationProgressController()
          ?.sendNewState(false);
    }
  }

  void startSuggestion(String membersId, bool restarted) async {
    PostFeedsGenerator().startSuggestionGenerativePost(_getPostLinkedData(
        (await await PostOperation().getSuggestedPosts(
          membersId,
          PostFeedsGenerator().getPostGreaterThanTime(restarted),
          PostFeedsGenerator().getPostLesserThanTime(true),
          PostFeedsGenerator().getPostRetry(),
          limitBy: PostFeedsGenerator().getSuggestionLimitBy(),
        ))
            .where((element) => element[dbReference(Post.reposted)] == null)
            .toList(),
        false,
        NotifierType.normal,
        processForOffset: false));
  }

  void startBatchedPosts(String membersId) async {
    PostFeedsGenerator().startBatchedPersonalizedGenerativePost(
        _getPostLinkedData(
            (await await PostOperation().getPersonalizedPosts(
                    membersId,
                    PostFeedsGenerator().personalizedTool,
                    PostFeedsGenerator().getPostGreaterThanTime(true),
                    PostFeedsGenerator().getPostLesserThanTime(true),
                    PostFeedsGenerator().getPostRetry(),
                    limitBy: PostFeedsGenerator().getPersonalizedLimitBy()))
                .where((element) => element[dbReference(Post.reposted)] == null)
                .toList(),
            false,
            NotifierType.normal,
            processForOffset: false));
  }

  Future<HomePagePostData?> getPublicPostLinkedData(
      Map<String, dynamic> allPost,
      List<String> postProfileConnectNotifiers) async {
    if (allPost[dbReference(Post.id)] == null) return null;
    final postProfile = postProfileConnectNotifiers.map((e) async =>
        await createAPostProfileNotifier(e, NotifierType.external));
    await Future.wait(postProfile.toList());
    return (await _getPostLinkedData([allPost], false, NotifierType.external,
            processForOffset: false))
        .single;
  }

  Future<void> getPublicPostLinkedNotifiers(
      String postId, String postBy) async {
    await createACommentNotifier(postId, NotifierType.external);
    await createALikeNotifier(postId, NotifierType.external);
    await createARepostsNotifier(postId, NotifierType.external);
    await createAConnectsNotifier(postBy, NotifierType.external);
    await createAPostProfileNotifier(postBy, NotifierType.external);
  }

  Future<List<HomePagePostData>> _getPostLinkedData(
      List<Map<String, dynamic>> allPosts,
      bool restarted,
      NotifierType notifierType,
      {bool mainPosts = true,
      bool processForOffset = true}) async {
    final postMediaList = await _fetchPostMedia(allPosts);
    final postMentions = await _fetchPostMentions(allPosts);

    if (notifierType == NotifierType.normal) {
      if (mainPosts) {
        await _fetchPostComments(allPosts, notifierType);
      }
      await _fetchMembersProfile(allPosts, notifierType);
      await _fetchPostLikes(allPosts, notifierType);
      await _fetchPostRepost(allPosts, notifierType);
      await _fetchMembersConnects(allPosts, notifierType);
    }

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

    if (mainPosts && processForOffset) {
      _configure(posts, restarted);
    }
    return posts;
  }

  Future<List<LikesNotifier?>> _fetchPostLikes(
      List<Map<String, dynamic>> allPosts, NotifierType notifierType) async {
    return await Future.wait([
      ...(await allPosts
          .asMap()
          .map((key, value) {
            String postId = value[dbReference(Post.id)];
            return MapEntry(key, createALikeNotifier(postId, notifierType));
          })
          .values
          .toList())
    ]);
  }

  Future<List<CommentsNotifier?>> _fetchPostComments(
      List<Map<String, dynamic>> allPosts, NotifierType notifierType) async {
    return await Future.wait([
      ...(allPosts
          .asMap()
          .map((key, value) {
            String postId = value[dbReference(Post.id)];
            return MapEntry(key, createACommentNotifier(postId, notifierType));
          })
          .values
          .toList())
    ]);
  }

  Future<List<RepostsNotifier?>> _fetchPostRepost(
      List<Map<String, dynamic>> allPosts, NotifierType notifierType) async {
    return await Future.wait([
      ...(await allPosts
          .asMap()
          .map((key, value) {
            String postId = value[dbReference(Post.id)];
            return MapEntry(key, createARepostsNotifier(postId, notifierType));
          })
          .values
          .toList())
    ]);
  }

  Future<List<ConnectsNotifier?>> _fetchMembersConnects(
      List<Map<String, dynamic>> allPosts, NotifierType notifierType) async {
    return await Future.wait([
      ...(await allPosts
          .asMap()
          .map((key, value) {
            String membersId = value[dbReference(Members.id)];
            return MapEntry(
                key, createAConnectsNotifier(membersId, notifierType));
          })
          .values
          .toList())
    ]);
  }

  Future<List<PostProfileNotifier?>> _fetchMembersProfile(
      List<Map<String, dynamic>> allPosts, NotifierType notifierType) async {
    return await Future.wait([
      ...(await allPosts
          .asMap()
          .map((key, value) {
            String membersId = value[dbReference(Members.id)];
            return MapEntry(
                key, createAPostProfileNotifier(membersId, notifierType));
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

  Future<bool> _fetchPostLocal() async {
    final allPost = await PostOperation().getGeneralLocalData();
    if (allPost.isNotEmpty) {
      await Future.wait(allPost
          .map((element) async =>
              await createACommentNotifier(element.postId, NotifierType.normal))
          .toList());
      await Future.wait(allPost
          .map((element) async =>
              await createALikeNotifier(element.postId, NotifierType.normal))
          .toList());
      await Future.wait(allPost
          .map((element) async =>
              await createARepostsNotifier(element.postId, NotifierType.normal))
          .toList());
      await Future.wait(allPost
          .map((element) async => await createAConnectsNotifier(
              element.postBy, NotifierType.normal))
          .toList());
      await Future.wait(allPost
          .map((element) async => await createAPostProfileNotifier(
              element.postBy, NotifierType.normal))
          .toList());
    }
    return _configure(allPost, false, online: false);
  }

  Future<void> addUserNewPost(HomePagePostData homePagePostData) async {
    if (started) {
      await createACommentNotifier(
          homePagePostData.postId, NotifierType.normal);
      await createALikeNotifier(homePagePostData.postId, NotifierType.normal);
      await createARepostsNotifier(
          homePagePostData.postId, NotifierType.normal);
      await createAConnectsNotifier(
          homePagePostData.postBy, NotifierType.normal);
      await createAPostProfileNotifier(
          homePagePostData.postBy, NotifierType.normal);
      _configure([homePagePostData], false, userNewLyAdded: true);
    }
  }

  void updateLatestData(
      List<HomePagePostData> allPost, bool online, bool restarted,
      {bool userNewLyAdded = false}) {
    if (restarted && allPost.isNotEmpty && online) {
      _data.clear();
    }
    if (!userNewLyAdded) {
      _data.addAll(allPost);
    } else {
      allPost.forEach((element) {
        _data.insert(0, element);
      });
    }
  }

  Future<bool> _configure(List<HomePagePostData> allPost, bool restarted,
      {bool online = true, bool userNewLyAdded = false}) async {
    allPost.sort((a, b) {
      final aDate = DateTime.tryParse(a.postCreatedAt);
      final bDate = DateTime.tryParse(b.postCreatedAt);

      if (aDate == null || bDate == null) {
        return 0;
      }
      return aDate.isBefore(bDate) ? 1 : 0;
    });

    List<HomePagePostData> nextValidPostForUi =
        PostFeedsGenerator().processNextOffset(this, allPost, userNewLyAdded);

    updateLatestData(nextValidPostForUi, online, restarted,
        userNewLyAdded: userNewLyAdded);

    if (nextValidPostForUi.isNotEmpty && online) {
      await PostOperation()
          .saveGeneralLocalPost(nextValidPostForUi)
          .then((value) => value);
    }
    sendNewUpdateToUi();
    return true;
  }

  void sendNewUpdateToUi() {
    getPostImplement()?.getPaginationProgressController()?.sendNewState(false);
    if (_data.isNotEmpty) {
      state.sendNewState(_data);
    }
    adjustLatestNotifiersByPostId();
    adjustLatestNotifiersByUserId();
  }
}
