import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'CustomProject.dart';
import 'SizeReportingWidget.dart';

class ExpandablePageView extends StatefulWidget {
  final List<EPView> epViews;
  final PageController? pageController;
  final Function(int index)? onPageChange;
  final bool reverse;
  final ScrollPhysics? physics;
  final bool pageSnapping;
  final DragStartBehavior dragStartBehavior;
  final bool allowImplicitScrolling;
  final String? restorationId;
  final Clip clipBehavior = Clip.hardEdge;
  final ScrollBehavior? scrollBehavior;
  final bool padEnds;
  final bool autoScroll;
  final Duration autoScrollDelay;
  final Duration autoReturnDelay;
  final Duration waitDuration;
  final bool directAncestorUseController;
  final Duration toAncestor;
  final Curve curve;
  final AlignmentGeometry alignment;
  final double? widthFactor;
  final double? heightFactor;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;

  const ExpandablePageView({
    super.key,
    required this.epViews,
    this.pageController,
    this.autoReturnDelay = const Duration(seconds: 1),
    this.autoScrollDelay = const Duration(seconds: 2),
    this.autoScroll = false,
    this.waitDuration = const Duration(seconds: 5),
    this.onPageChange,
    this.directAncestorUseController = false,
    this.toAncestor = const Duration(milliseconds: 400),
    this.curve = Curves.linear,
    this.physics,
    this.restorationId,
    this.scrollBehavior,
    this.reverse = false,
    this.pageSnapping = true,
    this.dragStartBehavior = DragStartBehavior.start,
    this.allowImplicitScrolling = false,
    this.padEnds = true,
    this.alignment = Alignment.centerLeft,
    this.widthFactor,
    this.heightFactor,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
  });

  @override
  State<ExpandablePageView> createState() => _ExpandablePageViewState();
}

class _ExpandablePageViewState extends State<ExpandablePageView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late List<double> heights;
  late List<Size> sizes;
  int currentPage = 0;
  var rebuild = false;
  var resize = false;
  Timer? autoScrollTimer;
  Timer? delayTimer;
  double initTextScaleFactor = 0.0;
  double maxHeight = 0.0;

  double get currentHeight => heights.isNotEmpty ? heights[currentPage] : 0;
  var leftOverScroll = 0.0;
  var rightOverScroll = 0.0;
  PageController? ancestorPageController;

  @override
  void initState() {
    super.initState();

    startAutoScroll();
    heights = widget.epViews.map((e) => 0.0).toList();
    sizes = widget.epViews.map((e) => const Size(0.0, 0.0)).toList();
    ancestorPageController =
        context.findAncestorWidgetOfExactType<PageView>()?.controller;

    WidgetsBinding.instance.addObserver(this);

    widget.pageController?.addListener(() {
      final newPage = widget.pageController?.page?.round() ?? 0;
      if (widget.pageController != null && currentPage != newPage) {
        try {
          setState(() => currentPage = newPage);
        } catch (e) {
          null;
        }
      }
    });
  }

  @override
  void dispose() {
    autoScrollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      rebuildPageView();
    }
  }

  void rebuildPageView() {
    setState(() {
      if (anyMatchDimension() &&
          !isWrap(widget.epViews[currentPage].crossDimension)) {
        int firstWrap = getFirstWrap(currentPage);
        if (firstWrap != -1) {
          maxHeight = 0;
          widget.pageController?.jumpToPage(firstWrap);
        }
      } else if (!anyMatchDimension()) {
        maxHeight = 0;
        widget.pageController?.jumpToPage(0);
      }
    });
  }

  bool isWrap(EPDimension? crossDimension) {
    return crossDimension == EPDimension.wrap || crossDimension == null;
  }

  int getFirstWrap(int currentPage) {
    int index = -1;
    int checking = 0;
    int epChildrenSize = widget.epViews.length;

    if (currentPage > 0 &&
        currentPage < epChildrenSize &&
        isWrap(widget.epViews[currentPage - 1].crossDimension)) {
      index = currentPage - 1;
    } else if (currentPage > 0 &&
        (currentPage + 1) < epChildrenSize &&
        isWrap(widget.epViews[currentPage + 1].crossDimension)) {
      index = currentPage + 1;
    } else if (epChildrenSize == 1) {
      index = 0;
    }

    while (index == -1 && checking < widget.epViews.length) {
      if (isWrap(widget.epViews[checking].crossDimension)) {
        index = checking;
      }

      checking++;
    }

    return index;
  }

  void startAutoScroll() {
    autoScrollTimer = widget.autoScroll
        ? Timer.periodic(widget.autoScrollDelay + widget.autoReturnDelay,
            (timer) {
            if (widget.pageController != null) {
              if (currentPage == widget.epViews.length - 1) {
                widget.pageController?.animateToPage(0,
                    duration: widget.autoReturnDelay, curve: Curves.ease);
              } else {
                widget.pageController?.nextPage(
                    duration: widget.autoScrollDelay, curve: Curves.ease);
              }
            }
          })
        : null;
  }

  void stopAutoScroll() {
    autoScrollTimer?.cancel();
    autoScrollTimer = null;
    delayTimer?.cancel();
    delayTimer = null;
  }

  void performWait() {
    var checkWait = widget.waitDuration - widget.autoScrollDelay;
    if (checkWait > Duration.zero && delayTimer == null) {
      delayTimer = Timer(checkWait, () {
        startAutoScroll();
      });
    }
  }

  double getMaxHeight() {
    for (var i = 0; i < heights.length; i++) {
      if (heights[i] > maxHeight) {
        maxHeight = heights[i];
      }
    }
    return maxHeight;
  }

  Widget getTheChild(int index, EPView epView) {
    return epView.child;
  }

  bool anyMatchDimension() {
    bool exists = false;
    for (var i = 0; i < widget.epViews.length; i++) {
      if (widget.epViews[i].crossDimension == EPDimension.match) {
        exists = true;
      }
    }
    return exists;
  }

  bool anyWrapDimension() {
    bool exists = false;
    for (var i = 0; i < widget.epViews.length; i++) {
      if (widget.epViews[i].crossDimension == EPDimension.wrap ||
          widget.epViews[i].crossDimension == null) {
        exists = true;
      }
    }
    return exists;
  }

  double getCurrentHeight() {
    return currentHeight;
  }

  double getBeginHeight() {
    if (widget.epViews[currentPage].crossDimension == EPDimension.match) {
      return getMaxHeight();
    } else {
      try {
        return heights[0] ?? 0;
      } catch (e) {
        return 0;
      }
    }
  }

  double getEndHeight() {
    if (widget.epViews[currentPage].crossDimension == EPDimension.match) {
      return getMaxHeight();
    } else {
      return getCurrentHeight();
    }
  }

  bool handleNotificationListener(Notification notification) {
    if (widget.directAncestorUseController) {
      // over scroll to the left side
      if (notification is OverscrollNotification &&
          notification.overscroll < 0) {
        double goToOffset =
            ancestorPageController!.position.pixels + notification.overscroll;

        if (goToOffset >= ancestorPageController!.position.minScrollExtent &&
            goToOffset <= ancestorPageController!.position.maxScrollExtent) {
          leftOverScroll += notification.overscroll;
          ancestorPageController?.position.correctPixels(goToOffset);
          ancestorPageController?.position.notifyListeners();
        }
      }

      // scroll back after left over scrolling
      if (leftOverScroll < 0) {
        if (notification is ScrollUpdateNotification) {
          final newOverScroll =
              min(notification.metrics.pixels + leftOverScroll, 0.0);
          final diff = newOverScroll - leftOverScroll;
          ancestorPageController?.position
              .correctPixels(ancestorPageController!.position.pixels + diff);
          ancestorPageController?.position.notifyListeners();
          leftOverScroll = newOverScroll;
          widget.pageController?.position.correctPixels(0);
          widget.pageController?.position.notifyListeners();
        }
      }

      // release left
      if (notification is UserScrollNotification &&
          notification.direction == ScrollDirection.idle &&
          leftOverScroll != 0) {
        double screenWidth = getScreenWidth(context);
        double goToCurrentOffset =
            ancestorPageController!.position.pixels - leftOverScroll;
        double goToNextOffset =
            ancestorPageController!.offset - (screenWidth + leftOverScroll);

        if ((leftOverScroll * -1) >= screenWidth / 2) {
          ancestorPageController?.animateTo(goToNextOffset,
              duration: widget.toAncestor, curve: widget.curve);
        } else {
          ancestorPageController?.animateTo(goToCurrentOffset,
              duration: widget.toAncestor, curve: widget.curve);
        }

        leftOverScroll = 0;
      }

      // over scroll to the right side
      if (notification is OverscrollNotification &&
          notification.overscroll > 0) {
        double goToOffset =
            ancestorPageController!.position.pixels + notification.overscroll;

        if (goToOffset >= ancestorPageController!.position.minScrollExtent &&
            goToOffset <= ancestorPageController!.position.maxScrollExtent) {
          rightOverScroll += notification.overscroll;
          ancestorPageController?.position.correctPixels(
              ancestorPageController!.position.pixels +
                  notification.overscroll);
          ancestorPageController?.position.notifyListeners();
        }
      }

      // scroll back after right over scrolling
      if (rightOverScroll > 0) {
        if (notification is ScrollUpdateNotification) {
          final maxScrollExtent = notification.metrics.maxScrollExtent;
          final newOverScroll = max(
              notification.metrics.pixels + rightOverScroll - maxScrollExtent,
              0.0);
          final diff = newOverScroll - rightOverScroll;
          ancestorPageController?.position
              .correctPixels(ancestorPageController!.position.pixels + diff);
          ancestorPageController?.position.notifyListeners();
          rightOverScroll = newOverScroll;
          widget.pageController?.position.correctPixels(maxScrollExtent);
          widget.pageController?.position.notifyListeners();
        }
      }

      // release right
      if (notification is UserScrollNotification &&
          notification.direction == ScrollDirection.idle &&
          rightOverScroll != 0) {
        double screenWidth = getScreenWidth(context);
        double goToCurrentOffset =
            ancestorPageController!.position.pixels - rightOverScroll;
        double goToNextOffset =
            (screenWidth - rightOverScroll) + ancestorPageController!.offset;
        if (rightOverScroll >= screenWidth / 2) {
          ancestorPageController?.animateTo(goToNextOffset,
              duration: widget.toAncestor, curve: widget.curve);
        } else {
          ancestorPageController?.animateTo(goToCurrentOffset,
              duration: widget.toAncestor, curve: widget.curve);
        }

        rightOverScroll = 0;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.epViews.isNotEmpty) {
      return TweenAnimationBuilder<double>(
        curve: Curves.easeInOutCubic,
        duration: const Duration(milliseconds: 100),
        tween: Tween<double>(begin: getBeginHeight(), end: getEndHeight()),
        builder: (context, value, child) =>
            SizedBox(height: value, child: child),
        child: GestureDetector(
          onHorizontalDragDown: (DragDownDetails dragDownDetails) {
            stopAutoScroll();
          },
          onHorizontalDragCancel: () {
            performWait();
          },
          child: NotificationListener(
            onNotification: handleNotificationListener,
            child: PageView(
              physics: widget.physics,
              scrollBehavior: widget.scrollBehavior,
              padEnds: widget.padEnds,
              pageSnapping: widget.pageSnapping,
              dragStartBehavior: widget.dragStartBehavior,
              reverse: widget.reverse,
              clipBehavior: widget.clipBehavior,
              restorationId: widget.restorationId,
              allowImplicitScrolling: widget.allowImplicitScrolling,
              key: widget.key,
              onPageChanged: widget.onPageChange,
              scrollDirection: Axis.horizontal,
              controller: widget.pageController,
              children: rebuild == false
                  // Rebuild is false
                  ? _sizeReportingChildren
                      .asMap() //
                      .map((index, child) => MapEntry(index, child))
                      .values
                      .toList()
                  // Rebuild is true
                  : [],
            ),
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  List<Widget> get _sizeReportingChildren => widget.epViews
      .asMap() //
      .map(
        (index, epView) => MapEntry(
          index,
          // Check the views cross dimension
          epView.crossDimension == EPDimension.match && index != 0
              // child is set to match the parent
              ? Column(
                  mainAxisAlignment: widget.mainAxisAlignment,
                  mainAxisSize: widget.mainAxisSize,
                  crossAxisAlignment: widget.crossAxisAlignment,
                  textDirection: widget.textDirection,
                  verticalDirection: widget.verticalDirection,
                  textBaseline: widget.textBaseline,
                  children: [Expanded(child: Container(child: epView.child))])
              : OverflowBox(
                  //needed, so that parent won't impose its constraints on the children, thus skewing the measurement results.
                  minHeight: 0,
                  maxHeight: double.infinity,
                  alignment: Alignment.topCenter,
                  child: SizeReportingWidget(
                    onSizeChange: (size) {
                      setState(() {
                        if (heights.isNotEmpty) {
                          heights[index] = size.height;
                        }
                      });
                    },
                    child: Align(
                        alignment: widget.alignment,
                        widthFactor: widget.widthFactor,
                        heightFactor: widget.heightFactor,
                        child: epView.child),
                  ),
                ),
        ),
      )
      .values
      .toList();
}

enum EPDimension { wrap, match }

class EPView {
  final EPDimension? crossDimension;
  final Widget child;

  EPView({this.crossDimension, required this.child});
}
