// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/operations/MembersOperation.dart';

import '../builders/CustomWrapListBuilder.dart';
import '../components/CustomProject.dart';
import '../data/LikesData.dart';
import '../db_references/Likes.dart';
import '../db_references/Members.dart';
import '../operations/CacheOperation.dart';
import '../operations/PostOperation.dart';

class LikesImplement {
  BuildContext? getLatestContext() => null;

  RetryStreamListener? getRetryStreamListener() => null;

  PaginationProgressController? getPaginationProgressController() => null;
}

class LikesNotifier {
  WidgetStateNotifier<List<LikesData>> state = WidgetStateNotifier();

  List<LikesData> _data = [];

  LikesImplement? _likesImplements;

  bool started = false;

  String? _postId;
  String? _fromWhere;

  LikesNotifier attachPostId(String postId, String fromWhere,
      {bool startFetching = false}) {
    _postId = postId;
    _fromWhere = fromWhere;
    if (startFetching) {
      _startFetching();
    }
    return this;
  }

  LikesNotifier start(LikesImplement likesImplement, String postId,
      {bool startFetching = true}) {
    BuildContext? buildContext = likesImplement.getLatestContext();
    if (buildContext != null && postId == _postId) {
      _likesImplements = likesImplement;
      _attachListeners(likesImplement);

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

  void _attachListeners(LikesImplement commentImplement) {
    RetryStreamListener? _retryStreamListener =
        commentImplement.getRetryStreamListener();
    _retryStreamListener?.addListener(_retryListener);
  }

  void restart() {
    showDebug(msg: _postId);
    if (started) {
      _fetchPostOnline();
    }
  }

  void stop() {
    _likesImplements?.getRetryStreamListener()?.removeListener(_retryListener);
  }

  Future<void> _fetchPostOnline() async {
    if (_postId == null) {
      return;
    }
    _configure(await _fetchPostLikes(_postId!));
  }

  Future<List<LikesData>> _fetchPostLikes(String postId) async {
    final postLikes = await PostOperation().getPostLikes(postId);
    final membersIdentityFuture = postLikes
        .map((e) =>
            MembersOperation().userOnlineRecord(e[dbReference(Members.id)]))
        .toList();
    final membersIdentity = await Future.wait(membersIdentityFuture);
    return membersIdentity
        .asMap()
        .map((key, value) {
          final postLike = postLikes[key];
          final identity =
              "${value[dbReference(Members.lastname)]} ${value[dbReference(Members.firstname)]}";
          return MapEntry(key, LikesData.fromOnline(postLike, identity));
        })
        .values
        .toList();
  }

  void _fetchLikesLocal() async {
    if (_postId == null) {
      return;
    }
    final savedPostLikes = await CacheOperation().getCacheData(
        dbReference(Likes.post_database), _postId!,
        fromWhere: _fromWhere);

    if (savedPostLikes != null && savedPostLikes is Map) {
      final allLikes =
          savedPostLikes.values.map((e) => LikesData.fromJson(e)).toList();
      _configure(allLikes);
    }
  }

  void updateLatestData(List<LikesData> allLikes) {
    _data = allLikes;
  }

  void addLikes(String userId) async {
    if (userId.isEmpty || _postId == null) {
      return;
    }

    String fullname = await MembersOperation().getFullName();
    String likesId = PostOperation().getUUID();
    LikesData like = LikesData(
      likesId,
      DateTime.now().toString(),
      _postId,
      null,
      null,
      fullname,
      userId,
    );
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
    saveLatestPostLikes();
  }

  void sendUpdateToUi(List<LikesData> allLikes) {
    state.sendNewState(allLikes);
  }

  Future<void> saveLatestPostLikes() async {
    if (_data.isNotEmpty) {
      Map mapData = Map.fromIterable(_data,
          key: (element) => element.likesId,
          value: (element) => element.toJson());
      await CacheOperation().saveCacheData(
          dbReference(Likes.post_database), _postId!, mapData,
          fromWhere: _fromWhere);
    }
  }
}
