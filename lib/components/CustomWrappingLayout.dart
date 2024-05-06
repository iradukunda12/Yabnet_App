import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';

import 'SizeReportingWidget.dart';

class CustomWrappingLayout extends StatefulWidget {
  final double minHeight;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final List<WLView> wlChildren;

  const CustomWrappingLayout(
      {super.key,
      required this.wlChildren,
      this.mainAxisAlignment = MainAxisAlignment.start,
      this.textDirection,
      this.textBaseline,
      this.mainAxisSize = MainAxisSize.max,
      this.crossAxisAlignment = CrossAxisAlignment.center,
      this.verticalDirection = VerticalDirection.down,
      this.minHeight = 100.0});

  @override
  State<CustomWrappingLayout> createState() => _CustomWrappingLayoutState();
}

class _CustomWrappingLayoutState extends State<CustomWrappingLayout>
    with WidgetsBindingObserver {
  double parentHeight = 100;
  bool rebuild = false;
  WidgetStateNotifier<bool> rebuildNotifier =
      WidgetStateNotifier(currentValue: false);
  WidgetStateNotifier<double> parentHeightNotifier =
      WidgetStateNotifier(currentValue: 100);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    parentHeight = widget.minHeight > 0 ? widget.minHeight : parentHeight;
    parentHeightNotifier.sendNewState(parentHeight);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      parentHeight = widget.minHeight > 0 ? widget.minHeight : parentHeight;
      parentHeightNotifier.sendNewState(parentHeight);
      rebuild = true;
      rebuildNotifier.sendNewState(rebuild);
      rebuild = false;
      rebuildNotifier.sendNewState(rebuild);
    }
  }

  @override
  void didUpdateWidget(covariant CustomWrappingLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    parentHeight = widget.minHeight > 0 ? widget.minHeight : parentHeight;
    parentHeightNotifier.sendNewState(parentHeight);
    rebuild = true;
    rebuildNotifier.sendNewState(rebuild);
    rebuild = false;
    rebuildNotifier.sendNewState(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    return SizeReportingWidget(
      onSizeChange: (Size size) {
        parentHeight = size.height;
        parentHeightNotifier.sendNewState(parentHeight);
      },
      child: WidgetStateConsumer(
          widgetStateNotifier: rebuildNotifier,
          widgetStateBuilder: (context, data) {
            return Row(
              key: widget.key,
              mainAxisSize: widget.mainAxisSize,
              mainAxisAlignment: widget.mainAxisAlignment,
              crossAxisAlignment: widget.crossAxisAlignment,
              textBaseline: widget.textBaseline,
              textDirection: widget.textDirection,
              verticalDirection: widget.verticalDirection,
              children: (data ?? rebuild) == false ? wlChildren : [],
            );
          }),
    );
  }

  Widget getTheChild(WLView wlView, int index) {
    if (wlView.crossDimension == WlDimension.match &&
        parentHeight != 0.0 &&
        !wlView.expandMain) {
      return SingleChildScrollView(
        child: SizedBox(
          height: parentHeight,
          child: wlView.child,
        ),
      );
    } else if (wlView.crossDimension == WlDimension.match &&
        parentHeight != 0.0 &&
        wlView.expandMain) {
      return Expanded(
        child: SizedBox(
          height: parentHeight,
          child: wlView.child,
        ),
      );
    } else if (wlView.expandMain) {
      return Expanded(child: wlView.child);
    } else {
      return wlView.child;
    }
  }

  List<Widget> get wlChildren => widget.wlChildren
      .asMap()
      .map((index, wlView) => MapEntry(
          index,
          StreamBuilder(
              initialData: parentHeightNotifier.currentValue,
              stream: parentHeightNotifier.stream,
              builder: (context, snapshot) {
                return getTheChild(wlView, index);
              })))
      .values
      .toList();
}

enum WlDimension { wrap, match }

class WLView {
  final WlDimension? crossDimension;
  final bool expandMain;
  final Widget child;

  WLView({this.crossDimension, required this.child, this.expandMain = false});
}
