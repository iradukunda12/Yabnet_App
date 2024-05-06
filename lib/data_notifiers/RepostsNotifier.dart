// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/data/RepostData.dart';
import 'package:yabnet/operations/MembersOperation.dart';

import '../builders/CustomWrapListBuilder.dart';
import '../components/CustomProject.dart';
import '../db_references/Members.dart';
import '../db_references/Post.dart';
import '../operations/CacheOperation.dart';
import '../operations/PostOperation.dart';

class RepostsImplement {
  BuildContext? getLatestContext() => null;

  RetryStreamListener? getRetryStreamListener() => null;

  PaginationProgressController? getPaginationProgressController() => null;
}

class RepostsNotifier {
  WidgetStateNotifier<List<RepostData>> state = WidgetStateNotifier();

  List<RepostData> _data = [];

  RepostsImplement? _repostImplements;

  bool started = false;

  String? _postId;
  String? _fromWhere;

  RepostsNotifier attachPostId(String postId, String fromWhere,
      {bool startFetching = false}) {
    _postId = postId;
    _fromWhere = fromWhere;

    if (startFetching) {
      _startFetching();
    }
    return this;
  }

  RepostsNotifier start(RepostsImplement repostsImplement, String postId,
      {bool startFetching = true}) {
    BuildContext? buildContext = repostsImplement.getLatestContext();
    if (buildContext != null && postId == _postId) {
      _repostImplements = repostsImplement;
      _attachListeners(repostsImplement);

      if (startFetching) {
        _startFetching();
      }
    }
    return this;
  }

  void _startFetching() {
    started = true;
    _fetchRepostsLocal();
    _fetchPostOnline();
  }

  List<RepostData> getLatestData() {
    return _data;
  }

  void _retryListener() {
    restart();
  }

  void _attachListeners(RepostsImplement commentImplement) {
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
    _repostImplements?.getRetryStreamListener()?.removeListener(_retryListener);
  }

  Future<void> _fetchPostOnline() async {
    if (_postId == null) {
      return;
    }
    _configure(await _fetchPostReposts(_postId!));
  }

  Future<List<RepostData>> _fetchPostReposts(String postId) async {
    final postReposts = await PostOperation().getPostReposts(postId);
    return postReposts
        .map((postRepost) => RepostData.fromOnline(postRepost))
        .toList();
  }

  Future<List> _fetchRequiredUsers(List<PostgrestMap> allLikes) async {
    return await Future.wait([
      ...(await allLikes
          .asMap()
          .map((key, value) {
            String userId = value[dbReference(Members.id)];
            return MapEntry(key, MembersOperation().userOnlineRecord(userId));
          })
          .values
          .toList())
    ]);
  }

  void _fetchRepostsLocal() async {
    if (_postId == null) {
      return;
    }
    final savedRepost = await CacheOperation().getCacheData(
        dbReference(Post.repost_database), _postId!,
        fromWhere: _fromWhere);

    if (savedRepost != null && savedRepost is Map) {
      final allComments =
          savedRepost.values.map((e) => RepostData.fromJson(e)).toList();
      _configure(allComments);
    }
  }

  void updateLatestData(List<RepostData> allReposts) {
    _data = allReposts;
  }

  void _configure(List<RepostData> allRepost) {
    updateLatestData(allRepost);
    sendUpdateToUi(allRepost);
    saveLatestReposts();
  }

  void sendUpdateToUi(List<RepostData> allReposts) {
    if (allReposts.isNotEmpty) {
      state.sendNewState(allReposts);
    }
  }

  Future<void> saveLatestReposts() async {
    if (_data.isNotEmpty) {
      Map mapData = Map.fromIterable(_data,
          key: (element) => element.postId,
          value: (element) => element.toJson());
      await CacheOperation().saveCacheData(
          dbReference(Post.repost_database), _postId!, mapData,
          fromWhere: _fromWhere);
    }
  }

  void addRepost(String thisUser, {RepostData? repostData}) {
    if (thisUser.isEmpty || _postId == null) {
      return;
    }
    String repostId =
        dbReference(Post.local) + "(->)" + PostOperation().getUUID();
    RepostData repost =
        RepostData(repostId, _postId!, DateTime.now().toString(), thisUser);
    _data.add(repostData ?? repost);
    sendUpdateToUi(_data);
  }

  void removePost(String thisUser) {
    int found = _data.indexWhere((element) => element.postBy == thisUser);

    if (found != -1) {
      _data.removeAt(found);
      sendUpdateToUi(_data);
    }
  }
}
