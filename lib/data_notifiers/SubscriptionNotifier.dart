// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/operations/PlansOperation.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../builders/ControlledStreamBuilder.dart';
import '../components/CustomProject.dart';
import '../data/PlanData.dart';
import '../data/SubscriptionsData.dart';
import '../db_references/Plans.dart';
import '../operations/SubscriptionsOperation.dart';

class SubscriptionsStack {
  int? _currentStack;

  int getStack(BuildContext context) {
    _currentStack ??= SubscriptionsNotifier().stack.length;
    return _currentStack!;
  }
}

class SubscriptionsImplement {
  BuildContext? getLatestContext() => null;

  RetryStreamListener? getRetryStreamListener() => null;
}

class SubscriptionsNotifier {
  static final SubscriptionsNotifier instance =
      SubscriptionsNotifier.internal();

  factory SubscriptionsNotifier() => instance;

  SubscriptionsNotifier.internal();

  WidgetStateNotifier<List<SubscriptionData>> state =
      WidgetStateNotifier(currentStateControl: WidgetStateControl.loading);

  List<int> stack = [];
  final List<SubscriptionsImplement> _plansImplement = [];
  List<PlanData> _data = [];
  bool started = false;
  StreamSubscription? _subscriptionStreamSubscription;

  void start(SubscriptionsImplement plansImplement,
      SubscriptionsStack subscriptionsStack) {
    BuildContext? buildContext = plansImplement.getLatestContext();
    if (buildContext != null) {
      _plansImplement.insert(
          subscriptionsStack.getStack(buildContext), plansImplement);
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
      _subscriptionStreamSubscription?.cancel();
      _subscriptionStreamSubscription = null;
      state.sendStateWithControl(WidgetStateControl.loading);
      _fetchPostOnline();
    }
  }

  void _attachListeners(SubscriptionsImplement subscriptionImplement) {
    RetryStreamListener? retryStreamListener =
        subscriptionImplement.getRetryStreamListener();
    retryStreamListener?.addListener(_retryListener);
  }

  void stop(SubscriptionsStack subscriptionsStack) {
    if (subscriptionsStack._currentStack != null) {
      _plansImplement
          .elementAtOrNull(subscriptionsStack._currentStack!)
          ?.getRetryStreamListener()
          ?.removeListener(_retryListener);
      _plansImplement.removeAt(subscriptionsStack._currentStack!);
      _subscriptionStreamSubscription?.cancel();
      _subscriptionStreamSubscription = null;
    }
  }

  void _fetchPostOnline() {
    String? thisUser = SupabaseConfig.client.auth.currentUser?.id;

    if (thisUser == null) {
      return;
    }
    _subscriptionStreamSubscription ??=
        SubscriptionsOperation().getUserSubscription(thisUser).listen((event) {
      _getSubscriptionLinkedData(event);
    });

    _subscriptionStreamSubscription?.onError((e, s) {
      state.sendStateWithControl(WidgetStateControl.error);
      _subscriptionStreamSubscription?.cancel();
      _subscriptionStreamSubscription = null;
    });
  }

  void _fetchPostLocal() {}

  void _getSubscriptionLinkedData(
      List<Map<String, dynamic>> allSubscription) async {
    final plansFuture = allSubscription
        .asMap()
        .map((key, value) {
          return MapEntry(key,
              PlansOperation().getPlanDetails(value[dbReference(Plans.id)]));
        })
        .values
        .toList();

    final planDetails = await Future.wait(plansFuture);

    final subscriptions = allSubscription
        .asMap()
        .map((key, value) {
          final plan = planDetails[key];
          return MapEntry(key, SubscriptionData.fromOnline(value, plan));
        })
        .values
        .toList();

    _configure(subscriptions);
  }

  void updateLatestData(List<PlanData> allPlans) {
    _data = allPlans;
  }

  List<SubscriptionData> _configure(List<SubscriptionData> allSubscriptionData,
      {String? filterText, bool sendUpdate = true}) {
    if (sendUpdate) {
      sendUpdateToUi(allSubscriptionData);
    }

    return allSubscriptionData;
  }

  void sendUpdateToUi(List<SubscriptionData> allSubscription) {
    state.sendNewState(allSubscription.reversed.toList());
  }
}
