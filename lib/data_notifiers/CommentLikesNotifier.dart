// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/operations/CommentOperation.dart';
import 'package:yabnet/operations/MembersOperation.dart';

import '../builders/CustomWrapListBuilder.dart';
import '../components/CustomProject.dart';
import '../data/LikesData.dart';
import '../db_references/Likes.dart';
import '../db_references/Members.dart';
import '../operations/CacheOperation.dart';
import '../operations/PostOperation.dart';

class CommentLikesImplement {
  BuildContext? getLatestContext() => null;

  RetryStreamListener? getRetryStreamListener() => null;

  PaginationProgressController? getPaginationProgressController() => null;
}

class CommentLikesNotifier {
  WidgetStateNotifier<List<LikesData>> state = WidgetStateNotifier();

  List<LikesData> _data = [];

  CommentLikesImplement? _commentLikesImplements;

  bool started = false;

  String? _commentId;
  String? _fromWhere;

  CommentLikesNotifier attachCommentId(String commentId, String? fromWhere,
      {bool startFetching = false}) {
    _commentId = commentId;
    _fromWhere = fromWhere;

    if (startFetching) {
      _startFetching();
    }
    return this;
  }

  CommentLikesNotifier start(
      CommentLikesImplement commentLikesImplement, String postId,
      {bool startFetching = true}) {
    BuildContext? buildContext = commentLikesImplement.getLatestContext();
    if (buildContext != null && postId == _commentId) {
      _commentLikesImplements = commentLikesImplement;
      _attachListeners(commentLikesImplement);

      if (startFetching) {
        _startFetching();
      }
    }
    return this;
  }

  void _startFetching() {
    started = true;
    _fetchLikesLocal();
    _fetchPostOnline();
  }

  List<LikesData> getLatestData() {
    return _data;
  }

  void _retryListener() {
    restart();
  }

  void _attachListeners(CommentLikesImplement commentImplement) {
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
    _commentLikesImplements
        ?.getRetryStreamListener()
        ?.removeListener(_retryListener);
  }

  Future<void> _fetchPostOnline() async {
    if (_commentId == null) {
      return;
    }
    _configure(await _fetchCommentLikes(_commentId!));
  }

  Future<List<LikesData>> _fetchCommentLikes(String commentId) async {
    if (commentId.contains("->")) return [];
    final commentLikes = await CommentOperation().getCommentLikes(commentId);
    final membersIdentityFuture = commentLikes
        .map((e) =>
            MembersOperation().userOnlineRecord(e[dbReference(Members.id)]))
        .toList();
    final membersIdentity = await Future.wait(membersIdentityFuture);
    return membersIdentity
        .asMap()
        .map((key, value) {
          final commentLike = commentLikes[key];
          final identity =
              "${value[dbReference(Members.lastname)]} ${value[dbReference(Members.firstname)]}";
          return MapEntry(key, LikesData.fromOnline(commentLike, identity));
        })
        .values
        .toList();
  }

  void _fetchLikesLocal() async {
    if (_commentId == null) {
      return;
    }
    final savedCommentLikes = await CacheOperation().getCacheData(
        dbReference(Likes.comment_database), _commentId!,
        fromWhere: _fromWhere);

    if (savedCommentLikes != null && savedCommentLikes is Map) {
      final allLikes =
          savedCommentLikes.values.map((e) => LikesData.fromJson(e)).toList();
      _configure(allLikes);
    }
  }

  void updateLatestData(List<LikesData> allLikes) {
    _data = allLikes;
  }

  void addLikes(String userId) async {
    if (userId.isEmpty || _commentId == null) {
      return;
    }

    String fullname = await MembersOperation().getFullName();

    String likesId =
        dbReference(Likes.local) + "(->)" + PostOperation().getUUID();
    LikesData like = LikesData(likesId, DateTime.now().toString(), null, null,
        _commentId, fullname, userId);
    _data.add(like);
    sendUpdateToUi(_data);
  }

  void removeLikes(String userId) {
    int found = _data.indexWhere((element) => element.membersId == userId);

    if (found != -1) {
      _data.removeAt(found);
      sendUpdateToUi(_data);
    }
  }

  void _configure(List<LikesData> allLikes) {
    updateLatestData(allLikes);
    sendUpdateToUi(allLikes);
    saveLatestCommentLikes();
  }

  void sendUpdateToUi(List<LikesData> allLikes) {
    state.sendNewState(allLikes);
  }

  Future<void> saveLatestCommentLikes() async {
    if (_data.isNotEmpty) {
      Map mapData = Map.fromIterable(_data,
          key: (element) => element.likesId,
          value: (element) => element.toJson());
      await CacheOperation().saveCacheData(
          dbReference(Likes.comment_database), _commentId!, mapData,
          fromWhere: _fromWhere);
    }
  }

  String? getCommentId() {
    return _commentId;
  }
}
