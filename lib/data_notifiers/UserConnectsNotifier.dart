// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/data/ConnectInfo.dart';
import 'package:yabnet/operations/MembersOperation.dart';

import '../components/CustomProject.dart';
import '../data/UserConnectsData.dart';
import '../db_references/Connect.dart';
import '../db_references/Members.dart';
import '../operations/CacheOperation.dart';
import '../supabase/SupabaseConfig.dart';

class UserConnectsStack {
  int? currentStack;

  int getStack(BuildContext context) {
    if (currentStack == null) {
      currentStack = UserConnectsNotifier().stack.length;
    }
    return currentStack!;
  }
}

class UserConnectsImplement {
  BuildContext? getLatestContext() => null;

  RetryStreamListener? getRetryStreamListener() => null;
}

class UserConnectsNotifier {
  static final UserConnectsNotifier instance = UserConnectsNotifier.internal();

  factory UserConnectsNotifier() => instance;
  WidgetStateNotifier<UserConnectsData> state = WidgetStateNotifier();

  UserConnectsNotifier.internal();

  List<int> stack = [];
  List<UserConnectsImplement> _userConnectsImplement = [];

  StreamSubscription? _connectStreamSubscription;
  StreamSubscription? _connectionStreamSubscription;

  bool started = false;

  void start(UserConnectsImplement userConnectsImplements,
      UserConnectsStack userConnectsStack) {
    BuildContext? buildContext = userConnectsImplements.getLatestContext();
    if (buildContext != null) {
      _userConnectsImplement.insert(
          userConnectsStack.getStack(buildContext), userConnectsImplements);
      started = true;
      _fetchLocalConnect();
      if (state.currentValue == null) {
        _fetchOnlineConnects(true, true);
      }
    }
  }

  void restart(bool connect, connection) {
    if (started) {
      _connectStreamSubscription?.cancel();
      _connectStreamSubscription = null;
      _connectionStreamSubscription?.cancel();
      _connectionStreamSubscription = null;
      _fetchOnlineConnects(connect, connection);
    }
  }

  Future<void> _fetchLocalConnect() async {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';

    if (thisUser.isEmpty) {
      return;
    }

    final savedLocalConnect = await CacheOperation()
        .getCacheData(dbReference(Members.user_connect), thisUser);

    if (savedLocalConnect != null) {
      final userConnectData = UserConnectsData.fromJson(savedLocalConnect);
      _performUpdate(userConnectData.connects, userConnectData.connection);
    }
  }

  void _fetchOnlineConnects(bool connects, bool connection) {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';

    if (connects) {
      _fetchConnects(thisUser);
    }

    if (connection) {
      _fetchConnection(thisUser);
    }
  }

  void _fetchConnection(String thisUser) {
    _connectionStreamSubscription ??=
        MembersOperation().thisUserConnections(thisUser)?.listen((event) async {
      if (event.isNotEmpty) {
        final userInfoFuture = event
            .map((e) async => await MembersOperation()
                .userOnlineRecord(e[dbReference(Connect.to)]))
            .toList();
        final userInfoResult = await Future.wait(userInfoFuture);
        List<ConnectInfo> connectInfoList =
            userInfoResult.map((e) => ConnectInfo.fromOnline(e)).toList();
        _performUpdate(null, connectInfoList);
      }
    });
  }

  void _fetchConnects(String thisUser) {
    _connectStreamSubscription ??=
        MembersOperation().thisUserConnects(thisUser)?.listen((event) async {
      if (event.isNotEmpty) {
        final userInfoFuture = event
            .map((e) async => await MembersOperation()
                .userOnlineRecord(e[dbReference(Members.id)]))
            .toList();
        final userInfoResult = await Future.wait(userInfoFuture);
        List<ConnectInfo> connectInfoList =
            userInfoResult.map((e) => ConnectInfo.fromOnline(e)).toList();
        _performUpdate(connectInfoList, null);
      }
    });
  }

  void _performUpdate(
      List<ConnectInfo>? connects, List<ConnectInfo>? connection) {
    if (state.currentValue != null &&
        (connects != null || connection != null)) {
      state.sendNewState(state.currentValue?.copyWith(
          connects: connects ?? state.currentValue?.connects,
          connection: connection ?? state.currentValue?.connection));
    } else {
      UserConnectsData userConnectsData =
          UserConnectsData(connects, connection);
      state.sendNewState(userConnectsData);
    }
    ;

    saveLatestConnectData();
  }

  Future<void> saveLatestConnectData() async {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';

    if (state.currentValue != null && thisUser.isNotEmpty) {
      await CacheOperation().saveCacheData(
        dbReference(Members.user_connect),
        thisUser,
        state.currentValue?.toJson(),
      );
    }
  }

  void stop(UserConnectsStack userConnectStack) {
    if (userConnectStack.currentStack != null) {
      _userConnectsImplement.removeAt(userConnectStack.currentStack!);
    }
  }

  void removeConnection(ConnectInfo connectInfo) {
    List<ConnectInfo> connections = state.currentValue?.connection ?? [];

    int found = connections
        .indexWhere((element) => element.membersId == connectInfo.membersId);

    if (found != -1) {
      connections.removeAt(found);
      _performUpdate(null, connections);
    }
  }

  void removeConnect(ConnectInfo connectInfo) {
    List<ConnectInfo> connect = state.currentValue?.connects ?? [];

    int found = connect
        .indexWhere((element) => element.membersId == connectInfo.membersId);

    if (found != -1) {
      connect.removeAt(found);
      _performUpdate(connect, null);
    }
  }
}
