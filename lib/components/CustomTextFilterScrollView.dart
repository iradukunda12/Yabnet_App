import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'CustomProject.dart';
import 'SizeReportingWidget.dart';

class TextFilterController extends ChangeNotifier {
  int? toIndex;

  TextFilterController({this.toIndex});

  void jumpToIndex(int index) {
    toIndex = index;
    notifyListeners();
  }
}

class CustomTextFilterScrollView extends StatefulWidget {
  final ValueChanged<int> currentItem;
  final TextFilterController? textFilterController;
  final int startingIndex;
  final bool useIcon;
  final bool useBottomDivider;
  final EdgeInsets padding;
  final Color? textActiveColor;
  final Color textNormalColor;
  final Color textActiveBackground;
  final Color textNormalBackground;
  final double textSize;
  final FontWeight textWeight;
  final bool boldUnSelected;
  final bool boldSelected;
  final double textPadding;
  final double bottomDividerHeight;
  final Color bottomDividerColor;
  final BorderRadiusGeometry borderRadius;
  final bool directAncestorUseController;
  final Duration toAncestor;
  final Curve curve;
  final double offsetAddon;
  final List<FilterItem> filterItems;

  const CustomTextFilterScrollView(
      {super.key,
      this.startingIndex = 0,
      this.useIcon = false,
      required this.filterItems,
      required this.textActiveColor,
      required this.textNormalColor,
      required this.textActiveBackground,
      this.textSize = 16.0,
      this.textWeight = FontWeight.bold,
      this.borderRadius = BorderRadius.zero,
      this.textNormalBackground = Colors.transparent,
      this.textPadding = 5.0,
      required this.padding,
      this.toAncestor = const Duration(milliseconds: 400),
      this.curve = Curves.linear,
      this.useBottomDivider = true,
      this.bottomDividerHeight = 2.0,
      this.directAncestorUseController = false,
      this.bottomDividerColor = Colors.transparent,
      required this.currentItem,
      this.boldUnSelected = false,
      this.boldSelected = true,
      this.textFilterController,
      this.offsetAddon = 19});

  @override
  State<CustomTextFilterScrollView> createState() =>
      _CustomTextFilterScrollViewState();
}

class _CustomTextFilterScrollViewState extends State<CustomTextFilterScrollView>
    with WidgetsBindingObserver {
  int currentlySelected = 0;
  ScrollController controller = ScrollController();
  GlobalKey containerKey = GlobalKey();
  List<Size> childrenSizes = [];
  Size parentSize = const Size(0, 0);
  var leftOverScroll = 0.0;
  var rightOverScroll = 0.0;
  PageController? ancestorPageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    childrenSizes = widget.filterItems.map((e) => const Size(0, 0)).toList();
    ancestorPageController =
        context.findAncestorWidgetOfExactType<PageView>()?.controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        currentlySelected =
            (widget.filterItems.length) > widget.startingIndex ||
                    widget.startingIndex >= 0
                ? widget.startingIndex
                : 0;
      });
      widget.currentItem(currentlySelected);
    });

    widget.textFilterController?.addListener(() {
      int? toIndex = widget.textFilterController?.toIndex;

      if (toIndex != null && toIndex != currentlySelected) {
        setState(() {
          currentlySelected = toIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void scrollToChildPosition(int position) {
    double totalWidth = 0.0;
    for (int i = 0; i <= position; i++) {
      totalWidth = totalWidth + childrenSizes[i].width;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? containerBox =
          containerKey.currentContext?.findRenderObject() as RenderBox?;

      if (containerBox != null) {
        final double containerWidth = containerBox.size.width;
        final double itemExtent = containerWidth / position;
        final double offset =
            totalWidth - containerWidth; // Adjust the offset calculation.

        final double maxScroll = controller.position.maxScrollExtent;
        final double maxVisibleOffset = controller.offset + containerWidth;
        final double minVisibleOffset = controller.offset;

        // Adjust the visibility conditions.
        final bool isPositionVisible = offset >= minVisibleOffset;
        final bool isPositionPartiallyVisible =
            offset + itemExtent >= minVisibleOffset;

        if ((!isPositionVisible || isPositionPartiallyVisible) &&
            offset >= 0 &&
            (offset + widget.offsetAddon) <= maxVisibleOffset) {
          controller.animateTo(
            offset + widget.offsetAddon,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else if (offset < 0) {
          controller.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else if ((offset + widget.offsetAddon) > maxVisibleOffset) {
          controller.animateTo(
            maxVisibleOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      scrollToChildPosition(currentlySelected);
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
          controller.position.correctPixels(0);
          controller.position.notifyListeners();
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
          controller.position.correctPixels(maxScrollExtent);
          controller.position.notifyListeners();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Widgets

        SizeReportingWidget(
          onSizeChange: (Size size) {
            parentSize = size;
          },
          child: NotificationListener(
            onNotification: handleNotificationListener,
            child: SingleChildScrollView(
              key: containerKey,
              controller: controller,
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: widget.padding,
                child: Row(
                  children: filterItems,
                ),
              ),
            ),
          ),
        ),

        //  Bottom line
        widget.useBottomDivider
            ? Row(
                children: [
                  Expanded(
                      child: Container(
                    height: widget.bottomDividerHeight,
                    color: widget.bottomDividerColor,
                  )),
                ],
              )
            : const SizedBox()
      ],
    );
  }

  List<Widget> get filterItems => widget.filterItems
      .asMap()
      .map((index, filterItem) => MapEntry(
          index,
          GestureDetector(
            onTap: () {
              if (currentlySelected != index) {
                setState(() {
                  currentlySelected = index;
                });

                widget.currentItem(currentlySelected);
                scrollToChildPosition(currentlySelected);
              }
            },
            child: SizeReportingWidget(
              onSizeChange: (Size size) {
                childrenSizes[index] = size;
              },
              child: Row(
                children: [
                  // Filter Item
                  Container(
                    decoration: BoxDecoration(
                        color: index == currentlySelected
                            ? widget.textActiveBackground
                            : widget.textNormalBackground,
                        borderRadius: widget.borderRadius),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: widget.textPadding,
                          vertical: widget.textPadding * 0.5),
                      child: Row(
                        children: [
                          // Icon

                          widget.useIcon && filterItem.icon != null
                              ? Icon(
                                  filterItem.icon,
                                  color: filterItem.iconColor ??
                                      (index == currentlySelected
                                          ? widget.textActiveColor
                                          : widget.textNormalColor),
                                )
                              : const SizedBox(),

                          // Filter Text
                          widget.useIcon && filterItem.icon != null
                              ? const SizedBox(
                                  width: 4,
                                )
                              : const SizedBox(),
                          Text(
                            filterItem.filterText,
                            style: TextStyle(
                                color: index == currentlySelected
                                    ? widget.textActiveColor
                                    : widget.textNormalColor,
                                fontSize: widget.textSize,
                                fontWeight: index == currentlySelected &&
                                            widget.boldSelected ||
                                        widget.boldUnSelected &&
                                            index != currentlySelected
                                    ? widget.textWeight
                                    : FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ),

                  //  Space
                  const SizedBox(
                    width: 16,
                  )
                ],
              ),
            ),
          )))
      .values
      .toList();
}

class FilterItem {
  final IconData? icon;
  final double iconSize;
  final Color? iconColor;
  final String filterText;

  FilterItem({
    this.icon,
    required this.filterText,
    this.iconSize = 16,
    this.iconColor,
  });
}
