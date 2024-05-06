// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/operations/PlansOperation.dart';

import '../builders/ControlledStreamBuilder.dart';
import '../data/PlanData.dart';

class PlansStack {
  int? _currentStack;

  int getStack(BuildContext context) {
    _currentStack ??= PlansNotifier().stack.length;
    return _currentStack!;
  }
}

class PlansImplement {
  BuildContext? getLatestContext() => null;

  RetryStreamListener? getRetryStreamListener() => null;
}

class PlansNotifier {
  static final PlansNotifier instance = PlansNotifier.internal();

  factory PlansNotifier() => instance;

  PlansNotifier.internal();

  WidgetStateNotifier<List<PlanData>> state =
      WidgetStateNotifier(currentStateControl: WidgetStateControl.loading);

  List<int> stack = [];
  final List<PlansImplement> _plansImplement = [];
  List<PlanData> _data = [];
  bool started = false;
  StreamSubscription? _plansStreamSubscription;

  void start(PlansImplement plansImplement, PlansStack plansStack) {
    BuildContext? buildContext = plansImplement.getLatestContext();
    if (buildContext != null) {
      _plansImplement.insert(plansStack.getStack(buildContext), plansImplement);
      started = true;
      _attachListeners(plansImplement);
      _fetchPostLocal();
      _fetchPostOnline();
    }
  }

  void _retryListener() {
    restart();
  }

  void restart() {
    if (started) {
      _plansStreamSubscription?.cancel();
      _plansStreamSubscription = null;
      state.sendStateWithControl(WidgetStateControl.loading);
      _fetchPostOnline();
    }
  }

  void _attachListeners(PlansImplement plansImplement) {
    RetryStreamListener? retryStreamListener =
        plansImplement.getRetryStreamListener();
    retryStreamListener?.addListener(_retryListener);
  }

  void stop(PlansStack planStack) {
    if (planStack._currentStack != null) {
      _plansImplement
          .elementAtOrNull(planStack._currentStack!)
          ?.getRetryStreamListener()
          ?.removeListener(_retryListener);
      _plansImplement.removeAt(planStack._currentStack!);
      _plansStreamSubscription?.cancel();
      _plansStreamSubscription = null;
    }
  }

  void _fetchPostOnline() {
    _plansStreamSubscription ??= PlansOperation().getAllPlans().listen((event) {
      _getPlanLinkedData(event);
    });

    _plansStreamSubscription?.onError((e, s) {
      state.sendStateWithControl(WidgetStateControl.error);
      _plansStreamSubscription?.cancel();
      _plansStreamSubscription = null;
    });
  }

  void _fetchPostLocal() {}

  void _getPlanLinkedData(List<Map<String, dynamic>> allPlan) async {
    final plans = allPlan
        .asMap()
        .map((key, value) {
          return MapEntry(key, PlanData.fromOnline(value));
        })
        .values
        .toList();

    _configure(plans);
  }

  void updateLatestData(List<PlanData> allPlans) {
    _data = allPlans;
  }

  List<PlanData> _configure(List<PlanData> allPlans,
      {String? filterText, bool sendUpdate = true}) {
    if (sendUpdate) {
      sendUpdateToUi(allPlans);
    }

    return allPlans;
  }

  void sendUpdateToUi(List<PlanData> allPlan) {
    state.sendNewState(allPlan.reversed.toList());
  }
}
