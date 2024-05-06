// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/data/HomePageCommentData.dart';
import 'package:yabnet/data_notifiers/CommentLikesNotifier.dart';
import 'package:yabnet/data_notifiers/PostProfileNotifier.dart';
import 'package:yabnet/operations/CacheOperation.dart';
import 'package:yabnet/operations/CommentOperation.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../builders/CustomWrapListBuilder.dart';
import '../components/CustomProject.dart';
import '../data/NotifierDataClass.dart';
import '../db_references/Comments.dart';
import '../db_references/Members.dart';
import '../db_references/NotifierType.dart';

class CommentsImplement {
  BuildContext? getLatestContext() => null;

  RetryStreamListener? getRetryStreamListener() => null;

  PaginationProgressController? getPaginationProgressController() => null;
}

class CommentsNotifier {
  WidgetStateNotifier<List<HomePageCommentData>> state = WidgetStateNotifier();

  List<HomePageCommentData> _data = [];

  CommentsImplement? _commentsImplement;

  bool started = false;
  bool _fromStart = false;

  String commentFromTime = DateTime.now().toUtc().toString();

  Future<bool> saveLastPostTimeChecked(String time) {
    return CacheOperation().saveCacheData(dbReference(Comments.time_database),
        dbReference(Comments.last_comment_time_checked), time);
  }

  Future<String?> getLastPostTimeChecked() async {
    return await CacheOperation().getCacheData(
        dbReference(Comments.time_database),
        dbReference(Comments.last_comment_time_checked));
  }

  String? _postId;
  String? _fromWhere;

  NotifierDataClass<CommentLikesNotifier?, NotifierType>
      _commentLikesNotifiers = NotifierDataClass();

  NotifierDataClass<PostProfileNotifier?, NotifierType> _postProfileNotifier =
      NotifierDataClass();

  void getLatestPostReceived(String? time) async {
    if (time != null) {
      commentFromTime = time;
      saveLastPostTimeChecked(time);
    }
  }

  CommentsNotifier attachPostId(String postId, String fromWhere,
      {bool startFetching = false}) {
    _postId = postId;
    _fromWhere = fromWhere;

    if (startFetching) {
      _startFetching();
    }
    return this;
  }

  CommentsNotifier start(CommentsImplement commentsImplement, String postId,
      {bool startFetching = true}) {
    BuildContext? buildContext = commentsImplement.getLatestContext();
    if (buildContext != null && postId == _postId) {
      _commentsImplement = commentsImplement;
      _attachListeners(commentsImplement);

      if (startFetching) {
        _startFetching();
      }
    }
    return this;
  }

  Future<void> _startFetching() async {
    started = true;
    _fetchPostLocal();
    _fetchPostOnline();
  }

  List<HomePageCommentData> getLatestData() {
    return _data.reversed.toList();
  }

  void _retryListener() {
    restart();
  }

  void _attachListeners(CommentsImplement commentImplement) {
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
    _commentsImplement
        ?.getRetryStreamListener()
        ?.removeListener(_retryListener);
  }

  void makeUpdateOnFindByCommentId(String commentId,
      {bool? online, String? commentToIdentity, String? commentIdentity}) {
    int found = _data.indexWhere((element) => element.commentId == commentId);

    if (found != -1) {
      _data[found] = _data[found].copyWith(online: online);
      sendNewUpdateToUi();
    }
  }

  Future<void> makeUpdateOnSuccessfulComment(
      String oldCommentId, HomePageCommentData newHomePageCommentData) async {
    int found =
        _data.indexWhere((element) => element.commentId == oldCommentId);

    if (found != -1) {
      _data[found] = newHomePageCommentData;

      CommentLikesNotifier? oldCommentLikesNotifiers = _commentLikesNotifiers
          .getData(oldCommentId, forWhich: NotifierType.normal);

      _commentLikesNotifiers.removeWhere((key, forWhich) =>
          key == oldCommentId && forWhich == NotifierType.normal);

      _commentLikesNotifiers.removeWhere((key, forWhich) =>
          key == oldCommentId && forWhich == NotifierType.normal);

      CommentLikesNotifier? commentLikesNotifiers =
          await createACommentLikeNotifier(
              newHomePageCommentData.commentId, NotifierType.normal);

      if (oldCommentLikesNotifiers?.getLatestData().isNotEmpty == true) {
        String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
        if (thisUser.isNotEmpty) {
          commentLikesNotifiers?.addLikes(thisUser);
        }
      }
      sendNewUpdateToUi();
    }
  }

  void makeUpdateOnSubCommentByCommentId(String commentId, String commentToId,
      {bool? online}) {
    int found = _data.indexWhere((element) => element.commentId == commentToId);

    if (found != -1) {
      int _found = _data[found]
          .commentsPost
          .indexWhere((element) => element.commentId == commentId);
      if (_found != -1) {
        _data[found].commentsPost[_found] =
            _data[found].commentsPost[_found].copyWith(online: online);
        sendNewUpdateToUi();
      }
    }
  }

  void makeUpdateOnSubSuccessfulComment(String oldCommentId, String commentToId,
      HomePageCommentData newHomePageCommentData) {
    int found = _data.indexWhere((element) => element.commentId == commentToId);

    if (found != -1) {
      int _found = _data[found]
          .commentsPost
          .indexWhere((element) => element.commentId == oldCommentId);
      if (_found != -1) {
        _data[found].commentsPost[_found] = newHomePageCommentData;
        CommentLikesNotifier? commentLikesNotifiers = _commentLikesNotifiers
            .getData(oldCommentId, forWhich: NotifierType.normal);
        _commentLikesNotifiers.removeWhere((key, forWhich) =>
            key == oldCommentId && forWhich == NotifierType.normal);
        _commentLikesNotifiers.addReplacementData(
            newHomePageCommentData.commentId,
            NotifierType.normal,
            commentLikesNotifiers);
        sendNewUpdateToUi();
      }
    }
  }

  void addLocalMainComment(HomePageCommentData homePageCommentData) {
    createACommentLikeNotifier(
        homePageCommentData.commentId, NotifierType.normal);
    createAPostProfileNotifier(
        homePageCommentData.commentBy, NotifierType.normal);
    if (homePageCommentData.commentToBy != null) {
      createAPostProfileNotifier(
          homePageCommentData.commentToBy!, NotifierType.normal);
    }
    _data.add(homePageCommentData);
    sendNewUpdateToUi();
  }

  void addLocalSubComment(
      HomePageCommentData homePageCommentData, String commentToId) {
    int found = _data.indexWhere((element) => element.commentId == commentToId);

    if (found != -1) {
      createACommentLikeNotifier(
          homePageCommentData.commentId, NotifierType.normal);
      createAPostProfileNotifier(
          homePageCommentData.commentBy, NotifierType.normal);
      if (homePageCommentData.commentToBy != null) {
        createAPostProfileNotifier(
            homePageCommentData.commentToBy!, NotifierType.normal);
      }
      _data[found].commentsPost.add(homePageCommentData);
      sendNewUpdateToUi();
    }
  }

  void deleteLocalMainComment(String commentId) {
    int found = _data.indexWhere((element) => element.commentId == commentId);
    if (found != -1) {
      _data.removeAt(found);
      sendNewUpdateToUi();
    }
  }

  void deleteLocalSubComment(String commentId, String commentTotId) {
    int found =
        _data.indexWhere((element) => element.commentId == commentTotId);

    if (found != -1) {
      int _found = _data[found]
          .commentsPost
          .indexWhere((element) => element.commentId == commentId);
      if (_found != -1) {
        _data[found].commentsPost.removeAt(_found);
        sendNewUpdateToUi();
      }
    }
  }

  List<HomePageCommentData> getAllPostByUserId(String userId) {
    return _data.where((element) => element.commentBy == userId).toList();
  }

  Future<void> _fetchPostOnline() async {
    if (_postId == null) {
      return;
    }
    _getCommentLinkedData(
        (await CommentOperation()
                .getPostComments(_postId!, commentFromTime, _fromStart, 4))
            .where((element) => element[dbReference(Comments.to)] == null)
            .toList(),
        NotifierType.normal);
  }

  Future<HomePageCommentData?> getPublicCommentLinkedData(
      Map<String, dynamic> allComments, String? postId) async {
    _postId = postId;
    return (await _getCommentLinkedData([allComments], NotifierType.external))
        .single;
  }

  void getPublicPostLinkedNotifiers(String commentId, String membersId) async {
    await createACommentLikeNotifier(commentId, NotifierType.external);
    await createAPostProfileNotifier(membersId, NotifierType.external);
  }

  Future<List<HomePageCommentData>> _getCommentLinkedData(
      List<Map<String, dynamic>> allComments, NotifierType notifierType,
      {bool mainComments = true}) async {
    final getSubCommentsMap =
        mainComments ? await _fetchCommentsToMap(allComments) : [];
    List<List<HomePageCommentData>> getSubComments =
        mainComments ? await _fetchSubComments(getSubCommentsMap.cast()) : [];

    final getCommentToMap = mainComments
        ? getSubComments.map((e) {
            return e.map((subComment) async {
              if (subComment.commentTo == null) return null;
              return await CommentOperation()
                  .getPostCommentsTo(subComment.commentTo!);
            }).toList();
          }).toList()
        : [];

    final getCommentTo = await Future.wait(
        await (await getCommentToMap.map((e) => Future.wait(e))));

    if (notifierType == NotifierType.normal) {
      await _fetchCommentsLikes(allComments, notifierType);
      await _fetchPostProfileNotifier(allComments, notifierType);
      if (getCommentTo.isNotEmpty) {
        await _fetchPostToProfileNotifier(getCommentTo.cast(), notifierType);
      }
    }

    final comments = allComments
        .asMap()
        .map((key, value) {
          Map<dynamic, dynamic> comments = allComments[key];

          String postCreatedAt =
              comments[dbReference(Comments.created_at)].toString();
          String commentId = comments[dbReference(Comments.id)];
          String membersId = comments[dbReference(Members.id)];
          String commentText = comments[dbReference(Comments.text)];
          String? commentTo = comments[dbReference(Comments.to)];
          String? commentToBy =
              comments[dbReference(Comments.table)]?[dbReference(Members.id)];
          String? commentParent = comments[dbReference(Comments.parent)];
          final subComment = (getSubComments.elementAtOrNull(key) ?? []);

          List<HomePageCommentData?> allCommentTo = subComment
              .asMap()
              .map((index, value) {
                final subCommentTo = (getCommentTo.elementAtOrNull(key) ?? []);

                final commentToMap = subCommentTo.elementAtOrNull(index);
                final commentToBy = commentToMap[dbReference(Members.id)];
                return MapEntry(
                    index,
                    value.copyWith(
                      commentToBy: commentToBy,
                    ));
              })
              .values
              .toList();

          return MapEntry(
              key,
              HomePageCommentData(
                commentId,
                membersId,
                postCreatedAt,
                commentText,
                allCommentTo.cast(),
                true,
                commentTo,
                commentToBy,
                commentParent,
              ));
        })
        .values
        .toList();
    if (mainComments) {
      _configure(comments, true, false);
    }
    return comments;
  }

  CommentLikesNotifier? getCommentLikeNotifier(
      String commentId, NotifierType notifierType) {
    return _commentLikesNotifiers.getData(commentId, forWhich: notifierType);
  }

  PostProfileNotifier? getPostProfileNotifier(
      String membersId, NotifierType notifierType) {
    return _postProfileNotifier.getData(membersId, forWhich: notifierType);
  }

  Future<List<CommentLikesNotifier?>> _fetchCommentsLikes(
      List<Map<String, dynamic>> allComments, NotifierType notifierType) async {
    return await Future.wait([
      ...(await allComments
          .asMap()
          .map((key, value) {
            String commentId = value[dbReference(Comments.id)];
            return MapEntry(
                key, createACommentLikeNotifier(commentId, notifierType));
          })
          .values
          .toList())
    ]);
  }

  Future<List<PostProfileNotifier?>> _fetchPostProfileNotifier(
      List<Map<String, dynamic>> allComments, NotifierType notifierType) async {
    return await Future.wait([
      ...(await allComments
          .asMap()
          .map((key, value) {
            String memberId = value[dbReference(Members.id)];
            return MapEntry(
                key, createAPostProfileNotifier(memberId, notifierType));
          })
          .values
          .toList())
    ]);
  }

  Future<List<List<PostProfileNotifier?>>> _fetchPostToProfileNotifier(
      List<List<dynamic>> allComments, NotifierType notifierType) async {
    return await Future.wait(
      allComments.map((commentsList) async {
        return await Future.wait(
          commentsList.map((commentMap) async {
            String? memberId = commentMap?[dbReference(Members.id)];
            if (memberId != null) {
              return await createAPostProfileNotifier(memberId, notifierType);
            } else {
              return null;
            }
          }).toList(),
        );
      }).toList(),
    );
  }

  Future<CommentLikesNotifier?> createACommentLikeNotifier(
      String commentId, NotifierType notifierType) async {
    if (!_commentLikesNotifiers.containIdentity(commentId, notifierType)) {
      CommentLikesNotifier likesNotifiers = CommentLikesNotifier()
          .attachCommentId(commentId, _fromWhere, startFetching: true);
      _commentLikesNotifiers.addReplacementData(
          commentId, notifierType, likesNotifiers);
      return _commentLikesNotifiers.getData(commentId, forWhich: notifierType);
    } else {
      CommentLikesNotifier? likesNotifiers =
          _commentLikesNotifiers.getData(commentId, forWhich: notifierType);
      return likesNotifiers;
    }
  }

  Future<PostProfileNotifier?> createAPostProfileNotifier(
      String memberId, NotifierType notifierType) async {
    if (!_postProfileNotifier.containIdentity(memberId, notifierType)) {
      PostProfileNotifier likesNotifiers = PostProfileNotifier()
          .attachMembersId(memberId, _fromWhere, startFetching: true);
      _postProfileNotifier.addReplacementData(
          memberId, notifierType, likesNotifiers);
      return _postProfileNotifier.getData(memberId, forWhich: notifierType);
    } else {
      PostProfileNotifier? likesNotifiers =
          _postProfileNotifier.getData(memberId, forWhich: notifierType);
      return likesNotifiers;
    }
  }

  Future<List<PostgrestList>> _fetchCommentsToMap(
      List<Map<String, dynamic>> allComments) async {
    return await Future.wait([
      ...(await allComments
          .asMap()
          .map((key, value) {
            String commentId = value[dbReference(Comments.id)];
            return MapEntry(key, CommentOperation().getCommentTo(commentId));
          })
          .values
          .toList())
    ]);
  }

  Future<List<List<HomePageCommentData>>> _fetchSubComments(
      List<List<Map<String, dynamic>>> allCommentsMap) async {
    return await Future.wait([
      ...(await allCommentsMap
          .asMap()
          .map((key, allComments) {
            return MapEntry(
                key,
                _getCommentLinkedData(allComments, NotifierType.normal,
                    mainComments: false));
          })
          .values
          .toList())
    ]);
  }

  Future<List> _fetchRequiredUsers(
      List<Map<String, dynamic>> allComments) async {
    return await Future.wait([
      ...(await allComments
          .asMap()
          .map((key, value) {
            String userId = value[dbReference(Members.id)];
            return MapEntry(key, MembersOperation().userOnlineRecord(userId));
          })
          .values
          .toList())
    ]);
  }

  Future<List> _fetchRequiredUsersTo(
      List<Map<String, dynamic>> allComments) async {
    return await Future.wait([
      ...(await allComments
          .asMap()
          .map((key, value) {
            String? commentId = value[dbReference(Comments.to)];
            return MapEntry(
                key, CommentOperation().getCommentToIdentity(commentId));
          })
          .values
          .toList())
    ]);
  }

  void _fetchPostLocal() async {
    if (_postId == null) {
      return;
    }
    final savedPosts = await CacheOperation().getCacheData(
        dbReference(Comments.database), _postId!,
        fromWhere: _fromWhere);

    if (savedPosts != null && savedPosts is Map) {
      final allComments = savedPosts.values
          .map((e) => HomePageCommentData.fromJson(e))
          .toList();

      allComments.forEach((mainComment) {
        createACommentLikeNotifier(mainComment.commentId, NotifierType.normal);
        createAPostProfileNotifier(mainComment.commentBy, NotifierType.normal);
        mainComment.commentsPost.forEach((subComment) {
          createACommentLikeNotifier(subComment.commentId, NotifierType.normal);
          createAPostProfileNotifier(subComment.commentBy, NotifierType.normal);
          if (subComment.commentToBy != null) {
            createAPostProfileNotifier(
                subComment.commentToBy!, NotifierType.normal);
          }
        });
      });
      _configure(allComments, false, false);
    }
  }

  void updateLatestData(
      List<HomePageCommentData> allComments, bool online, bool restarted) {
    _data.addAll(allComments);
  }

  CommentsImplement? getCommentImplement() {
    return _commentsImplement;
  }

  void requestPaginate({bool canForceRetry = false}) {
    if (started) {
      if (canForceRetry) {
        getCommentImplement()?.getRetryStreamListener()?.sendForcedRetry();
      }
      _fetchPostOnline();
    }
  }

  void _configure(
      List<HomePageCommentData> allComments, bool online, bool restarted) {
    allComments.sort((a, b) {
      final aDate = DateTime.tryParse(a.commentCreatedAt);
      final bDate = DateTime.tryParse(b.commentCreatedAt);

      if (aDate == null || bDate == null) {
        return 0;
      }
      return aDate.isBefore(bDate) ? 0 : 1;
    });

    if (allComments.isEmpty &&
        getLatestData().isEmpty &&
        !_fromStart &&
        online) {
      _fromStart = true;
      requestPaginate(canForceRetry: true);
      return;
    }

    List<String> commentsIds = getLatestData().map((e) => e.commentId).toList();

    allComments
        .removeWhere((element) => commentsIds.contains(element.commentId));

    commentsIds.addAll(allComments.map((e) => e.commentId).toList());

    int commentSize = allComments.length;

    if (commentSize <= 0 && getLatestData().isNotEmpty) {
      getLatestPostReceived(getLatestData().firstOrNull?.commentCreatedAt);
    } else {
      getLatestPostReceived(allComments.lastOrNull?.commentCreatedAt);
    }

    updateLatestData(allComments, false, restarted);
    sendNewUpdateToUi();
  }

  void sendNewUpdateToUi() {
    state.sendNewState(_data.reversed.toList());
    saveLatestComment();
  }

  Future<void> saveLatestComment() async {
    if (_data.isNotEmpty && _fromWhere != null) {
      Map mapData = Map.fromIterable(_data,
          key: (element) => element.commentId,
          value: (element) => element.toJson());
      await CacheOperation().saveCacheData(
          dbReference(Comments.database), _postId!, mapData,
          fromWhere: _fromWhere);
    }
  }
}
