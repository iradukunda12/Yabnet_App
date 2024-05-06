// ignore_for_file: constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/data/UserData.dart';
import 'package:yabnet/operations/MembersOperation.dart';

class ProfileStack {
  int? _currentStack;

  int getStack(BuildContext context) {
    if (_currentStack == null) {
      _currentStack = ProfileNotifier().stack.length;
    }
    return _currentStack!;
  }
}

class ProfileImplement {
  BuildContext? getLatestContext() => null;
}

class ProfileNotifier {
  static final ProfileNotifier instance = ProfileNotifier.internal();

  factory ProfileNotifier() => instance;
  WidgetStateNotifier<UserData> state = WidgetStateNotifier();

  ProfileNotifier.internal();

  List<int> stack = [];
  List<ProfileImplement> _profileImplement = [];

  Future<void> start(
      ProfileImplement profileImplement, ProfileStack profileStack) async {
    BuildContext? buildContext = profileImplement.getLatestContext();
    if (buildContext != null) {
      _profileImplement.insert(
          profileStack.getStack(buildContext), profileImplement);
      _getData();
      (await MembersOperation().listenable())?.addListener(_profileListener);
    }
  }

  Future<void> stop(ProfileStack profileStack) async {
    (await MembersOperation().listenable())?.removeListener(_profileListener);
    if (profileStack._currentStack != null) {
      _profileImplement.removeAt(profileStack._currentStack!);
    }
  }

  void _profileListener() {
    _getData();
  }

  void _getData() async {
    dynamic userRecord = await MembersOperation().getUserRecord();
    if (userRecord != null && userRecord is Map) {
      UserData userData = UserData.fromOnlineData(userRecord);
      state.sendNewState(userData);
    }
  }
}
