import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';

import '../components/CustomProject.dart';

enum RefreshState {
  refreshing,
  refreshComplete,
  refreshError,
}

class RetryStreamListener extends ChangeNotifier {
  bool retrying = false;
  bool forced = false;

  Timer? _requestControl;
  bool _performAction = true;

  StreamController<RefreshState> refreshStreamController =
      StreamController<RefreshState>.broadcast();

  void autoRetryMethod(
      {Function()? action, bool forcedRetry = false, bool notified = true}) {
    if (retrying == false) {
      refreshStreamController.add(RefreshState.refreshing);
      startRetrying(forcedRetry: forcedRetry);
      action?.call();
      stopRetry(notified: notified);
    }
  }

  void stopRetry({bool notified = true}) {
    retrying = false;
    forced = false;
    if (notified) {
      notifyListeners();
    }
  }

  void startRetrying({bool forcedRetry = false}) {
    retrying = true;
    forced = forcedRetry;
    notifyListeners();
  }

  void sendForcedRetry({bool forcedRetry = true}) {
    forced = forcedRetry;
    notifyListeners();
  }

  void controlRequestCall(Duration duration, Function() action) {
    if (_performAction) {
      action.call();
      _performAction = false;
    }
    _requestControl ??= Timer(duration, () {
      _performAction = true;
      _requestControl?.cancel();
      _requestControl = null;
    });
  }
}

typedef AsyncControlledStreamBuilder<A> = Widget Function(
    BuildContext context, ControlledStreamSnapshot<A> autoSnapshot);

enum ControlledStreamResult {
  waiting,
  noConnection,
  hasData,
  none,
  done,
  forcedRetry
}

class ControlledStreamSnapshot<T> {
  final ControlledStreamResult result;
  final T? data;

  bool get isDone => result == ControlledStreamResult.done;

  bool get isNone => result == ControlledStreamResult.none;

  bool get hasData => result == ControlledStreamResult.hasData;

  bool get forcedRetry => result == ControlledStreamResult.forcedRetry;

  bool get noConnection => result == ControlledStreamResult.noConnection;

  bool get isWaiting => result == ControlledStreamResult.waiting;

  bool get nullData => data == null;

  ControlledStreamSnapshot(this.result, this.data);
}

typedef ControlledStreamProvider<A> = Stream<A>? Function(BuildContext context);

class ControlledStreamBuilder<T> extends StatefulWidget {
  final T? initialData;
  final String? identity;
  final bool? networkChange;
  final Duration timeOutWhen;
  final RetryStreamListener? retryStreamListener;
  final ControlledStreamProvider<T>? streamProvider;
  final AsyncControlledStreamBuilder<T?> builder;

  const ControlledStreamBuilder({
    super.key,
    this.initialData,
    this.identity,
    this.timeOutWhen = const Duration(minutes: 1),
    this.retryStreamListener,
    required this.streamProvider,
    required this.builder,
    this.networkChange,
  });

  @override
  State<ControlledStreamBuilder<T>> createState() =>
      _ControlledStreamBuilderState<T>();
}

class _ControlledStreamBuilderState<T> extends State<ControlledStreamBuilder<T>>
    with WidgetsBindingObserver {
  bool errorOccurredForData = false;
  bool alreadyDone = false;
  ControlledStreamSnapshot<T?> value =
      ControlledStreamSnapshot(ControlledStreamResult.waiting, null);
  StreamSubscription<T?>? streamSubscription;
  StreamSubscription<ConnectivityResult>? connectionSubscription;
  Timer? timer;
  bool anyData = false;
  WidgetStateNotifier<ControlledStreamSnapshot<T?>> widgetStateNotifier =
      WidgetStateNotifier();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && errorOccurredForData ||
        state == AppLifecycleState.resumed && alreadyDone ||
        streamSubscription?.isPaused == true) {
      endStream();

      if (value.hasData) {
        widgetStateNotifier.sendNewState(value);
      } else {
        value = ControlledStreamSnapshot(ControlledStreamResult.waiting, null);
        widgetStateNotifier.sendNewState(value);
      }
      checkStream();
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    if (widget.initialData != null) {
      value = ControlledStreamSnapshot(
          ControlledStreamResult.hasData, widget.initialData);
      widgetStateNotifier.sendNewState(value);
    }
    checkStream();
    connectionSubscription =
        Connectivity().onConnectivityChanged.listen(onConnectionChanged);

    try {
      widget.retryStreamListener?.addListener(retryListener);
    } catch (e) {
      null;
    }
  }

  void retryListener() {
    if (widget.retryStreamListener?.retrying == true) {
      endStream();
      widget.retryStreamListener?.refreshStreamController
          .add(RefreshState.refreshing);

      if (widget.retryStreamListener?.forced == false) {
        value = ControlledStreamSnapshot(ControlledStreamResult.waiting, null);
      } else {
        value =
            ControlledStreamSnapshot(ControlledStreamResult.forcedRetry, null);
      }
      widgetStateNotifier.sendNewState(value);
      checkStream();
      widget.retryStreamListener?.stopRetry(notified: false);
    }
  }

  @override
  void didUpdateWidget(covariant ControlledStreamBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamProvider != widget.streamProvider) {
      anyData = anyData;
      endStream();
      widgetStateNotifier.sendNewState(
          ControlledStreamSnapshot(ControlledStreamResult.none, null));
      widgetStateNotifier.sendNewState(value);
      checkStream();
    }
  }

  void onConnectionChanged(ConnectivityResult result) {
    if (result != ConnectivityResult.none &&
            errorOccurredForData &&
            (widget.networkChange == true) ||
        result != ConnectivityResult.none &&
            alreadyDone &&
            (widget.networkChange == true)) {
      endStream();
      value = ControlledStreamSnapshot(ControlledStreamResult.waiting, null);
      widgetStateNotifier.sendNewState(value);
      checkStream();
    }
  }

  void endStream() {
    widget.retryStreamListener?.refreshStreamController
        .add(RefreshState.refreshComplete);
    streamSubscription?.cancel();
    streamSubscription = null;
    alreadyDone = false;
    timer?.cancel();
    timer = null;
  }

  void checkStream() {
    errorOccurredForData = false;

    if (streamSubscription == null &&
        widget.streamProvider != null &&
        mounted) {
      streamSubscription =
          widget.streamProvider!(context)?.listen(onListen, onDone: onDone);

      timer ??= Timer(widget.timeOutWhen, () {
        timer?.cancel();
        timer = null;
        widget.retryStreamListener?.refreshStreamController
            .add(RefreshState.refreshComplete);
        if (!anyData && !value.hasData) {
          endStream();
          onError();
          showDebug(
              msg:
                  "${widget.identity != null ? "${widget.identity} " : ""}Exited with a timeout");
        } else {
          widget.retryStreamListener?.refreshStreamController
              .add(RefreshState.refreshComplete);
        }
      });

      streamSubscription?.onError((Object error, stackTrace) {
        showDebug(msg: "$error $stackTrace");
        onError();
      });
    } else {
      widget.retryStreamListener?.refreshStreamController
          .add(RefreshState.refreshComplete);
    }
  }

  void onError() {
    widget.retryStreamListener?.refreshStreamController
        .add(RefreshState.refreshComplete);
    try {
      errorOccurredForData = true;
      if (!value.hasData) {
        value =
            ControlledStreamSnapshot(ControlledStreamResult.noConnection, null);
      }
      widgetStateNotifier.sendNewState(value);
    } catch (error, stackTrace) {
      null;
      showDebug(msg: "$error $stackTrace");
    }
    endStream();
  }

  void onDone() {
    widget.retryStreamListener?.refreshStreamController
        .add(RefreshState.refreshComplete);
    try {
      alreadyDone = true;
      value = ControlledStreamSnapshot(ControlledStreamResult.done, null);
      widgetStateNotifier.sendNewState(value);
    } catch (error, stackTrace) {
      null;
      showDebug(msg: "$error $stackTrace");
    }
    endStream();
  }

  void onListen(T? event) {
    widget.retryStreamListener?.refreshStreamController
        .add(RefreshState.refreshComplete);
    try {
      errorOccurredForData = false;
      alreadyDone = false;
      anyData = true;
      value = ControlledStreamSnapshot(ControlledStreamResult.hasData, event);
      widgetStateNotifier.sendNewState(value);
    } catch (error, stackTrace) {
      null;
      showDebug(msg: "$error $stackTrace");
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    connectionSubscription?.cancel();
    streamSubscription?.cancel();
    connectionSubscription = null;
    streamSubscription = null;
    timer?.cancel();
    timer = null;
    widget.retryStreamListener?.removeListener(retryListener);
  }

  @override
  Widget build(BuildContext context) {
    return WidgetStateConsumer<ControlledStreamSnapshot<T?>?>(
        widgetStateNotifier: widgetStateNotifier,
        widgetStateBuilder: (context, snapshot) {
          return widget.builder(context, snapshot ?? value);
        });
  }
}
