// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:open_document/my_files/init.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/data/NetworkConnectInfo.dart';
import 'package:yabnet/data/ProfessionData.dart';
import 'package:yabnet/data_notifiers/ConnectFieldNotifer.dart';
import 'package:yabnet/operations/MembersOperation.dart';

import '../builders/CustomWrapListBuilder.dart';
import '../data/ConnectInfo.dart';
import '../data/UserConnectsData.dart';
import 'UserConnectsNotifier.dart';

class NetworkConnectsImplement {
  BuildContext? getLatestContext() => null;

  RetryStreamListener? getRetryStreamListener() => null;

  PaginationProgressController? getPaginationProgressController() => null;
}

class NetworkConnectsNotifier {
  WidgetStateNotifier<Map<String, ConnectFieldNotifier>> state =
      WidgetStateNotifier();

  Map<String, ConnectFieldNotifier> _data = {};

  NetworkConnectsImplement? _networkConnectImplements;

  bool started = false;

  List<ConnectInfo>? _userConnects;

  static final NetworkConnectsNotifier instance =
      NetworkConnectsNotifier.internal();

  factory NetworkConnectsNotifier() => instance;

  NetworkConnectsNotifier.internal();

  StreamSubscription? _streamSubscription;

  NetworkConnectsNotifier start(NetworkConnectsImplement likesImplement,
      UserConnectsNotifier userConnectsNotifier,
      {bool startFetching = true}) {
    BuildContext? buildContext = likesImplement.getLatestContext();
    if (buildContext != null) {
      _networkConnectImplements = likesImplement;

      processUserConnect(
          userConnectsNotifier.state.currentValue, startFetching);
      _streamSubscription = userConnectsNotifier.state.stream.listen((event) {
        processUserConnect(event, startFetching);
      });

      _attachListeners(likesImplement);
    }
    return this;
  }

  void processUserConnect(
      UserConnectsData? userConnectsData, bool startFetching) {
    if (userConnectsData != null) {
      int size = _userConnects?.length ?? 0;
      _userConnects = userConnectsData.connection;

      if (_userConnects != null && _userConnects?.length != size ||
          _userConnects != null && _userConnects!.length == 0) {
        if (startFetching) {
          _startFetching();
        }
      }
    }
  }

  void _startFetching() {
    started = true;
    _fetchNetworkConnectsOnline();
  }

  Map<String, ConnectFieldNotifier> getLatestData() {
    return _data;
  }

  List<ConnectInfo>? getUserConnects() {
    return _userConnects;
  }

  void _retryListener() {
    updateConnectField();
    restart();
  }

  void _attachListeners(NetworkConnectsImplement commentImplement) {
    RetryStreamListener? _retryStreamListener =
        commentImplement.getRetryStreamListener();
    _retryStreamListener?.addListener(_retryListener);
  }

  void restart() {
    if (started) {
      _fetchNetworkConnectsOnline();
    }
  }

  void updateConnectField() {
    List<ConnectFieldNotifier> connectFields = [];
    connectFields.addAll(
        _data.map((key, value) => MapEntry(key, value)).values.toList());
    _processConnectField(connectFields, 0);
  }

  void _processConnectField(
      List<ConnectFieldNotifier> connectFields, int currentIndex) {
    if (currentIndex >= 0 && currentIndex <= (connectFields.length - 1)) {
      connectFields[currentIndex].getResponse().then((value) {
        _networkConnectImplements
            ?.getRetryStreamListener()
            ?.refreshStreamController
            .add(RefreshState.refreshComplete);
        _processConnectField(connectFields, currentIndex + 1);
      });
    }
  }

  void stop() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _networkConnectImplements
        ?.getRetryStreamListener()
        ?.removeListener(_retryListener);
  }

  Future<void> _fetchNetworkConnectsOnline() async {
    if (_userConnects == null) return;

    _fetchNetworkConnects();
  }

  void _fetchNetworkConnects() async {
    final allField = await MembersOperation().allFields();

    final fields = allField.map((e) => ProfessionData.fromOnline(e)).toList();
    fetchFieldValues(fields, 0);
  }

  void fetchFieldValues(List<ProfessionData> fields, int index) {
    if (index >= 0 && index <= (fields.length - 1)) {
      _processField(fields[index]).then((value) {
        _networkConnectImplements
            ?.getRetryStreamListener()
            ?.refreshStreamController
            .add(RefreshState.refreshComplete);
        fetchFieldValues(fields, index + 1);
      });
    }
  }

  Future<void> _processField(ProfessionData professionData) async {
    if (!_data.containsKey(professionData.professionTitle)) {
      return updateLatestData(
              professionData,
              ConnectFieldNotifier().attachProfessionField(professionData, this,
                  startFetching: true))
          ?.getResponse();
    }

    return _data[professionData.professionTitle]?.getResponse();
  }

  ConnectFieldNotifier? updateLatestData(
      ProfessionData professionData, ConnectFieldNotifier allConnects) {
    _data[professionData.professionTitle] = allConnects;
    sendUpdateToUi();
    return _data[professionData.professionTitle];
  }

  void sendUpdateToUi() {
    _networkConnectImplements
        ?.getRetryStreamListener()
        ?.refreshStreamController
        .add(RefreshState.refreshComplete);
    state.sendNewState(_data);
  }

  void removeNetworkInfo(NetworkConnectInfo networkConnectInfo) {
    ConnectFieldNotifier? connectFieldNotifier =
        _data[networkConnectInfo.membersField];
    connectFieldNotifier?.removeNetworkInfo(networkConnectInfo);
  }

  void removeThisField(ProfessionData? professionData) {
    if (professionData != null) {
      _data.remove(professionData.professionTitle);
      sendUpdateToUi();
    }
  }
}
