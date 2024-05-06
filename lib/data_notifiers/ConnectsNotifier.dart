// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/data/ConnectData.dart';
import 'package:yabnet/operations/MembersOperation.dart';

import '../builders/CustomWrapListBuilder.dart';
import '../components/CustomProject.dart';
import '../db_references/Members.dart';
import '../operations/CacheOperation.dart';
import '../operations/PostOperation.dart';

class ConnectsImplement {
  BuildContext? getLatestContext() => null;

  RetryStreamListener? getRetryStreamListener() => null;

  PaginationProgressController? getPaginationProgressController() => null;
}

class ConnectsNotifier {
  WidgetStateNotifier<List<ConnectData>> state = WidgetStateNotifier();

  List<ConnectData> _data = [];

  ConnectsImplement? _connectImplements;

  bool started = false;

  String? _membersId;
  String? _fromWhere;

  ConnectsNotifier attachMembersId(String memberId, String fromWhere,
      {bool startFetching = false}) {
    _membersId = memberId;
    _fromWhere = fromWhere;

    if (startFetching) {
      _startFetching();
    }
    return this;
  }

  ConnectsNotifier start(ConnectsImplement likesImplement, String postId,
      {bool startFetching = true}) {
    BuildContext? buildContext = likesImplement.getLatestContext();
    if (buildContext != null && postId == _membersId) {
      _connectImplements = likesImplement;
      _attachListeners(likesImplement);

      if (startFetching) {
        _startFetching();
      }
    }
    return this;
  }

  void _startFetching() {
    started = true;
    _fetchConnectsLocal();
    _fetchPostOnline();
  }

  List<ConnectData> getLatestData() {
    return _data;
  }

  void _retryListener() {
    restart();
  }

  void _attachListeners(ConnectsImplement commentImplement) {
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
    _connectImplements
        ?.getRetryStreamListener()
        ?.removeListener(_retryListener);
  }

  Future<void> _fetchPostOnline() async {
    if (_membersId == null) {
      return;
    }
    _configure(await _fetchPostConnects(_membersId!));
  }

  Future<List<ConnectData>> _fetchPostConnects(String userId) async {
    final postConnects = await PostOperation().getThisMemberConnects(userId);
    return postConnects
        .map((postConnect) => ConnectData.fromOnline(postConnect))
        .toList();
  }

  Future<List> _fetchRequiredUsers(List<PostgrestMap> allConnects) async {
    return await Future.wait([
      ...(await allConnects
          .asMap()
          .map((key, value) {
            String userId = value[dbReference(Members.id)];
            return MapEntry(key, MembersOperation().userOnlineRecord(userId));
          })
          .values
          .toList())
    ]);
  }

  void _fetchConnectsLocal() async {
    if (_membersId == null) {
      return;
    }
    final savedConnects = await CacheOperation().getCacheData(
        dbReference(Members.connect_database), _membersId!,
        fromWhere: _fromWhere);

    if (savedConnects != null && savedConnects is Map) {
      final allConnects =
          savedConnects.values.map((e) => ConnectData.fromJson(e)).toList();
      _configure(allConnects);
    }
  }

  void updateLatestData(List<ConnectData> allLikes) {
    _data = allLikes;
  }

  void _configure(List<ConnectData> allConnects) {
    updateLatestData(allConnects);
    sendUpdateToUi(allConnects);
    saveLatestConnects();
  }

  void sendUpdateToUi(List<ConnectData> allConnects) {
    if (allConnects.isNotEmpty) {
      state.sendNewState(allConnects);
    }
  }

  Future<void> saveLatestConnects() async {
    if (_data.isNotEmpty) {
      Map mapData = Map.fromIterable(_data,
          key: (element) => element.connectId,
          value: (element) => element.toJson());
      await CacheOperation().saveCacheData(
          dbReference(Members.connect_database), _membersId!, mapData,
          fromWhere: _fromWhere);
    }
  }

  void addConnect(String connectUser, String thisUser,
      {ConnectData? connectData}) {
    if (thisUser.isEmpty || connectUser.isEmpty || _membersId == null) {
      return;
    }
    String connectId =
        dbReference(Members.local) + "(->)" + PostOperation().getUUID();
    ConnectData repost = ConnectData(
        connectId, connectUser, DateTime.now().toString(), thisUser);
    _data.add(connectData ?? repost);
    sendUpdateToUi(_data);
  }

  void removeConnect(String thisUser) {
    int found = _data.indexWhere((element) => element.membersId == thisUser);

    if (found != -1) {
      _data.removeAt(found);
      sendUpdateToUi(_data);
    }
  }
}
