import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/SizeReportingWidget.dart';

import '../builders/ControlledStreamBuilder.dart';
import '../components/CustomProject.dart';

typedef WrapListBuilder<A> = Widget Function(BuildContext context, int index);

enum WrapEdgePosition { reserveBottom, normalTop, reserveTop, normalBottom }

class PaginationProgressController extends WidgetStateNotifier {}

class PaginationProgressStyle {
  final EdgeInsets padding;
  final double scrollThreshold;
  final bool useDefaultTimeOut;
  final Duration progressMaxDuration;

  PaginationProgressStyle(
      {this.padding = const EdgeInsets.all(8),
      this.useDefaultTimeOut = true,
      this.scrollThreshold = 0,
      this.progressMaxDuration = const Duration(milliseconds: 500)});
}

class CustomWrapListBuilder extends StatefulWidget {
  final int? itemCount;
  final bool reverse;
  final bool sliver;
  final bool shrinkWrap;
  final bool injector;
  final bool alwaysPaginating;
  final WrapListBuilder wrapListBuilder;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final int? paginateSize;
  final ScrollPhysics? physics;
  final TextDirection? textDirection;
  final CrossAxisAlignment crossAxisAlignment;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final PaginationProgressStyle? paginationProgressStyle;
  final PaginationProgressController? paginationProgressController;
  final ValueChanged<WrapEdgePosition>? wrapEdgePosition;
  final Function(int? currentSize, int? nextPaginate)? paginationSizeChanged;
  final ValueChanged<ScrollDirection>? wrapScrollDirection;
  final RetryStreamListener? retryStreamListener;
  final ScrollController? scrollController;
  final Widget? topPaginateWidget;
  final Widget? bottomPaginateWidget;

  const CustomWrapListBuilder({
    super.key,
    required this.itemCount,
    this.mainAxisSize = MainAxisSize.min,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textBaseline,
    this.verticalDirection = VerticalDirection.down,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.textDirection,
    this.reverse = false,
    this.sliver = false,
    this.shrinkWrap = true,
    this.retryStreamListener,
    this.wrapEdgePosition,
    this.paginationProgressStyle,
    this.paginationProgressController,
    this.paginateSize,
    this.wrapScrollDirection,
    required this.wrapListBuilder,
    this.scrollController,
    this.paginationSizeChanged,
    this.physics,
    this.topPaginateWidget,
    this.bottomPaginateWidget,
    this.alwaysPaginating = false,
    this.injector = true,
  });

  @override
  State<CustomWrapListBuilder> createState() => _CustomWrapListBuilderState();
}

class _CustomWrapListBuilderState extends State<CustomWrapListBuilder> {
  List<Widget> builders = [];
  int paginate = 0;
  WidgetStateNotifier<int> paginateSize = WidgetStateNotifier();

  PaginationProgressStyle get getPaginationProgressStyle =>
      widget.paginationProgressStyle ?? PaginationProgressStyle();
  bool loading = false;
  Timer? progressDefaultTimer;
  StreamSubscription? paginationSubscription;

  @override
  void dispose() {
    super.dispose();
    paginationSubscription?.cancel();
    paginationSubscription = null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.paginateSize != null) {
      paginate += widget.paginateSize ?? 0;
    } else {
      paginate = widget.itemCount ?? 0;
    }
    paginateSize.sendNewState(paginate);
    widget.paginationProgressController?.stream.listen((event) {
      if (widget.paginationProgressController?.currentValue == false) {
        loading = false;
      }
      progressDefaultTimer?.cancel();
      progressDefaultTimer = null;
      progressDefaultTimer ??=
          Timer(getPaginationProgressStyle.progressMaxDuration, () {
        if (widget.paginationProgressController != null &&
            widget.paginationProgressStyle?.useDefaultTimeOut == true) {
          widget.paginationProgressController?.sendNewState(false);
        }
        loading = false;
        progressDefaultTimer?.cancel();
        progressDefaultTimer = null;
      });
    });

    paginationSubscription = paginateSize.stream.listen((event) {
      if (widget.paginationSizeChanged != null) {
        widget.paginationSizeChanged!(widget.itemCount, event ?? paginate);
      }
    });
  }

  bool handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      sendScrollDirection(notification.metrics.axisDirection);
      checkEndOfList(notification.metrics, notification.metrics.axisDirection,
          notification.scrollDelta,
          threshold: getPaginationProgressStyle.scrollThreshold);
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant CustomWrapListBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.paginateSize == null &&
        widget.itemCount != oldWidget.itemCount) {
      paginate = widget.itemCount ?? 0;
      paginateSize.sendNewState(paginate);
    }

    if ((widget.paginateSize ?? 0) < 0) {
      paginate = widget.paginateSize ?? 0;
      paginateSize.sendNewState(paginate);
    }
  }

  void checkCanPaginate() {
    int itemSize = widget.itemCount ?? 0;

    if (!loading && widget.alwaysPaginating) {
      widget.paginationProgressController?.sendNewState(true);
      loading = true;
    }

    if (widget.paginateSize != null && itemSize <= paginate && itemSize > 0) {
      if (((paginate + (widget.paginateSize ?? 0)) - itemSize) <=
          (widget.paginateSize ?? 0)) {
        if (!loading && !widget.alwaysPaginating) {
          widget.paginationProgressController?.sendNewState(true);
          loading = true;
        }
        paginate += widget.paginateSize ?? 0;
        paginateSize.sendNewState(paginate);
      }
    } else if (widget.paginateSize != null &&
        itemSize > paginate &&
        itemSize > 0) {
      if (!loading && !widget.alwaysPaginating) {
        widget.paginationProgressController?.sendNewState(true);
        loading = true;
      }
      paginate += widget.paginateSize ?? 0;
      paginateSize.sendNewState(paginate);
    }
  }

  void sendScrollDirection(AxisDirection axisDirection) {
    if (widget.wrapScrollDirection == null) {
      return;
    }
    ScrollDirection scrollDirection = switch (axisDirection) {
      AxisDirection.up => ScrollDirection.forward,
      AxisDirection.right => ScrollDirection.forward,
      AxisDirection.down => ScrollDirection.reverse,
      AxisDirection.left => ScrollDirection.reverse,
    };

    widget.wrapScrollDirection!(scrollDirection);
  }

  void endOfList(
    ScrollMetrics metrics,
  ) {
    if (widget.wrapEdgePosition == null) {
      return;
    }
    double pixels = metrics.pixels;
    double maxScroll = metrics.maxScrollExtent;

    if (pixels == 0) {
      if (widget.reverse) {
        checkCanPaginate();
        widget.wrapEdgePosition!(WrapEdgePosition.reserveBottom);
      } else {
        widget.wrapEdgePosition!(WrapEdgePosition.normalTop);
      }
    } else if (metrics.atEdge && pixels != 0) {
      if (widget.reverse) {
        widget.wrapEdgePosition!(WrapEdgePosition.reserveTop);
      } else {
        checkCanPaginate();
        widget.wrapEdgePosition!(WrapEdgePosition.normalBottom);
      }
    }
  }

  bool canShow = true;

  void checkEndOfList(
      ScrollMetrics metrics, AxisDirection axisDirection, double? scrollDelta,
      {double threshold = 0}) {
    if (widget.wrapEdgePosition == null) {
      return;
    }

    double pixels = metrics.pixels;
    double maxScroll = metrics.maxScrollExtent;

    if (threshold != 0) {
      if (pixels <= threshold && canShow) {
        if (widget.reverse && (scrollDelta ?? 0) < 0) {
          checkCanPaginate();
          canShow = false;
          widget.wrapEdgePosition!(WrapEdgePosition.reserveBottom);
        } else {
          widget.wrapEdgePosition!(WrapEdgePosition.normalTop);
        }
      } else if (pixels >= (maxScroll - threshold)) {
        if (widget.reverse) {
          widget.wrapEdgePosition!(WrapEdgePosition.reserveTop);
        } else if ((scrollDelta ?? 0) > 0 && canShow) {
          checkCanPaginate();
          canShow = false;
          widget.wrapEdgePosition!(WrapEdgePosition.normalBottom);
        }
      } else {
        canShow = true;
      }
    } else {
      endOfList(metrics);
    }
  }

  Widget scrollViewIndicator() {
    return Center(
        child: Padding(
      padding: getPaginationProgressStyle.padding,
      child: progressBarWidget(),
    ));
  }

  int getItemCount(int paginate) {
    int itemCount = widget.itemCount ?? 0;
    if (paginate > itemCount) {
      return itemCount;
    } else {
      return paginate;
    }
  }

  Map<int, Size> childSizes = {};

  List<Widget> getBuilders(int paginate) {
    int itemCount = getItemCount(paginate);
    childSizes.clear();
    final getBuilders = widget.reverse
        ? [
            for (var index = 0; index < itemCount; index++)
              Builder(builder: (context) {
                return widget.wrapListBuilder(context, itemCount - (index + 1));
              })
          ]
        : [
            for (var index = 0; index < itemCount; index++)
              Builder(builder: (context) {
                return widget.wrapListBuilder(context, index);
              })
          ];
    return getBuilders
        .asMap()
        .map((key, child) {
          return MapEntry(
              key,
              SizeReportingWidget(
                child: child,
                onSizeChange: (size) {
                  childSizes[key] = size;
                },
              ));
        })
        .values
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return WidgetStateConsumer<int?>(
        widgetStateNotifier: paginateSize,
        widgetStateBuilder: (context, snapshot) {
          return NotificationListener<ScrollNotification>(
            onNotification: handleScrollNotification,
            child: RefreshIndicator(
              displacement: widget.retryStreamListener != null ? 40 : 0,
              onRefresh: () async {
                widget.retryStreamListener?.startRetrying();
                return widget
                        .retryStreamListener?.refreshStreamController.stream
                        .timeout(widget
                                .paginationProgressStyle?.progressMaxDuration ??
                            const Duration(seconds: 15))
                        .any((element) =>
                            element == RefreshState.refreshComplete) ??
                    Future.delayed(Duration.zero);
              },
              child: widget.sliver
                  ? Column(
                      children: [
                        if (widget.paginationProgressController != null)
                          StreamBuilder(
                              initialData: widget
                                  .paginationProgressController?.currentValue,
                              stream:
                                  widget.paginationProgressController?.stream,
                              builder: (context, snapshot) {
                                bool indicator = ((widget.itemCount ?? 0) > 0 &&
                                    (snapshot.data ?? false) &&
                                    widget.reverse &&
                                    paginate != 0);
                                return indicator
                                    ? scrollViewIndicator()
                                    : Padding(
                                        padding: (widget.topPaginateWidget !=
                                                null)
                                            ? getPaginationProgressStyle.padding
                                            : EdgeInsets.zero,
                                        child: GestureDetector(
                                            onTap: () {
                                              widget
                                                  .paginationProgressController
                                                  ?.sendNewState(true);
                                              if (widget.wrapEdgePosition !=
                                                  null) {
                                                widget.wrapEdgePosition!(
                                                    WrapEdgePosition
                                                        .reserveBottom);
                                              }
                                            },
                                            child: ((widget.itemCount ?? 0) > 0)
                                                ? (widget.topPaginateWidget ??
                                                    const SizedBox())
                                                : SizedBox()),
                                      );
                              }),
                        Expanded(
                          child: CustomScrollView(slivers: [
                            widget.injector
                                ? SliverOverlapInjector(
                                    handle: NestedScrollView
                                        .sliverOverlapAbsorberHandleFor(
                                            context))
                                : const SliverPadding(padding: EdgeInsets.zero),
                            SliverList(
                                delegate: SliverChildBuilderDelegate(
                                    childCount: getItemCount(paginate),
                                    (context, index) {
                              int itemCount = getItemCount(paginate);
                              return widget.reverse
                                  ? widget.wrapListBuilder(
                                      context, itemCount - (index + 1))
                                  : widget.wrapListBuilder(context, index);
                            })),
                          ]),
                        ),
                        if (widget.paginationProgressController != null)
                          StreamBuilder(
                              initialData: widget
                                  .paginationProgressController?.currentValue,
                              stream:
                                  widget.paginationProgressController?.stream,
                              builder: (context, snapshot) {
                                return (widget.itemCount ?? 0) > 0 &&
                                        (snapshot.data ?? false) &&
                                        !widget.reverse &&
                                        paginate != 0
                                    ? scrollViewIndicator()
                                    : Padding(
                                        padding: (widget.bottomPaginateWidget !=
                                                null)
                                            ? getPaginationProgressStyle.padding
                                            : EdgeInsets.zero,
                                        child: GestureDetector(
                                            onTap: () {
                                              widget
                                                  .paginationProgressController
                                                  ?.sendNewState(true);
                                              if (widget.wrapEdgePosition !=
                                                  null) {
                                                widget.wrapEdgePosition!(
                                                    WrapEdgePosition
                                                        .normalBottom);
                                              }
                                            },
                                            child: ((widget.itemCount ?? 0) > 0)
                                                ? (widget
                                                        .bottomPaginateWidget ??
                                                    const SizedBox())
                                                : SizedBox()),
                                      );
                              }),
                      ],
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      controller: widget.scrollController,
                      shrinkWrap: widget.shrinkWrap,
                      physics: widget.physics ??
                          (widget.retryStreamListener != null
                              ? const AlwaysScrollableScrollPhysics()
                              : null),
                      children: [
                        if (widget.paginationProgressController != null)
                          StreamBuilder(
                              initialData: widget
                                  .paginationProgressController?.currentValue,
                              stream:
                                  widget.paginationProgressController?.stream,
                              builder: (context, snapshot) {
                                bool indicator = ((widget.itemCount ?? 0) > 0 &&
                                    (snapshot.data ?? false) &&
                                    widget.reverse &&
                                    paginate != 0);
                                return indicator
                                    ? scrollViewIndicator()
                                    : Padding(
                                        padding: (widget.topPaginateWidget !=
                                                null)
                                            ? getPaginationProgressStyle.padding
                                            : EdgeInsets.zero,
                                        child: GestureDetector(
                                            onTap: () {
                                              widget
                                                  .paginationProgressController
                                                  ?.sendNewState(true);
                                              if (widget.wrapEdgePosition !=
                                                  null) {
                                                widget.wrapEdgePosition!(
                                                    WrapEdgePosition
                                                        .reserveBottom);
                                              }
                                            },
                                            child: ((widget.itemCount ?? 0) > 0)
                                                ? (widget.topPaginateWidget ??
                                                    const SizedBox())
                                                : SizedBox()),
                                      );
                              }),
                        ...(getBuilders(snapshot ?? paginate)),
                        if (widget.paginationProgressController != null)
                          StreamBuilder(
                              initialData: widget
                                  .paginationProgressController?.currentValue,
                              stream:
                                  widget.paginationProgressController?.stream,
                              builder: (context, snapshot) {
                                return (widget.itemCount ?? 0) > 0 &&
                                        (snapshot.data ?? false) &&
                                        !widget.reverse &&
                                        paginate != 0
                                    ? scrollViewIndicator()
                                    : Padding(
                                        padding: (widget.bottomPaginateWidget !=
                                                null)
                                            ? getPaginationProgressStyle.padding
                                            : EdgeInsets.zero,
                                        child: GestureDetector(
                                            onTap: () {
                                              widget
                                                  .paginationProgressController
                                                  ?.sendNewState(true);
                                              if (widget.wrapEdgePosition !=
                                                  null) {
                                                widget.wrapEdgePosition!(
                                                    WrapEdgePosition
                                                        .normalBottom);
                                              }
                                            },
                                            child: ((widget.itemCount ?? 0) > 0)
                                                ? (widget
                                                        .bottomPaginateWidget ??
                                                    const SizedBox())
                                                : SizedBox()),
                                      );
                              }),
                      ],
                    ),
            ),
          );
        });
  }
}
