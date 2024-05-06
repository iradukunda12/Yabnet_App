import 'dart:async';

import 'package:flutter/cupertino.dart';

class LocalNavigationController {
  static final LocalNavigationController instance =
      LocalNavigationController.internal();

  factory LocalNavigationController() => instance;

  LocalNavigationController.internal();

  StreamController<GlobalKey<NavigatorState>> sendNavigatorController =
      StreamController<GlobalKey<NavigatorState>>.broadcast();
  NavigatorState? getNavigator;

  void addNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    try {
      sendNavigatorController.add(navigatorKey);
    } catch (e) {
      null;
    }
  }

  static GlobalKey<NavigatorState> useNavigatorKey =
      GlobalKey<NavigatorState>();

  void onUseNavigatorKey(Function(NavigatorState?) navigatorStateFunction,
      {Duration waitTime = const Duration(seconds: 5)}) async {
    if (useNavigatorKey.currentContext == null) {
      StreamSubscription? streamSubscription;
      streamSubscription = sendNavigatorController.stream
          .timeout(waitTime)
          .listen((navigatorStream) {
        if (navigatorStream.currentContext != null) {
          getNavigator = Navigator.of(navigatorStream.currentContext!);
          navigatorStateFunction(getNavigator);
          streamSubscription?.cancel();
          streamSubscription = null;
        }
      });

      streamSubscription?.onError((error, stackTrace) {
        navigatorStateFunction(getNavigator);
        streamSubscription?.cancel();
        streamSubscription = null;
      });
    } else {
      getNavigator = Navigator.of(useNavigatorKey.currentContext!);
      navigatorStateFunction(getNavigator);
    }
  }
}
