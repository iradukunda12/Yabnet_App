import 'package:flutter/cupertino.dart';

import '../builders/AutoReconnectFutureBuilder.dart';

typedef DisplayRepositoryDataBuilder<A> = Widget Function(A? data);
typedef ConfigureRepositoryDataBuilder<A> = Widget Function(
    CustomRepositoryBuilder<A?> respositoryBuilder,
    LatestDataNotifier<A?> latestDataNotifier);
typedef InitialRepositoryDataBuilder<A> = Future<A?> Function(
    BuildContext context);
typedef OnlineRepositoryBuilder<T> = Widget Function(
    BuildContext context,
    CustomRepositoryBuilder<T?> respositoryBuilder,
    LatestDataNotifier<T?> latestDataNotifier);

class CustomRepositoryImplement<A> {
  InitialRepositoryDataBuilder<A?>? initialRepositoryDataBuilder() {
    return null;
  }

  DisplayRepositoryDataBuilder<A?>? displayRepositoryDataBuilder() {
    return null;
  }

  ConfigureRepositoryDataBuilder<A?>? configureRepositoryDataBuilder<A>() {
    return null;
  }

  OnlineRepositoryBuilder<A?>? onlineBuilder() {
    return null;
  }
}

class LatestDataNotifier<B> extends ChangeNotifier {
  int afterInitialValue = 0;
  B? getLatest;
  B? initialData;

  AutoFutureResult futureResult = AutoFutureResult.waiting;

  B? getLatestAfterInitial({
    int after = 0,
  }) {
    if (afterInitialValue > after) {
      afterInitialValue++;
      return getLatest;
    } else if (afterInitialValue == after) {
      afterInitialValue++;
      getLatest = getLatest;
      return getLatest;
    } else {
      afterInitialValue++;
      return initialData;
    }
  }

  void setLatest(B? value) {
    getLatest = value;
    notifyListeners();
  }

  void setFutureResult(AutoFutureResult result) {
    futureResult = result;
    notifyListeners();
  }

  void clearLatest() {
    getLatest = null;
    notifyListeners();
  }

  void initializeData(B? value) {
    initialData ??= value;
  }
}

class CustomRepositoryBuilder<A> extends StatefulWidget {
  final InitialRepositoryDataBuilder<A?> initialRepositoryDataBuilder;
  final DisplayRepositoryDataBuilder<A?> displayRepositoryDataBuilder;
  final ConfigureRepositoryDataBuilder<A?>? configureRepositoryDataBuilder;
  final OnlineRepositoryBuilder<A?> onlineBuilder;

  const CustomRepositoryBuilder({
    super.key,
    required this.initialRepositoryDataBuilder,
    this.configureRepositoryDataBuilder,
    required this.displayRepositoryDataBuilder,
    required this.onlineBuilder,
  });

  @override
  State<CustomRepositoryBuilder<A?>> createState() =>
      _CustomRepositoryBuilderState<A?>();
}

class _CustomRepositoryBuilderState<T>
    extends State<CustomRepositoryBuilder<T?>> {
  LatestDataNotifier<T?> latestDataNotifier = LatestDataNotifier();
  bool? alreadyInitial;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    latestDataNotifier.setLatest(null);
    latestDataNotifier.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoReconnectFutureBuilder<T?>(
        autoFuture: widget.initialRepositoryDataBuilder(context),
        builder: (context, future) {
          if (future.data != null) {
            alreadyInitial = true;
          }

          if (alreadyInitial == true) {
            alreadyInitial = false;
            latestDataNotifier.initializeData(future.data);
            latestDataNotifier.setLatest(future.data);
            latestDataNotifier.setFutureResult(AutoFutureResult.hasData);
          } else if (alreadyInitial == null) {
            latestDataNotifier.setFutureResult(future.result);
          }

          return widget.onlineBuilder(context, widget, latestDataNotifier);
        });
  }
}
