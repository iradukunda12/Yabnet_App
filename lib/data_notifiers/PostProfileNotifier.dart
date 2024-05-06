// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:open_document/my_files/init.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/data/UserData.dart';
import 'package:yabnet/data_notifiers/ProfileNotifier.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../builders/CustomWrapListBuilder.dart';
import '../components/CustomProject.dart';
import '../data/PostProfileData.dart';
import '../db_references/Likes.dart';
import '../operations/CacheOperation.dart';

class PostProfileImplement {
  BuildContext? getLatestContext() => null;

  RetryStreamListener? getRetryStreamListener() => null;

  PaginationProgressController? getPaginationProgressController() => null;
}

class PostProfileNotifier {
  WidgetStateNotifier<PostProfileData> state = WidgetStateNotifier();

  PostProfileData? _data;

  PostProfileImplement? _postProfileImplement;

  bool started = false;

  String? _memberId;
  String? _fromWhere;

  StreamSubscription? profileStreamSubscription;
  StreamSubscription? userStreamSubscription;

  PostProfileNotifier attachMembersId(String postId, String? fromWhere,
      {bool startFetching = false}) {
    _memberId = postId;
    _fromWhere = fromWhere;
    if (startFetching) {
      _startFetching();
    }
    return this;
  }

  PostProfileNotifier start(
      PostProfileImplement postProfileImplement, String postId,
      {bool startFetching = true}) {
    BuildContext? buildContext = postProfileImplement.getLatestContext();
    if (buildContext != null && postId == _memberId) {
      _postProfileImplement = postProfileImplement;
      _attachListeners(postProfileImplement);
      if (startFetching) {
        _startFetching();
      }
    }
    return this;
  }

  void _startFetching() {
    started = true;

    if (!forThisUser()) {
      _fetchLocalPostProfile();
      _fetchPostProfileOnline();
    }
  }

  bool forThisUser() {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';

    if (thisUser.isNotEmpty && _memberId == thisUser) {
      UserData? userData = ProfileNotifier().state.currentValue;
      if (userData != null) {
        _configure(PostProfileData.fromJson(userData.toJson()), true);
        userStreamSubscription ??=
            ProfileNotifier().state.stream.listen((event) {
          if (event != null) {
            _configure(PostProfileData.fromJson(event.toJson()), true);
          }
        });
      }
      return true;
    }
    return false;
  }

  PostProfileData? getLatestData() {
    return _data;
  }

  void _retryListener() {
    restart();
  }

  void _attachListeners(PostProfileImplement commentImplement) {
    RetryStreamListener? _retryStreamListener =
        commentImplement.getRetryStreamListener();
    _retryStreamListener?.addListener(_retryListener);
  }

  void restart() {
    if (started) {
      _fetchPostProfileOnline();
    }
  }

  void endSubscription() {
    profileStreamSubscription?.cancel();
    profileStreamSubscription = null;
    userStreamSubscription?.cancel();
    userStreamSubscription = null;
  }

  void stop() {
    endSubscription();
    _postProfileImplement
        ?.getRetryStreamListener()
        ?.removeListener(_retryListener);
  }

  Future<void> _fetchPostProfileOnline() async {
    if (_memberId == null) {
      return;
    }

    await profileStreamSubscription?.cancel();
    profileStreamSubscription = null;
    profileStreamSubscription = MembersOperation()
        .userOnlineRecordStream(_memberId!)
        .listen((userRecord) {
      if (userRecord.singleOrNull != null) {
        _configure(PostProfileData.fromOnlineData(userRecord.single), false);
      }
    });
  }

  void _fetchLocalPostProfile() async {
    if (_memberId == null) {
      return;
    }
    final savedPostProfileData = await CacheOperation().getCacheData(
        dbReference(Likes.post_profile_database), _memberId!,
        fromWhere: _fromWhere);

    if (savedPostProfileData != null) {
      final postProfileData = PostProfileData.fromJson(savedPostProfileData);
      _configure(postProfileData, false);
    }
  }

  void updateLatestData(PostProfileData postProfileData) {
    _data = postProfileData;
  }

  void _configure(PostProfileData postProfileData, bool userData) {
    updateLatestData(postProfileData);
    sendUpdateToUi(postProfileData);

    if (!userData) {
      saveLatestPostProfile();
    }
  }

  void sendUpdateToUi(PostProfileData postProfileData) {
    state.sendNewState(postProfileData);
  }

  Future<void> saveLatestPostProfile() async {
    if (_data != null) {
      await CacheOperation().saveCacheData(
          dbReference(Likes.post_profile_database), _memberId!, _data?.toJson(),
          fromWhere: _fromWhere);
    }
  }
}
